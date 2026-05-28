import processing.video.*;
import oscP5.*;
import netP5.*;
import processing.sound.*;

// Virtual antenna theremin for MacBook Pro.
// Processing -> Wekinator: /wek/inputs, 2 floats, localhost:6448
//   input 1 = hand proximity to pitch antenna
//   input 2 = hand distance from volume loop
// Wekinator -> Processing: /wek/outputs, 2 floats, localhost:12000
//   output 1 = pitch, output 2 = volume

final int WEKINATOR_INPUT_PORT = 6448;
final int PROCESSING_LISTEN_PORT = 12000;
final int INPUT_MOUSE = 0;
final int INPUT_MOTION = 1;
final int INPUT_EYES = 2;

Capture camera;
OscP5 oscP5;
NetAddress wekinator;
SinOsc theremin;

int[] previousPixels;
boolean cameraAvailable = false;
boolean cameraTried = false;
boolean mirrorCamera = true;
int inputMode = INPUT_MOUSE;

float handX = 450;
float handY = 280;
float rawHandX = 450;
float rawHandY = 280;
float handConfidence = 0;
float motionThreshold = 38;
int motionPixels = 0;
float eyeDarkOffset = 32;
int eyeDarkPixels = 0;
float eyeSensitivity = 4.2;
float eyeDeadZone = 0.018;
float eyeRawX = 0.5;
float eyeRawY = 0.5;
float eyeCenterX = 0.5;
float eyeCenterY = 0.5;
boolean eyeCalibrated = false;
boolean requestEyeCalibration = false;

float eyeRoiX = 0.22;
float eyeRoiY = 0.16;
float eyeRoiW = 0.56;
float eyeRoiH = 0.28;

float inputPitch = 0.5;
float inputVolume = 0.0;
float wekiPitch = 0.5;
float wekiVolume = 0.0;
boolean gotWekinatorOutput = false;
int lastWekinatorMillis = -9999;

float targetPitch = 0.5;
float targetVolume = 0.0;
float smoothPitch = 0.5;
float smoothVolume = 0.0;

boolean muted = true;
boolean useWekinator = false;
boolean quantizePitch = false;
boolean sendToWekinator = true;
boolean testTone = false;
int oscSentCount = 0;

float minFreq = 160.0;
float maxFreq = 1400.0;
float masterGain = 0.35;
float pitchRange = 430.0;
float volumeRange = 390.0;

int[] pentatonicMidi = {
  48, 50, 52, 55, 57,
  60, 62, 64, 67, 69,
  72, 74, 76, 79, 81
};

void setup() {
  size(900, 560);
  smooth(8);
  colorMode(RGB, 255);

  oscP5 = new OscP5(this, PROCESSING_LISTEN_PORT);
  wekinator = new NetAddress("localhost", WEKINATOR_INPUT_PORT);

  theremin = new SinOsc(this);
  theremin.play();
  theremin.amp(0);

  textFont(createFont("Arial", 16));
}

void draw() {
  updateHandInput();
  updateInputs();

  if (sendToWekinator && frameCount % 2 == 0) {
    sendOscToWekinator();
  }

  boolean wekinatorIsLive = gotWekinatorOutput && millis() - lastWekinatorMillis < 1500;

  if (useWekinator && wekinatorIsLive) {
    targetPitch = constrain(wekiPitch, 0, 1);
    targetVolume = constrain(wekiVolume, 0, 1) * handConfidence;
  } else {
    targetPitch = inputPitch;
    targetVolume = inputVolume * handConfidence;
  }

  if (testTone) {
    targetPitch = 0.45;
    targetVolume = 0.8;
  }

  smoothPitch = lerp(smoothPitch, targetPitch, 0.12);
  smoothVolume = lerp(smoothVolume, muted ? 0 : targetVolume, 0.10);

  float freq = pitchToFrequency(smoothPitch);
  float amp = pow(constrain(smoothVolume, 0, 1), 1.35) * masterGain;

  theremin.freq(freq);
  theremin.amp(amp);

  drawTheremin(freq, amp, wekinatorIsLive);
}

void captureEvent(Capture c) {
  c.read();
}

void updateHandInput() {
  if (inputMode == INPUT_MOTION) {
    updateMotionHand();
  } else if (inputMode == INPUT_EYES) {
    updateEyeHand();
  } else {
    updateMouseHand();
  }
}

void updateMouseHand() {
  rawHandX = mouseX;
  rawHandY = mouseY;
  handConfidence = 1;
  motionPixels = 0;
  eyeDarkPixels = 0;
  eyeCalibrated = false;
  handX = lerp(handX, rawHandX, 0.25);
  handY = lerp(handY, rawHandY, 0.25);
}

void startCameraIfNeeded() {
  if (cameraAvailable || cameraTried) {
    return;
  }

  cameraTried = true;
  try {
    String[] cameras = Capture.list();
    if (cameras.length > 0) {
      camera = new Capture(this, 640, 480);
      camera.start();
      cameraAvailable = true;
    }
  } catch (Exception e) {
    println("Camera could not be started: " + e.getMessage());
  }
}

void updateMotionHand() {
  startCameraIfNeeded();

  if (!cameraAvailable || camera == null || camera.width == 0 || camera.height == 0) {
    updateMouseHand();
    return;
  }

  camera.loadPixels();
  if (camera.pixels == null || camera.pixels.length == 0) {
    return;
  }

  if (previousPixels == null || previousPixels.length != camera.pixels.length) {
    previousPixels = new int[camera.pixels.length];
    arrayCopy(camera.pixels, previousPixels);
    return;
  }

  float sumX = 0;
  float sumY = 0;
  int count = 0;
  int step = 4;

  for (int y = 0; y < camera.height; y += step) {
    for (int x = 0; x < camera.width; x += step) {
      int index = y * camera.width + x;
      int current = camera.pixels[index];
      int previous = previousPixels[index];

      float diff = colorDifference(current, previous);
      if (diff > motionThreshold) {
        sumX += x;
        sumY += y;
        count++;
      }
    }
  }

  arrayCopy(camera.pixels, previousPixels);
  motionPixels = count;

  if (count > 28) {
    float cx = sumX / count;
    float cy = sumY / count;
    rawHandX = mirrorCamera ? width - (cx / camera.width) * width : (cx / camera.width) * width;
    rawHandY = (cy / camera.height) * height;
    handConfidence = lerp(handConfidence, constrain(count / 950.0, 0.25, 1), 0.22);
  } else {
    handConfidence = lerp(handConfidence, 0, 0.012);
  }

  handX = lerp(handX, rawHandX, 0.23);
  handY = lerp(handY, rawHandY, 0.23);
}

void updateEyeHand() {
  startCameraIfNeeded();

  if (!cameraAvailable || camera == null || camera.width == 0 || camera.height == 0) {
    updateMouseHand();
    return;
  }

  camera.loadPixels();
  if (camera.pixels == null || camera.pixels.length == 0) {
    return;
  }

  int x0 = int(camera.width * eyeRoiX);
  int y0 = int(camera.height * eyeRoiY);
  int x1 = int(camera.width * (eyeRoiX + eyeRoiW));
  int y1 = int(camera.height * (eyeRoiY + eyeRoiH));
  int step = 2;

  float minBrightness = 255;
  float totalBrightness = 0;
  int samples = 0;

  for (int y = y0; y < y1; y += step) {
    for (int x = x0; x < x1; x += step) {
      int c = camera.pixels[y * camera.width + x];
      float b = pixelBrightness(c);
      minBrightness = min(minBrightness, b);
      totalBrightness += b;
      samples++;
    }
  }

  float averageBrightness = samples > 0 ? totalBrightness / samples : 255;
  float darkThreshold = min(averageBrightness * 0.72, minBrightness + eyeDarkOffset);

  float weightedX = 0;
  float weightedY = 0;
  float totalWeight = 0;
  int count = 0;

  for (int y = y0; y < y1; y += step) {
    for (int x = x0; x < x1; x += step) {
      int c = camera.pixels[y * camera.width + x];
      float b = pixelBrightness(c);
      if (b < darkThreshold) {
        float weight = darkThreshold - b + 1;
        weightedX += x * weight;
        weightedY += y * weight;
        totalWeight += weight;
        count++;
      }
    }
  }

  eyeDarkPixels = count;
  motionPixels = 0;

  if (totalWeight > 0 && count > 10) {
    float cx = weightedX / totalWeight;
    float cy = weightedY / totalWeight;
    float nx = constrain((cx - x0) / max(1.0f, float(x1 - x0)), 0, 1);
    float ny = constrain((cy - y0) / max(1.0f, float(y1 - y0)), 0, 1);

    eyeRawX = mirrorCamera ? 1.0 - nx : nx;
    eyeRawY = ny;

    if (!eyeCalibrated || requestEyeCalibration) {
      eyeCenterX = eyeRawX;
      eyeCenterY = eyeRawY;
      eyeCalibrated = true;
      requestEyeCalibration = false;
    }

    float gazeX = 0.5 + applyDeadZone(eyeRawX - eyeCenterX, eyeDeadZone) * eyeSensitivity;
    float gazeY = 0.5 + applyDeadZone(eyeRawY - eyeCenterY, eyeDeadZone) * eyeSensitivity;

    rawHandX = map(constrain(gazeX, 0, 1), 0, 1, 80, width - 80);
    rawHandY = map(constrain(gazeY, 0, 1), 0, 1, 95, height - 115);
    handConfidence = lerp(handConfidence, constrain(count / 190.0, 0.25, 1), 0.18);
  } else {
    handConfidence = lerp(handConfidence, 0, 0.035);
  }

  handX = lerp(handX, rawHandX, 0.18);
  handY = lerp(handY, rawHandY, 0.18);
}

float applyDeadZone(float value, float zone) {
  if (abs(value) <= zone) {
    return 0;
  }

  if (value > 0) {
    return value - zone;
  }

  return value + zone;
}

float colorDifference(int a, int b) {
  float ar = (a >> 16) & 0xff;
  float ag = (a >> 8) & 0xff;
  float ab = a & 0xff;
  float br = (b >> 16) & 0xff;
  float bg = (b >> 8) & 0xff;
  float bb = b & 0xff;
  return (abs(ar - br) + abs(ag - bg) + abs(ab - bb)) / 3.0;
}

float pixelBrightness(int c) {
  float r = (c >> 16) & 0xff;
  float g = (c >> 8) & 0xff;
  float b = c & 0xff;
  return (r + g + b) / 3.0;
}

void updateInputs() {
  float pitchDistance = max(0, pitchAntennaX() - handX);
  inputPitch = constrain(1.0 - pitchDistance / pitchRange, 0, 1);

  float loopDistance = dist(handX, handY, volumeLoopX(), volumeLoopY());
  inputVolume = constrain((loopDistance - 35.0) / volumeRange, 0, 1);
}

void sendOscToWekinator() {
  OscMessage msg = new OscMessage("/wek/inputs");
  msg.add(inputPitch);
  msg.add(inputVolume);
  oscP5.send(msg, wekinator);
  oscSentCount++;
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/wek/outputs") && msg.typetag().length() >= 1) {
    wekiPitch = msg.get(0).floatValue();
    if (msg.typetag().length() >= 2) {
      wekiVolume = msg.get(1).floatValue();
    }
    gotWekinatorOutput = true;
    lastWekinatorMillis = millis();
  }
}

float pitchToFrequency(float value) {
  value = constrain(value, 0, 1);

  if (quantizePitch) {
    int index = int(round(value * (pentatonicMidi.length - 1)));
    index = constrain(index, 0, pentatonicMidi.length - 1);
    return midiToFrequency(pentatonicMidi[index]);
  }

  return minFreq * pow(maxFreq / minFreq, value);
}

float midiToFrequency(int midiNote) {
  return 440.0 * pow(2.0, (midiNote - 69) / 12.0);
}

void keyPressed() {
  if (key == 'm' || key == 'M') {
    muted = !muted;
  } else if (key == 'w' || key == 'W') {
    useWekinator = !useWekinator;
  } else if (key == 'q' || key == 'Q') {
    quantizePitch = !quantizePitch;
  } else if (key == 's' || key == 'S') {
    sendToWekinator = !sendToWekinator;
  } else if (key == 't' || key == 'T') {
    testTone = !testTone;
  } else if (key == 'c' || key == 'C') {
    inputMode = (inputMode + 1) % 3;
    if (inputMode == INPUT_MOTION || inputMode == INPUT_EYES) {
      startCameraIfNeeded();
      resetMotionReference();
    }
  } else if (key == 'e' || key == 'E') {
    if (inputMode == INPUT_EYES) {
      requestEyeCalibration = true;
    }
  } else if (key == 'r' || key == 'R') {
    resetMotionReference();
  } else if (key == 'v' || key == 'V') {
    mirrorCamera = !mirrorCamera;
    if (inputMode == INPUT_EYES) {
      requestEyeCalibration = true;
    }
  } else if (key == '[') {
    if (inputMode == INPUT_EYES) {
      eyeSensitivity = max(1.2, eyeSensitivity - 0.4);
    } else {
      motionThreshold = max(8, motionThreshold - 4);
    }
  } else if (key == ']') {
    if (inputMode == INPUT_EYES) {
      eyeSensitivity = min(10.0, eyeSensitivity + 0.4);
    } else {
      motionThreshold = min(95, motionThreshold + 4);
    }
  } else if (key == '-' || key == '_') {
    if (inputMode == INPUT_EYES) {
      eyeDarkOffset = max(8, eyeDarkOffset - 4);
    }
  } else if (key == '=' || key == '+') {
    if (inputMode == INPUT_EYES) {
      eyeDarkOffset = min(80, eyeDarkOffset + 4);
    }
  }
}

void mousePressed() {
  muted = false;
}

void resetMotionReference() {
  if (inputMode == INPUT_MOTION || inputMode == INPUT_EYES) {
    startCameraIfNeeded();
  }
  if (inputMode == INPUT_EYES) {
    requestEyeCalibration = true;
  }
  if (cameraAvailable && camera != null && camera.pixels != null && camera.pixels.length > 0) {
    camera.loadPixels();
    previousPixels = new int[camera.pixels.length];
    arrayCopy(camera.pixels, previousPixels);
  }
  handConfidence = 0;
}

void drawTheremin(float freq, float amp, boolean wekinatorIsLive) {
  drawInputBackground();
  drawFields();
  drawThereminBody();
  drawWave(freq, amp);
  drawControlPoint();
  drawVirtualHand();
  drawVolumeMeter(amp);
  drawHud(freq, amp, wekinatorIsLive);
}

void drawInputBackground() {
  background(9, 12, 18);

  if ((inputMode == INPUT_MOTION || inputMode == INPUT_EYES) && cameraAvailable && camera != null && camera.width > 0) {
    pushMatrix();
    if (mirrorCamera) {
      translate(width, 0);
      scale(-1, 1);
    }
    image(camera, 0, 0, width, height);
    popMatrix();
    noStroke();
    fill(9, 12, 18, 168);
    rect(0, 0, width, height);

    if (inputMode == INPUT_EYES) {
      drawEyeRoiOverlay();
    }
  }

  stroke(35, 44, 58, 150);
  strokeWeight(1);
  for (int x = 0; x <= width; x += 60) {
    line(x, 0, x, height);
  }
  for (int y = 0; y <= height; y += 60) {
    line(0, y, width, y);
  }
}

void drawEyeRoiOverlay() {
  float x = width * eyeRoiX;
  if (mirrorCamera) {
    x = width * (1.0 - eyeRoiX - eyeRoiW);
  }
  float y = height * eyeRoiY;
  float w = width * eyeRoiW;
  float h = height * eyeRoiH;

  noFill();
  stroke(255, 194, 80, 180);
  strokeWeight(2);
  rect(x, y, w, h, 6);

  fill(255, 194, 80, 190);
  noStroke();
  textAlign(LEFT, BOTTOM);
  textSize(13);
  text("eye region", x + 8, y - 6);

  float rawX = x + eyeRawX * w;
  float rawY = y + eyeRawY * h;
  float centerX = x + eyeCenterX * w;
  float centerY = y + eyeCenterY * h;

  stroke(255, 194, 80, 170);
  strokeWeight(1);
  line(centerX - 12, centerY, centerX + 12, centerY);
  line(centerX, centerY - 12, centerX, centerY + 12);

  noStroke();
  fill(88, 205, 255, 220);
  ellipse(rawX, rawY, 10, 10);
}

float pitchAntennaX() {
  return width - 96;
}

float pitchAntennaTop() {
  return 112;
}

float pitchAntennaBottom() {
  return height - 104;
}

float volumeLoopX() {
  return 105;
}

float volumeLoopY() {
  return height - 132;
}

void drawFields() {
  noFill();

  for (int i = 1; i <= 6; i++) {
    float d = 70 + i * 62;
    float alpha = map(i, 1, 6, 72, 14);
    stroke(88, 205, 255, alpha);
    strokeWeight(1.5);
    arc(pitchAntennaX(), height * 0.5, d, d * 1.65, HALF_PI, PI + HALF_PI);
  }

  for (int i = 1; i <= 5; i++) {
    float d = 85 + i * 62;
    float alpha = map(i, 1, 5, 70, 14);
    stroke(255, 194, 80, alpha);
    strokeWeight(1.5);
    ellipse(volumeLoopX(), volumeLoopY(), d, d * 0.64);
  }
}

void drawThereminBody() {
  float bodyX = width * 0.29;
  float bodyY = height - 82;
  float bodyW = width * 0.42;
  float bodyH = 42;

  noStroke();
  fill(25, 31, 42);
  rect(bodyX, bodyY, bodyW, bodyH, 7);
  fill(43, 51, 66);
  rect(bodyX + 12, bodyY + 9, bodyW - 24, 7, 3);

  stroke(88, 205, 255);
  strokeWeight(5);
  line(pitchAntennaX(), pitchAntennaBottom(), pitchAntennaX(), pitchAntennaTop());
  strokeWeight(2);
  noFill();
  ellipse(pitchAntennaX(), pitchAntennaTop() - 10, 18, 18);

  stroke(255, 194, 80);
  strokeWeight(4);
  noFill();
  ellipse(volumeLoopX(), volumeLoopY(), 88, 56);
  line(volumeLoopX() + 44, volumeLoopY(), bodyX, bodyY + bodyH * 0.55);

  fill(230);
  noStroke();
  textAlign(CENTER, TOP);
  textSize(13);
  text("pitch antenna", pitchAntennaX(), pitchAntennaBottom() + 16);
  text("volume loop", volumeLoopX(), volumeLoopY() + 42);
}

void drawWave(float freq, float amp) {
  float phase = frameCount * 0.06;
  float waveHeight = map(amp, 0, masterGain, 8, 120);
  float cycles = map(freq, minFreq, maxFreq, 1.0, 9.0);

  noFill();
  stroke(88, 205, 255, 210);
  strokeWeight(3);
  beginShape();
  for (int x = 0; x < width; x += 3) {
    float angle = phase + TWO_PI * cycles * x / width;
    float y = height * 0.52 + sin(angle) * waveHeight;
    vertex(x, y);
  }
  endShape();

  stroke(255, 194, 80, 150);
  strokeWeight(1.5);
  beginShape();
  for (int x = 0; x < width; x += 4) {
    float angle = phase * 0.7 + TWO_PI * (cycles * 0.5) * x / width;
    float y = height * 0.52 + cos(angle) * waveHeight * 0.55;
    vertex(x, y);
  }
  endShape();
}

void drawControlPoint() {
  float x = map(smoothPitch, 0, 1, 40, width - 40);
  float y = map(smoothVolume, 0, 1, height - 70, 80);
  float radius = map(smoothVolume, 0, 1, 22, 90);

  noStroke();
  fill(88, 205, 255, 35);
  ellipse(x, y, radius * 2.2, radius * 2.2);
  fill(255, 194, 80, 70);
  ellipse(x, y, radius * 1.2, radius * 1.2);
  fill(255);
  ellipse(x, y, 14, 14);
}

void drawVirtualHand() {
  float handRadius = map(handConfidence, 0, 1, 12, 26);
  float pitchLineAlpha = map(inputPitch * handConfidence, 0, 1, 35, 190);
  float volumeLineAlpha = map(inputVolume * handConfidence, 0, 1, 35, 170);

  stroke(88, 205, 255, pitchLineAlpha);
  strokeWeight(2);
  line(handX, handY, pitchAntennaX(), constrain(handY, pitchAntennaTop(), pitchAntennaBottom()));

  stroke(255, 194, 80, volumeLineAlpha);
  strokeWeight(2);
  line(handX, handY, volumeLoopX(), volumeLoopY());

  noStroke();
  fill(255, 255, 255, 35 + 85 * handConfidence);
  ellipse(handX, handY, handRadius * 2.8, handRadius * 2.8);
  fill(255, 255, 255, 90 + 145 * handConfidence);
  ellipse(handX, handY, handRadius, handRadius);

  fill(220, 220 * handConfidence);
  textAlign(CENTER, BOTTOM);
  textSize(13);
  text(inputModeLabel(), handX, handY - 28);
}

void drawVolumeMeter(float amp) {
  float meterWidth = 220;
  float meterHeight = 12;
  float x = width - meterWidth - 24;
  float y = height - 36;
  float level = constrain(amp / masterGain, 0, 1);

  noStroke();
  fill(255, 255, 255, 38);
  rect(x, y, meterWidth, meterHeight, 4);
  fill(muted ? color(120, 120, 120) : color(255, 194, 80));
  rect(x, y, meterWidth * level, meterHeight, 4);
}

void drawHud(float freq, float amp, boolean wekinatorIsLive) {
  fill(240);
  textAlign(LEFT, TOP);
  textSize(22);
  text("Processing + Wekinator Theremin", 24, 22);

  textSize(14);
  fill(190);
  text("Input OSC: /wek/inputs -> localhost:6448", 24, 58);
  text("Output OSC: /wek/outputs -> Processing port 12000", 24, 78);

  String mode = useWekinator ? "WEKINATOR" : "DIRECT PREVIEW";
  String live = wekinatorIsLive ? "receiving" : "waiting";
  String muteText = muted ? "muted" : "sound on";
  String quantizeText = quantizePitch ? "pentatonic" : "continuous";
  String sendText = sendToWekinator ? "sending" : "paused";
  String testText = testTone ? " / TEST TONE" : "";
  String inputText = inputModeLabel();
  if ((inputMode == INPUT_MOTION || inputMode == INPUT_EYES) && !cameraAvailable) {
    inputText += ", mouse fallback";
  }
  String cameraText = cameraAvailable ? "camera on" : "camera off";
  String sensorText = inputMode == INPUT_EYES
    ? "eye gain: " + nf(eyeSensitivity, 1, 1) + " / dark: " + int(eyeDarkOffset) + " / pixels: " + eyeDarkPixels
    : "motion: " + motionPixels + " / threshold: " + int(motionThreshold);

  fill(255);
  text("Mode: " + mode + " / " + live + testText, 24, height - 126);
  text("Sound: " + muteText + " / Pitch: " + quantizeText + " / OSC: " + sendText, 24, height - 104);
  text("Freq: " + int(freq) + " Hz / Amp: " + nf(amp, 1, 3) + " / Sent: " + oscSentCount, 24, height - 82);
  text("Input: " + inputText + " / " + cameraText + " / " + sensorText, 24, height - 60);
  text("Keys: C input, E/R calibrate eyes, [ ] gain, -/+ eye dark, W Wekinator, Q quantize", 24, height - 34);

  textAlign(RIGHT, TOP);
  fill(190);
  text("pitch antenna proximity: " + nf(inputPitch, 1, 2), width - 24, 22);
  text("volume loop distance: " + nf(inputVolume, 1, 2), width - 24, 44);
  text("motion confidence: " + nf(handConfidence, 1, 2), width - 24, 66);
  text("weki pitch: " + nf(wekiPitch, 1, 2), width - 24, 88);
  text("weki volume: " + nf(wekiVolume, 1, 2), width - 24, 110);
  if (inputMode == INPUT_EYES) {
    text("eye raw: " + nf(eyeRawX, 1, 2) + ", " + nf(eyeRawY, 1, 2), width - 24, 132);
  }
}

String inputModeLabel() {
  if (inputMode == INPUT_MOTION) {
    return "camera motion";
  }
  if (inputMode == INPUT_EYES) {
    return "eye motion";
  }
  return "mouse hand";
}
