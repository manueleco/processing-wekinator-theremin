import processing.video.*;
import processing.serial.*;
import oscP5.*;
import netP5.*;
import processing.sound.*;
import java.io.File;

// Virtual antenna theremin for MacBook Pro.
// Processing -> Wekinator: /wek/inputs, localhost:6448
//   basic profile: 2 inputs = pitch proximity, volume loop distance
//   expressive profile: 6 inputs = pitch, volume, speed, acceleration, confidence, noise
//   sensor fusion profile: 10 inputs = expressive inputs + Arduino physical sensor features
// Wekinator -> Processing: /wek/outputs, localhost:12000
//   basic profile: 2 outputs = pitch, volume
//   expressive profile: 4 outputs = pitch, volume, vibrato, timbre brightness

final int WEKINATOR_INPUT_PORT = 6448;
final int PROCESSING_LISTEN_PORT = 12000;
final int INPUT_MOUSE = 0;
final int INPUT_KEYBOARD = 1;
final int INPUT_MOTION = 2;
final int INPUT_EYES = 3;
final int INPUT_ARDUINO = 4;
final int PITCH_CONTINUOUS = 0;
final int PITCH_CHROMATIC = 1;
final int PITCH_PENTATONIC = 2;
final int PITCH_ODE_TO_JOY = 3;
final int WEKI_BASIC = 0;
final int WEKI_EXPRESSIVE = 1;
final int WEKI_FUSION = 2;
final int PRACTICE_OFF = 0;
final int PRACTICE_MELODY = 1;
final int PRACTICE_TRAJECTORY = 2;

Capture camera;
Serial arduinoPort;
OscP5 oscP5;
NetAddress wekinator;
SinOsc theremin;
SawOsc timbreOsc;

int[] previousPixels;
boolean cameraAvailable = false;
boolean cameraTried = false;
boolean cameraStarting = false;
int cameraStartMillis = -9999;
String cameraStatus = "camera off";
boolean mirrorCamera = true;
int inputMode = INPUT_MOUSE;
boolean arduinoAvailable = false;
boolean arduinoTried = false;
String arduinoPortName = "";
String lastArduinoLine = "";
int lastArduinoMillis = -9999;

float handX = 450;
float handY = 280;
float rawHandX = 450;
float rawHandY = 280;
float handConfidence = 0;
float previousHandX = 450;
float previousHandY = 280;
float previousInstantSpeed = 0;
float movementSpeed = 0;
float movementAcceleration = 0;
float sensorNoise = 0;
float expressionEnergy = 0;
float arduinoPitchMm = -1;
float arduinoVolumeMm = -1;
float arduinoPitchControl = 0;
float arduinoVolumeControl = 0.75;
float arduinoConfidence = 0;
float arduinoSpeed = 0;
float arduinoNoise = 0;
float previousArduinoPitchControl = 0;
float previousArduinoVolumeControl = 0.75;
float arduinoMinMm = 50;
float arduinoMaxMm = 650;
float motionThreshold = 38;
int motionPixels = 0;
float eyeDarkOffset = 32;
int eyeDarkPixels = 0;
float eyeSensitivityX = 4.2;
float eyeSensitivityY = 8.0;
float eyeDeadZoneX = 0.018;
float eyeDeadZoneY = 0.010;
float eyeRawX = 0.5;
float eyeRawY = 0.5;
float eyeCenterX = 0.5;
float eyeCenterY = 0.5;
boolean eyeCalibrated = false;
boolean requestEyeCalibration = false;

float eyeRoiX = 0.22;
float eyeRoiY = 0.18;
float eyeRoiW = 0.56;
float eyeRoiH = 0.22;

float inputPitch = 0.5;
float inputVolume = 0.0;
float keyboardPitch = 0.5;
float keyboardVolume = 0.65;
int keyboardChromaticIndex = 18;
int keyboardMelodyIndex = 0;
float wekiPitch = 0.5;
float wekiVolume = 0.0;
float wekiVibrato = 0.0;
float wekiBrightness = 0.0;
boolean gotWekinatorOutput = false;
int lastWekinatorMillis = -9999;

float targetPitch = 0.5;
float targetVolume = 0.0;
float smoothPitch = 0.5;
float smoothVolume = 0.0;
float targetVibrato = 0.0;
float targetBrightness = 0.0;
float smoothVibrato = 0.0;
float smoothBrightness = 0.0;

boolean muted = true;
boolean useWekinator = false;
int pitchMode = PITCH_CONTINUOUS;
int currentMidiNote = -1;
int currentMelodyIndex = -1;
int previousMelodyIndexForSpeed = -1;
int lastMelodyStepMillis = -9999;
float melodyStepSpeed = 0;
boolean sendToWekinator = true;
int wekinatorProfile = WEKI_BASIC;
boolean testTone = false;
int oscSentCount = 0;
boolean dataLogging = false;
PrintWriter dataLog;
String trainingLabel = "free";
String dataLogFilename = "";
int dataLogRows = 0;
boolean practiceMode = false;
int practiceType = PRACTICE_OFF;
int practiceStep = 0;
int practiceScore = 0;
float practiceHoldSeconds = 0;
float practiceRequiredSeconds = 0.85;
String activeExerciseId = "ode_to_joy_note_hold";
String activeExerciseName = "Ode to Joy Note Hold";
String activeExerciseGoal = "Hit each note and hold it steadily.";
boolean exerciseConfigLoaded = false;
int[] practiceMelodyMidi;
ArrayList<PVector> trajectoryTargetPath = new ArrayList<PVector>();
ArrayList<PVector> trajectoryUserPath = new ArrayList<PVector>();
ArrayList<ArrayList<PVector>> trajectoryExercisePaths = new ArrayList<ArrayList<PVector>>();
ArrayList<String> trajectoryExerciseIds = new ArrayList<String>();
ArrayList<String> trajectoryExerciseNames = new ArrayList<String>();
ArrayList<String> trajectoryExerciseGoals = new ArrayList<String>();
ArrayList<String> trajectoryExpectedGestures = new ArrayList<String>();
ArrayList<Float> trajectoryExerciseTolerances = new ArrayList<Float>();
ArrayList<Float> trajectoryExerciseRequiredScores = new ArrayList<Float>();
ArrayList<Integer> trajectoryExerciseRepetitions = new ArrayList<Integer>();
ArrayList<Integer> trajectoryExerciseSampleCounts = new ArrayList<Integer>();
int trajectoryExerciseIndex = 0;
String trajectoryExerciseId = "rehab_horizontal_arc";
String trajectoryExerciseName = "Guided Reach Arc";
String trajectoryExerciseGoal = "Follow the target path smoothly.";
String trajectoryExpectedGesture = "arc";
String trajectoryDetectedGesture = "collecting";
float trajectoryScore = 0;
float trajectoryBestScore = 0;
float trajectoryDistance = 1;
float trajectoryCompletion = 0;
float trajectoryTolerance = 0.42;
float trajectoryRequiredScore = 72;
float trajectorySmoothness = 0;
float trajectoryPathLength = 0;
float trajectoryDirectness = 0;
int trajectoryDirectionChanges = 0;
int trajectoryReps = 0;
int trajectoryTargetReps = 3;
int trajectorySampleCount = 48;
int trajectoryLastSampleMillis = -9999;
int trajectoryLastRepMillis = -9999;
boolean demoGuide = false;
int demoStep = 0;
boolean presentationWindow = false;

float minFreq = 160.0;
float maxFreq = 1400.0;
float masterGain = 0.35;
float pitchFieldStartRatio = 0.28;
float pitchFieldStep = 0.035;
float volumeRange = 390.0;
int chromaticMinMidi = 48;
int chromaticMaxMidi = 84;

int[] pentatonicMidi = {
  48, 50, 52, 55, 57,
  60, 62, 64, 67, 69,
  72, 74, 76, 79, 81
};

int[] odeToJoyMidi = {
  64, 64, 65, 67, 67, 65, 64, 62,
  60, 60, 62, 64, 64, 62, 62,
  64, 64, 65, 67, 67, 65, 64, 62,
  60, 60, 62, 64, 62, 60, 60
};

void setup() {
  size(900, 560);
  surface.setResizable(true);
  surface.setTitle("Adaptive Expressive Theremin");
  smooth(8);
  colorMode(RGB, 255);

  oscP5 = new OscP5(this, PROCESSING_LISTEN_PORT);
  wekinator = new NetAddress("localhost", WEKINATOR_INPUT_PORT);

  theremin = new SinOsc(this);
  theremin.play();
  theremin.amp(0);

  timbreOsc = new SawOsc(this);
  timbreOsc.play();
  timbreOsc.amp(0);

  textFont(createFont("Arial", 16));
  loadExerciseConfig();
}

void draw() {
  updateArduinoFeatures();
  updateHandInput();
  updateInputs();

  if (sendToWekinator && frameCount % 2 == 0) {
    sendOscToWekinator();
  }

  boolean wekinatorIsLive = gotWekinatorOutput && millis() - lastWekinatorMillis < 1500;
  float directVibrato = constrain(expressionEnergy * 0.95, 0, 1);
  float directBrightness = constrain(inputPitch * 0.30 + movementSpeed * 0.70, 0, 1) * handConfidence;

  if (useWekinator && wekinatorIsLive) {
    targetPitch = constrain(wekiPitch, 0, 1);
    targetVolume = constrain(wekiVolume, 0, 1) * handConfidence;
    targetVibrato = wekinatorProfile != WEKI_BASIC ? constrain(wekiVibrato, 0, 1) * handConfidence : directVibrato;
    targetBrightness = wekinatorProfile != WEKI_BASIC ? constrain(wekiBrightness, 0, 1) * handConfidence : directBrightness;
  } else {
    targetPitch = inputPitch;
    targetVolume = inputVolume * handConfidence;
    targetVibrato = directVibrato;
    targetBrightness = directBrightness;
  }

  if (testTone) {
    targetPitch = 0.45;
    targetVolume = 0.8;
    targetVibrato = 0.18;
    targetBrightness = 0.18;
  }

  float pitchSmoothing = inputMode == INPUT_KEYBOARD ? 0.48 : 0.12;
  float volumeSmoothing = inputMode == INPUT_KEYBOARD ? 0.30 : 0.10;
  smoothPitch = lerp(smoothPitch, targetPitch, pitchSmoothing);
  smoothVolume = lerp(smoothVolume, muted ? 0 : targetVolume, volumeSmoothing);
  smoothVibrato = lerp(smoothVibrato, muted ? 0 : targetVibrato, 0.10);
  smoothBrightness = lerp(smoothBrightness, muted ? 0 : targetBrightness, 0.10);

  float baseFreq = pitchToFrequency(smoothPitch);
  updateMelodyStepSpeed();
  float vibratoRate = map(smoothVibrato, 0, 1, 4.0, 8.5);
  float vibratoDepthSemitones = map(smoothVibrato, 0, 1, 0.0, 0.85);
  float vibratoSemitones = sin(frameCount * 0.08 * vibratoRate) * vibratoDepthSemitones;
  float freq = baseFreq * pow(2.0, vibratoSemitones / 12.0);
  float amp = pow(constrain(smoothVolume, 0, 1), 1.35) * masterGain;
  float timbreMix = constrain(smoothBrightness, 0, 1);

  theremin.freq(freq);
  theremin.amp(amp * (1.0 - timbreMix * 0.42));
  timbreOsc.freq(freq);
  timbreOsc.amp(amp * timbreMix * 0.22);

  updatePracticeMode();
  logDataFrame(freq, amp);
  drawTheremin(freq, amp, wekinatorIsLive);
}

void captureEvent(Capture c) {
  c.read();
}

void serialEvent(Serial port) {
  String line = port.readStringUntil('\n');
  if (line != null) {
    parseArduinoLine(trim(line));
  }
}

void updateHandInput() {
  if (inputMode == INPUT_MOTION) {
    updateMotionHand();
  } else if (inputMode == INPUT_EYES) {
    updateEyeHand();
  } else if (inputMode == INPUT_ARDUINO) {
    updateArduinoHand();
  } else if (inputMode == INPUT_KEYBOARD) {
    updateKeyboardHand();
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

void updateKeyboardHand() {
  rawHandX = map(keyboardPitch, 0, 1, pitchFieldStartX(), pitchAntennaX());
  rawHandY = map(keyboardVolume, 0, 1, height - 90, 92);
  handConfidence = 1;
  motionPixels = 0;
  eyeDarkPixels = 0;
  eyeCalibrated = false;
  handX = lerp(handX, rawHandX, 0.48);
  handY = lerp(handY, rawHandY, 0.48);
}

void startCameraIfNeeded() {
  if (cameraAvailable || cameraStarting || cameraTried) {
    return;
  }

  cameraTried = true;
  cameraStarting = true;
  cameraStatus = "camera starting";
  cameraStartMillis = millis();

  try {
    String[] cameras = Capture.list();
    if (cameras != null && cameras.length > 0) {
      camera = new Capture(this, 640, 480);
      camera.start();
      cameraAvailable = true;
      cameraStatus = "camera on";
      println("Camera started.");
    } else {
      cameraAvailable = false;
      cameraStatus = "camera not found";
      println("Camera not found.");
    }
  } catch (Exception e) {
    cameraAvailable = false;
    cameraStatus = "camera failed";
    println("Camera could not be started: " + e.getMessage());
  } finally {
    cameraStarting = false;
  }
}

void startArduinoSerial() {
  if (arduinoAvailable || arduinoTried) {
    return;
  }

  arduinoTried = true;
  try {
    String[] ports = Serial.list();
    for (int i = 0; i < ports.length; i++) {
      String lower = ports[i].toLowerCase();
      if (lower.indexOf("usbmodem") >= 0 || lower.indexOf("usbserial") >= 0 || lower.indexOf("wchusbserial") >= 0) {
        arduinoPortName = ports[i];
        break;
      }
    }

    if (arduinoPortName.length() > 0) {
      arduinoPort = new Serial(this, arduinoPortName, 115200);
      arduinoPort.bufferUntil('\n');
      arduinoAvailable = true;
      println("Arduino serial connected: " + arduinoPortName);
    } else {
      println("Arduino serial not found. Press O to retry after connecting the board.");
    }
  } catch (Exception e) {
    println("Arduino serial could not be started: " + e.getMessage());
    arduinoAvailable = false;
    arduinoPort = null;
  }
}

void retryArduinoSerial() {
  try {
    if (arduinoPort != null) {
      arduinoPort.stop();
      arduinoPort = null;
    }
  } catch (Exception e) {
    println("Arduino serial close failed: " + e.getMessage());
  }

  arduinoAvailable = false;
  arduinoTried = false;
  arduinoPortName = "";
  lastArduinoMillis = -9999;
  startArduinoSerial();
}

void parseArduinoLine(String line) {
  if (line == null || line.length() == 0) {
    return;
  }

  String[] parts = splitTokens(line, ", ");
  if (parts.length < 2) {
    return;
  }

  int offset = parts[0].equals("A") ? 1 : 0;
  if (parts.length - offset < 1) {
    return;
  }

  arduinoPitchMm = parseSafeFloat(parts[offset], arduinoPitchMm);
  if (parts.length - offset >= 2) {
    arduinoVolumeMm = parseSafeFloat(parts[offset + 1], arduinoVolumeMm);
  }
  if (parts.length - offset >= 3) {
    arduinoConfidence = constrain(parseSafeFloat(parts[offset + 2], arduinoConfidence), 0, 1);
  } else {
    arduinoConfidence = 1;
  }

  lastArduinoLine = line;
  lastArduinoMillis = millis();
}

float parseSafeFloat(String value, float fallback) {
  try {
    return Float.parseFloat(value);
  } catch (Exception e) {
    return fallback;
  }
}

void updateArduinoFeatures() {
  boolean live = arduinoIsLive();

  if (!live) {
    arduinoConfidence = lerp(arduinoConfidence, 0, 0.06);
  }

  float pitchNorm = normalizeArduinoDistance(arduinoPitchMm);
  float volumeNorm = arduinoVolumeMm >= 0 ? normalizeArduinoDistance(arduinoVolumeMm) : 0.75;

  arduinoPitchControl = constrain(1.0 - pitchNorm, 0, 1);
  arduinoVolumeControl = constrain(volumeNorm, 0, 1);

  float pitchDelta = abs(arduinoPitchControl - previousArduinoPitchControl);
  float volumeDelta = abs(arduinoVolumeControl - previousArduinoVolumeControl);
  float instantArduinoSpeed = constrain((pitchDelta + volumeDelta) * 8.0, 0, 1);

  arduinoSpeed = lerp(arduinoSpeed, instantArduinoSpeed, 0.20);
  arduinoNoise = lerp(arduinoNoise, constrain(abs(instantArduinoSpeed - arduinoSpeed) * 3.0 + (1.0 - arduinoConfidence) * 0.25, 0, 1), 0.16);

  previousArduinoPitchControl = arduinoPitchControl;
  previousArduinoVolumeControl = arduinoVolumeControl;
}

boolean arduinoIsLive() {
  return arduinoAvailable && millis() - lastArduinoMillis < 900;
}

float normalizeArduinoDistance(float distanceMm) {
  if (distanceMm < 0) {
    return 1;
  }
  return constrain((distanceMm - arduinoMinMm) / (arduinoMaxMm - arduinoMinMm), 0, 1);
}

void updateArduinoHand() {
  if (!arduinoIsLive()) {
    updateMouseHand();
    return;
  }

  rawHandX = map(arduinoPitchControl, 0, 1, 110, pitchAntennaX());
  rawHandY = map(arduinoVolumeControl, 0, 1, height - 110, 95);
  handConfidence = lerp(handConfidence, constrain(arduinoConfidence, 0.2, 1), 0.25);
  motionPixels = 0;
  eyeDarkPixels = 0;
  eyeCalibrated = false;

  handX = lerp(handX, rawHandX, 0.25);
  handY = lerp(handY, rawHandY, 0.25);
}

void updateMotionHand() {
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

    float gazeX = 0.5 + applyDeadZone(eyeRawX - eyeCenterX, eyeDeadZoneX) * eyeSensitivityX;
    float gazeY = 0.5 + applyDeadZone(eyeRawY - eyeCenterY, eyeDeadZoneY) * eyeSensitivityY;

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
  if (inputMode == INPUT_ARDUINO && arduinoIsLive()) {
    inputPitch = arduinoPitchControl;
    inputVolume = arduinoVolumeControl;
  } else if (inputMode == INPUT_KEYBOARD) {
    inputPitch = keyboardPitch;
    inputVolume = keyboardVolume;
  } else {
    float pitchDistance = max(0, pitchAntennaX() - handX);
    inputPitch = constrain(1.0 - pitchDistance / pitchFieldRange(), 0, 1);

    float loopDistance = dist(handX, handY, volumeLoopX(), volumeLoopY());
    inputVolume = constrain((loopDistance - 35.0) / volumeRange, 0, 1);
  }

  float dx = handX - previousHandX;
  float dy = handY - previousHandY;
  float instantSpeed = constrain(sqrt(dx * dx + dy * dy) / 80.0, 0, 1);
  float instantAcceleration = constrain(abs(instantSpeed - previousInstantSpeed) * 4.0, 0, 1);

  movementSpeed = lerp(movementSpeed, instantSpeed, 0.22);
  movementAcceleration = lerp(movementAcceleration, instantAcceleration, 0.22);
  sensorNoise = lerp(sensorNoise, constrain(abs(instantSpeed - movementSpeed) * 3.5 + (1.0 - handConfidence) * 0.35, 0, 1), 0.18);
  expressionEnergy = constrain((movementSpeed * 0.65 + movementAcceleration * 0.35) * handConfidence, 0, 1);

  previousHandX = handX;
  previousHandY = handY;
  previousInstantSpeed = instantSpeed;
}

void sendOscToWekinator() {
  OscMessage msg = new OscMessage("/wek/inputs");
  msg.add(inputPitch);
  msg.add(inputVolume);
  if (wekinatorProfile == WEKI_EXPRESSIVE || wekinatorProfile == WEKI_FUSION) {
    msg.add(movementSpeed);
    msg.add(movementAcceleration);
    msg.add(handConfidence);
    msg.add(sensorNoise);
  }
  if (wekinatorProfile == WEKI_FUSION) {
    msg.add(arduinoPitchControl);
    msg.add(arduinoVolumeControl);
    msg.add(arduinoSpeed);
    msg.add(arduinoConfidence);
  }
  oscP5.send(msg, wekinator);
  oscSentCount++;
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/wek/outputs") && msg.typetag().length() >= 1) {
    wekiPitch = msg.get(0).floatValue();
    if (msg.typetag().length() >= 2) {
      wekiVolume = msg.get(1).floatValue();
    }
    if (msg.typetag().length() >= 3) {
      wekiVibrato = msg.get(2).floatValue();
    }
    if (msg.typetag().length() >= 4) {
      wekiBrightness = msg.get(3).floatValue();
    }
    gotWekinatorOutput = true;
    lastWekinatorMillis = millis();
  }
}

float pitchToFrequency(float value) {
  value = constrain(value, 0, 1);
  currentMidiNote = -1;
  currentMelodyIndex = -1;

  if (pitchMode == PITCH_PENTATONIC) {
    int index = int(round(value * (pentatonicMidi.length - 1)));
    index = constrain(index, 0, pentatonicMidi.length - 1);
    currentMidiNote = pentatonicMidi[index];
    return midiToFrequency(currentMidiNote);
  }

  if (pitchMode == PITCH_CHROMATIC) {
    currentMidiNote = int(round(map(value, 0, 1, chromaticMinMidi, chromaticMaxMidi)));
    currentMidiNote = constrain(currentMidiNote, chromaticMinMidi, chromaticMaxMidi);
    return midiToFrequency(currentMidiNote);
  }

  if (pitchMode == PITCH_ODE_TO_JOY) {
    int index = int(round(value * (odeToJoyMidi.length - 1)));
    index = constrain(index, 0, odeToJoyMidi.length - 1);
    currentMelodyIndex = index;
    currentMidiNote = odeToJoyMidi[index];
    return midiToFrequency(currentMidiNote);
  }

  return minFreq * pow(maxFreq / minFreq, value);
}

void updateMelodyStepSpeed() {
  if (pitchMode != PITCH_ODE_TO_JOY || currentMelodyIndex < 0) {
    melodyStepSpeed = lerp(melodyStepSpeed, 0, 0.05);
    previousMelodyIndexForSpeed = -1;
    return;
  }

  if (previousMelodyIndexForSpeed < 0) {
    previousMelodyIndexForSpeed = currentMelodyIndex;
    lastMelodyStepMillis = millis();
    return;
  }

  if (currentMelodyIndex != previousMelodyIndexForSpeed) {
    int now = millis();
    float seconds = max(0.05, (now - lastMelodyStepMillis) / 1000.0);
    float steps = abs(currentMelodyIndex - previousMelodyIndexForSpeed);
    melodyStepSpeed = lerp(melodyStepSpeed, steps / seconds, 0.55);
    previousMelodyIndexForSpeed = currentMelodyIndex;
    lastMelodyStepMillis = now;
  } else {
    melodyStepSpeed = lerp(melodyStepSpeed, 0, 0.018);
  }
}

float midiToFrequency(int midiNote) {
  return 440.0 * pow(2.0, (midiNote - 69) / 12.0);
}

String pitchModeLabel() {
  if (pitchMode == PITCH_CHROMATIC) {
    return "chromatic";
  }
  if (pitchMode == PITCH_PENTATONIC) {
    return "pentatonic";
  }
  if (pitchMode == PITCH_ODE_TO_JOY) {
    return "ode to joy";
  }
  return "continuous";
}

String currentPitchNoteLabel() {
  if (currentMidiNote < 0) {
    return "";
  }
  if (pitchMode == PITCH_ODE_TO_JOY) {
    return " / Note: " + midiNoteName(currentMidiNote) + " (" + (currentMelodyIndex + 1) + "/" + odeToJoyMidi.length + ")";
  }
  return " / Note: " + midiNoteName(currentMidiNote);
}

String midiNoteName(int midiNote) {
  String[] names = {
    "C", "C#", "D", "D#", "E", "F",
    "F#", "G", "G#", "A", "A#", "B"
  };
  return names[midiNote % 12] + str((midiNote / 12) - 1);
}

void keyPressed() {
  if (key == CODED && handleTrainerArrowKey()) {
    return;
  }

  if (key == 'm' || key == 'M') {
    muted = !muted;
  } else if (key == 'w' || key == 'W') {
    useWekinator = !useWekinator;
  } else if (key == 'q' || key == 'Q') {
    pitchMode = (pitchMode + 1) % 4;
    syncKeyboardTrainerToPitchMode();
  } else if (key == 's' || key == 'S') {
    sendToWekinator = !sendToWekinator;
  } else if (key == 'x' || key == 'X') {
    wekinatorProfile = (wekinatorProfile + 1) % 3;
    gotWekinatorOutput = false;
  } else if (key == 'o' || key == 'O') {
    retryArduinoSerial();
  } else if (key == 'l' || key == 'L') {
    toggleDataLogging();
  } else if (key == 'b' || key == 'B') {
    demoGuide = !demoGuide;
  } else if (key == 'n' || key == 'N') {
    demoGuide = true;
    demoStep = (demoStep + 1) % demoStepCount();
  } else if (key == 'p' || key == 'P') {
    cyclePracticeMode();
  } else if (key == 'z' || key == 'Z') {
    cycleTrajectoryExercise();
  } else if (key == 't' || key == 'T') {
    testTone = !testTone;
  } else if (key == 'c' || key == 'C') {
    cycleInputMode();
  } else if (key == 'k' || key == 'K') {
    retryCamera();
    resetMotionReference();
  } else if (key == 'u' || key == 'U') {
    togglePresentationWindow();
  } else if (key == 'i' || key == 'I') {
    adjustPitchFieldStart(-1);
  } else if (key == 'j' || key == 'J') {
    adjustPitchFieldStart(1);
  } else if (key == 'e' || key == 'E') {
    if (inputMode == INPUT_EYES) {
      requestEyeCalibration = true;
    }
  } else if (key == 'r' || key == 'R') {
    if (practiceType == PRACTICE_TRAJECTORY) {
      resetTrajectoryPractice(false);
    } else {
      resetMotionReference();
    }
  } else if (key == 'v' || key == 'V') {
    mirrorCamera = !mirrorCamera;
    if (inputMode == INPUT_EYES) {
      requestEyeCalibration = true;
    }
  } else if (key == 'g' || key == 'G') {
    if (practiceType == PRACTICE_TRAJECTORY) {
      adjustTrajectoryCalibration(1);
    } else {
      adjustSensorSensitivity(1);
    }
  } else if (key == 'f' || key == 'F') {
    if (practiceType == PRACTICE_TRAJECTORY) {
      adjustTrajectoryCalibration(-1);
    } else {
      adjustSensorSensitivity(-1);
    }
  } else if (key == 'y' || key == 'Y') {
    if (inputMode == INPUT_EYES) {
      eyeSensitivityY = min(16.0, eyeSensitivityY + 0.8);
    }
  } else if (key == 'h' || key == 'H') {
    if (inputMode == INPUT_EYES) {
      eyeSensitivityY = max(1.6, eyeSensitivityY - 0.8);
    }
  } else if (key == 'd' || key == 'D') {
    if (inputMode == INPUT_EYES) {
      eyeDarkOffset = min(80, eyeDarkOffset + 4);
    }
  } else if (key == 'a' || key == 'A') {
    if (inputMode == INPUT_EYES) {
      eyeDarkOffset = max(8, eyeDarkOffset - 4);
    }
  } else if (key >= '0' && key <= '9') {
    setTrainingLabel(key);
  }
}

boolean handleTrainerArrowKey() {
  if (keyCode != LEFT && keyCode != RIGHT && keyCode != UP && keyCode != DOWN) {
    return false;
  }

  if (inputMode != INPUT_KEYBOARD) {
    inputMode = INPUT_KEYBOARD;
    syncKeyboardTrainerToPitchMode();
  }

  if (keyCode == LEFT) {
    adjustKeyboardPitch(-1);
  } else if (keyCode == RIGHT) {
    adjustKeyboardPitch(1);
  } else if (keyCode == UP) {
    adjustKeyboardVolume(1);
  } else if (keyCode == DOWN) {
    adjustKeyboardVolume(-1);
  }

  resetMotionReference();
  return true;
}

void cycleInputMode() {
  if (inputMode == INPUT_MOUSE) {
    inputMode = INPUT_KEYBOARD;
  } else if (inputMode == INPUT_KEYBOARD) {
    inputMode = INPUT_MOTION;
  } else if (inputMode == INPUT_MOTION) {
    inputMode = INPUT_EYES;
    requestEyeCalibration = true;
  } else {
    inputMode = INPUT_MOUSE;
  }
  resetMotionReference();
}

void syncKeyboardTrainerToPitchMode() {
  if (pitchMode == PITCH_CHROMATIC) {
    keyboardChromaticIndex = constrain(round(keyboardPitch * chromaticStepCount()), 0, chromaticStepCount());
    keyboardPitch = keyboardChromaticIndex / float(max(1, chromaticStepCount()));
  } else if (pitchMode == PITCH_ODE_TO_JOY) {
    keyboardMelodyIndex = constrain(round(keyboardPitch * (odeToJoyMidi.length - 1)), 0, odeToJoyMidi.length - 1);
    keyboardPitch = keyboardMelodyIndex / float(max(1, odeToJoyMidi.length - 1));
  }
}

void adjustKeyboardPitch(int direction) {
  if (pitchMode == PITCH_CHROMATIC) {
    keyboardChromaticIndex = constrain(keyboardChromaticIndex + direction, 0, chromaticStepCount());
    keyboardPitch = keyboardChromaticIndex / float(max(1, chromaticStepCount()));
  } else if (pitchMode == PITCH_ODE_TO_JOY) {
    keyboardMelodyIndex = constrain(keyboardMelodyIndex + direction, 0, odeToJoyMidi.length - 1);
    keyboardPitch = keyboardMelodyIndex / float(max(1, odeToJoyMidi.length - 1));
  } else if (pitchMode == PITCH_PENTATONIC) {
    int index = constrain(round(keyboardPitch * (pentatonicMidi.length - 1)) + direction, 0, pentatonicMidi.length - 1);
    keyboardPitch = index / float(max(1, pentatonicMidi.length - 1));
  } else {
    keyboardPitch = constrain(keyboardPitch + direction * 0.035, 0, 1);
  }
}

void adjustKeyboardVolume(int direction) {
  keyboardVolume = constrain(keyboardVolume + direction * 0.06, 0, 1);
}

int chromaticStepCount() {
  return chromaticMaxMidi - chromaticMinMidi;
}

void retryCamera() {
  try {
    if (camera != null) {
      camera.stop();
      camera = null;
    }
  } catch (Exception e) {
    println("Camera close failed: " + e.getMessage());
  }

  cameraAvailable = false;
  cameraStarting = false;
  cameraTried = false;
  cameraStatus = "camera off";
  previousPixels = null;
  startCameraIfNeeded();
}

void togglePresentationWindow() {
  presentationWindow = !presentationWindow;
  if (presentationWindow) {
    surface.setLocation(0, 0);
    surface.setSize(displayWidth, max(560, displayHeight - 80));
  } else {
    surface.setSize(900, 560);
    surface.setLocation(max(0, (displayWidth - 900) / 2), max(0, (displayHeight - 560) / 2));
  }
}

void adjustPitchFieldStart(float direction) {
  pitchFieldStartRatio = constrain(pitchFieldStartRatio + direction * pitchFieldStep, 0.12, 0.48);
  resetMotionReference();
}

void adjustSensorSensitivity(float direction) {
  if (inputMode == INPUT_EYES) {
    eyeSensitivityX = constrain(eyeSensitivityX + direction * 0.4, 1.2, 12.0);
    eyeSensitivityY = constrain(eyeSensitivityY + direction * 0.8, 1.6, 16.0);
  } else if (inputMode == INPUT_MOTION) {
    motionThreshold = constrain(motionThreshold - direction * 4, 8, 95);
  }
}

void adjustTrajectoryCalibration(float direction) {
  trajectoryTolerance = constrain(trajectoryTolerance + direction * 0.025, 0.22, 0.70);
  trajectoryRequiredScore = constrain(trajectoryRequiredScore - direction * 2.0, 55, 90);
}

void cycleTrajectoryExercise() {
  if (trajectoryExercisePaths.size() == 0) {
    loadDefaultTrajectoryExercises();
  }
  trajectoryExerciseIndex = (trajectoryExerciseIndex + 1) % max(1, trajectoryExercisePaths.size());
  setTrajectoryExercise(trajectoryExerciseIndex);
  if (practiceType != PRACTICE_TRAJECTORY) {
    startPracticeMode(PRACTICE_TRAJECTORY);
  } else {
    resetTrajectoryPractice(false);
  }
}

void mousePressed() {
  muted = false;
}

void exit() {
  if (dataLog != null) {
    dataLog.flush();
    dataLog.close();
  }
  super.exit();
}

void toggleDataLogging() {
  if (dataLogging) {
    dataLogging = false;
    if (dataLog != null) {
      dataLog.flush();
      dataLog.close();
      dataLog = null;
    }
    println("Data logging stopped: " + dataLogFilename + " rows=" + dataLogRows);
    return;
  }

  File dir = new File(sketchPath("data_logs"));
  if (!dir.exists()) {
    dir.mkdirs();
  }

  String filename = "data_logs/session-" + year() + nf(month(), 2) + nf(day(), 2) + "-"
    + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".csv";
  dataLog = createWriter(filename);
  dataLog.println(dataLogHeader());
  dataLogging = true;
  dataLogFilename = filename;
  dataLogRows = 0;
  println("Data logging started: " + filename);
}

String dataLogHeader() {
  return "millis,input_mode,wekinator_profile,label,input_pitch,input_volume,keyboard_pitch,keyboard_volume,melody_step_speed,movement_speed,movement_acceleration,hand_confidence,sensor_noise,"
    + "arduino_pitch_mm,arduino_volume_mm,arduino_pitch_control,arduino_volume_control,arduino_speed,arduino_confidence,arduino_noise,"
    + "weki_pitch,weki_volume,weki_vibrato,weki_brightness,target_pitch,target_volume,target_vibrato,target_brightness,"
    + "practice_mode,practice_type,practice_step,practice_score,practice_target_midi,exercise_id,trajectory_score,trajectory_best_score,trajectory_distance,trajectory_tolerance,"
    + "trajectory_reps,trajectory_gesture,trajectory_expected_gesture,trajectory_smoothness,trajectory_path_length,trajectory_direction_changes,current_midi_note,freq,amp";
}

void logDataFrame(float freq, float amp) {
  if (!dataLogging || dataLog == null || frameCount % 3 != 0) {
    return;
  }

  dataLog.println(millis() + ","
    + inputModeLabelForData() + ","
    + wekinatorProfileLabelForData() + ","
    + trainingLabel + ","
    + nf(inputPitch, 1, 4) + ","
    + nf(inputVolume, 1, 4) + ","
    + nf(keyboardPitch, 1, 4) + ","
    + nf(keyboardVolume, 1, 4) + ","
    + nf(melodyStepSpeed, 1, 4) + ","
    + nf(movementSpeed, 1, 4) + ","
    + nf(movementAcceleration, 1, 4) + ","
    + nf(handConfidence, 1, 4) + ","
    + nf(sensorNoise, 1, 4) + ","
    + nf(arduinoPitchMm, 1, 2) + ","
    + nf(arduinoVolumeMm, 1, 2) + ","
    + nf(arduinoPitchControl, 1, 4) + ","
    + nf(arduinoVolumeControl, 1, 4) + ","
    + nf(arduinoSpeed, 1, 4) + ","
    + nf(arduinoConfidence, 1, 4) + ","
    + nf(arduinoNoise, 1, 4) + ","
    + nf(wekiPitch, 1, 4) + ","
    + nf(wekiVolume, 1, 4) + ","
    + nf(wekiVibrato, 1, 4) + ","
    + nf(wekiBrightness, 1, 4) + ","
    + nf(targetPitch, 1, 4) + ","
    + nf(targetVolume, 1, 4) + ","
    + nf(targetVibrato, 1, 4) + ","
    + nf(targetBrightness, 1, 4) + ","
    + practiceMode + ","
    + practiceTypeLabelForData() + ","
    + practiceStep + ","
    + practiceScore + ","
    + practiceTargetMidi() + ","
    + csvSafe(currentExerciseIdForData()) + ","
    + nf(trajectoryScore, 1, 2) + ","
    + nf(trajectoryBestScore, 1, 2) + ","
    + nf(trajectoryDistance, 1, 4) + ","
    + nf(trajectoryTolerance, 1, 4) + ","
    + trajectoryReps + ","
    + csvSafe(trajectoryDetectedGesture) + ","
    + csvSafe(trajectoryExpectedGesture) + ","
    + nf(trajectorySmoothness, 1, 4) + ","
    + nf(trajectoryPathLength, 1, 4) + ","
    + trajectoryDirectionChanges + ","
    + currentMidiNote + ","
    + nf(freq, 1, 2) + ","
    + nf(amp, 1, 4));
  dataLogRows++;
  dataLog.flush();
}

String csvSafe(String value) {
  if (value == null) {
    return "";
  }
  return value.replace(',', '_').replace('\n', ' ').replace('\r', ' ');
}

String inputModeLabelForData() {
  if (inputMode == INPUT_KEYBOARD) {
    return "keyboard";
  }
  if (inputMode == INPUT_MOTION) {
    return "motion";
  }
  if (inputMode == INPUT_EYES) {
    return "eyes";
  }
  if (inputMode == INPUT_ARDUINO) {
    return "arduino";
  }
  return "mouse";
}

String wekinatorProfileLabelForData() {
  if (wekinatorProfile == WEKI_FUSION) {
    return "fusion";
  }
  if (wekinatorProfile == WEKI_EXPRESSIVE) {
    return "expressive";
  }
  return "basic";
}

String practiceTypeLabelForData() {
  if (practiceType == PRACTICE_MELODY) {
    return "melody_hold";
  }
  if (practiceType == PRACTICE_TRAJECTORY) {
    return "trajectory_match";
  }
  return "off";
}

String currentExerciseIdForData() {
  if (practiceType == PRACTICE_TRAJECTORY) {
    return trajectoryExerciseId;
  }
  if (practiceType == PRACTICE_MELODY) {
    return activeExerciseId;
  }
  return "";
}

void setTrainingLabel(char numberKey) {
  if (numberKey == '1') {
    trainingLabel = "low";
  } else if (numberKey == '2') {
    trainingLabel = "middle";
  } else if (numberKey == '3') {
    trainingLabel = "high";
  } else if (numberKey == '4') {
    trainingLabel = "stable";
  } else if (numberKey == '5') {
    trainingLabel = "expressive";
  } else if (numberKey == '6') {
    trainingLabel = "noisy";
  } else if (numberKey == '7') {
    trainingLabel = "left";
  } else if (numberKey == '8') {
    trainingLabel = "right";
  } else if (numberKey == '9') {
    trainingLabel = "hold";
  } else {
    trainingLabel = "free";
  }
}

void cyclePracticeMode() {
  if (practiceType == PRACTICE_OFF) {
    startPracticeMode(PRACTICE_MELODY);
  } else if (practiceType == PRACTICE_MELODY) {
    startPracticeMode(PRACTICE_TRAJECTORY);
  } else {
    startPracticeMode(PRACTICE_OFF);
  }
}

void startPracticeMode(int nextType) {
  practiceType = nextType;
  practiceMode = practiceType != PRACTICE_OFF;

  if (practiceType == PRACTICE_MELODY) {
    pitchMode = PITCH_CHROMATIC;
    syncKeyboardTrainerToPitchMode();
    practiceHoldSeconds = 0;
  } else if (practiceType == PRACTICE_TRAJECTORY) {
    resetTrajectoryPractice(false);
  } else {
    practiceHoldSeconds = 0;
    trajectoryUserPath.clear();
  }
}

void updatePracticeMode() {
  if (practiceType == PRACTICE_OFF) {
    return;
  }

  if (practiceType == PRACTICE_TRAJECTORY) {
    updateTrajectoryPractice();
    return;
  }

  updateMelodyPractice();
}

void updateMelodyPractice() {
  int targetNote = practiceTargetMidi();
  boolean noteMatches = currentMidiNote == targetNote && smoothVolume > 0.08;

  if (noteMatches) {
    practiceHoldSeconds += 1.0 / max(1.0, frameRate);
  } else {
    practiceHoldSeconds = max(0, practiceHoldSeconds - 0.035);
  }

  if (practiceHoldSeconds >= practiceRequiredSeconds) {
    practiceScore++;
    practiceStep = (practiceStep + 1) % odeToJoyMidi.length;
    practiceHoldSeconds = 0;
  }
}

void updateTrajectoryPractice() {
  if (trajectoryTargetPath.size() == 0) {
    loadDefaultTrajectoryExercises();
  }

  int now = millis();
  if (now - trajectoryLastSampleMillis > 70 && handConfidence > 0.08) {
    trajectoryUserPath.add(normalizedHandPoint());
    trajectoryLastSampleMillis = now;
  }

  while (trajectoryUserPath.size() > max(trajectorySampleCount, 8)) {
    trajectoryUserPath.remove(0);
  }

  trajectoryCompletion = constrain(trajectoryUserPath.size() / float(max(1, trajectorySampleCount)), 0, 1);
  updateTrajectoryGestureMetrics();

  if (trajectoryUserPath.size() >= 6) {
    trajectoryDistance = dtwDistance(
      resamplePath(trajectoryUserPath, trajectorySampleCount),
      resamplePath(trajectoryTargetPath, trajectorySampleCount)
    );
    trajectoryScore = constrain(100.0f * (1.0f - trajectoryDistance / max(0.05f, trajectoryTolerance)), 0, 100);
    trajectoryBestScore = max(trajectoryBestScore, trajectoryScore);
  } else {
    trajectoryScore = lerp(trajectoryScore, 0, 0.08);
  }

  boolean strongMatch = trajectoryCompletion > 0.72 && trajectoryScore >= trajectoryRequiredScore;
  if (strongMatch && now - trajectoryLastRepMillis > 900) {
    trajectoryReps++;
    practiceScore++;
    trajectoryLastRepMillis = now;
    resetTrajectoryPractice(true);
  }
}

PVector normalizedHandPoint() {
  return new PVector(constrain(handX / max(1.0f, float(width)), 0, 1), constrain(handY / max(1.0f, float(height)), 0, 1));
}

void resetTrajectoryPractice(boolean keepBest) {
  trajectoryUserPath.clear();
  trajectoryCompletion = 0;
  trajectoryDistance = 1;
  trajectoryScore = 0;
  trajectoryDetectedGesture = "collecting";
  trajectorySmoothness = 0;
  trajectoryPathLength = 0;
  trajectoryDirectness = 0;
  trajectoryDirectionChanges = 0;
  if (!keepBest) {
    trajectoryBestScore = 0;
    trajectoryReps = 0;
  }
  trajectoryLastSampleMillis = -9999;
}

void updateTrajectoryGestureMetrics() {
  int count = trajectoryUserPath.size();
  if (count < 3) {
    trajectoryDetectedGesture = "collecting";
    trajectorySmoothness = 0;
    trajectoryPathLength = 0;
    trajectoryDirectness = 0;
    trajectoryDirectionChanges = 0;
    return;
  }

  PVector start = trajectoryUserPath.get(0);
  PVector end = trajectoryUserPath.get(count - 1);
  float minX = start.x;
  float maxX = start.x;
  float minY = start.y;
  float maxY = start.y;
  float totalDistance = 0;
  float previousAngle = 0;
  boolean hasPreviousAngle = false;
  int changes = 0;

  for (int i = 1; i < count; i++) {
    PVector previous = trajectoryUserPath.get(i - 1);
    PVector current = trajectoryUserPath.get(i);
    float dx = current.x - previous.x;
    float dy = current.y - previous.y;
    float segment = sqrt(dx * dx + dy * dy);
    totalDistance += segment;
    minX = min(minX, current.x);
    maxX = max(maxX, current.x);
    minY = min(minY, current.y);
    maxY = max(maxY, current.y);

    if (segment > 0.015) {
      float angle = atan2(dy, dx);
      if (hasPreviousAngle && abs(angleDifference(angle, previousAngle)) > 0.95) {
        changes++;
      }
      previousAngle = angle;
      hasPreviousAngle = true;
    }
  }

  float dx = end.x - start.x;
  float dy = end.y - start.y;
  float directDistance = sqrt(dx * dx + dy * dy);
  float widthBox = maxX - minX;
  float heightBox = maxY - minY;

  trajectoryPathLength = totalDistance;
  trajectoryDirectness = totalDistance > 0.0001 ? constrain(directDistance / totalDistance, 0, 1) : 0;
  trajectoryDirectionChanges = changes;
  trajectorySmoothness = constrain(trajectoryDirectness * 0.72f + (1.0f - min(1.0f, changes / 5.0f)) * 0.28f, 0, 1);
  trajectoryDetectedGesture = classifyTrajectoryGesture(dx, dy, widthBox, heightBox, totalDistance, directDistance, changes);
}

float angleDifference(float a, float b) {
  float diff = a - b;
  while (diff > PI) {
    diff -= TWO_PI;
  }
  while (diff < -PI) {
    diff += TWO_PI;
  }
  return diff;
}

String classifyTrajectoryGesture(float dx, float dy, float widthBox, float heightBox, float totalDistance, float directDistance, int changes) {
  if (totalDistance < 0.08) {
    return "hold";
  }
  if (changes >= 5 && totalDistance > 0.28) {
    return "unstable";
  }
  if (totalDistance > 0.45 && directDistance < 0.22 && widthBox > 0.16 && heightBox > 0.12) {
    return "loop";
  }
  if (abs(dx) > 0.18 && abs(dy) > 0.14) {
    if (dx > 0 && dy < 0) {
      return "diagonal_up_right";
    }
    if (dx < 0 && dy < 0) {
      return "diagonal_up_left";
    }
    if (dx > 0) {
      return "diagonal_down_right";
    }
    return "diagonal_down_left";
  }
  if (abs(dx) > abs(dy) * 1.35 && abs(dx) > 0.18) {
    return dx > 0 ? "reach_right" : "reach_left";
  }
  if (abs(dy) > abs(dx) * 1.35 && abs(dy) > 0.16) {
    return dy < 0 ? "reach_up" : "reach_down";
  }
  if (widthBox > 0.25 && heightBox > 0.10) {
    return "arc";
  }
  return "controlled_reach";
}

ArrayList<PVector> resamplePath(ArrayList<PVector> source, int count) {
  ArrayList<PVector> result = new ArrayList<PVector>();
  if (source == null || source.size() == 0 || count <= 0) {
    return result;
  }
  if (source.size() == 1) {
    for (int i = 0; i < count; i++) {
      result.add(source.get(0).copy());
    }
    return result;
  }

  float[] cumulative = new float[source.size()];
  cumulative[0] = 0;
  for (int i = 1; i < source.size(); i++) {
    cumulative[i] = cumulative[i - 1] + PVector.dist(source.get(i - 1), source.get(i));
  }

  float total = cumulative[source.size() - 1];
  if (total <= 0.0001) {
    for (int i = 0; i < count; i++) {
      result.add(source.get(0).copy());
    }
    return result;
  }

  int segment = 1;
  for (int i = 0; i < count; i++) {
    float target = map(i, 0, max(1, count - 1), 0, total);
    while (segment < cumulative.length - 1 && cumulative[segment] < target) {
      segment++;
    }
    float previousDistance = cumulative[segment - 1];
    float segmentLength = max(0.0001, cumulative[segment] - previousDistance);
    float t = constrain((target - previousDistance) / segmentLength, 0, 1);
    result.add(PVector.lerp(source.get(segment - 1), source.get(segment), t));
  }
  return result;
}

float dtwDistance(ArrayList<PVector> a, ArrayList<PVector> b) {
  if (a == null || b == null || a.size() == 0 || b.size() == 0) {
    return 1;
  }

  int n = a.size();
  int m = b.size();
  float[][] dtw = new float[n + 1][m + 1];
  for (int i = 0; i <= n; i++) {
    for (int j = 0; j <= m; j++) {
      dtw[i][j] = 999999;
    }
  }
  dtw[0][0] = 0;

  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      float cost = PVector.dist(a.get(i - 1), b.get(j - 1));
      float bestPrevious = min(dtw[i - 1][j], min(dtw[i][j - 1], dtw[i - 1][j - 1]));
      dtw[i][j] = cost + bestPrevious;
    }
  }

  return dtw[n][m] / max(1.0f, float(n + m));
}

int practiceTargetMidi() {
  if (practiceMelodyMidi == null || practiceMelodyMidi.length == 0) {
    return odeToJoyMidi[practiceStep % odeToJoyMidi.length];
  }
  return practiceMelodyMidi[practiceStep % practiceMelodyMidi.length];
}

int practiceLength() {
  if (practiceMelodyMidi == null || practiceMelodyMidi.length == 0) {
    return odeToJoyMidi.length;
  }
  return practiceMelodyMidi.length;
}

void resetMotionReference() {
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
  drawTopBar(wekinatorIsLive);
  drawFields();
  drawTrajectoryGuide();
  drawThereminBody();
  drawWave(freq, amp);
  drawControlPoint();
  drawVirtualHand();
  drawVolumeMeter(amp);
  drawHud(freq, amp, wekinatorIsLive);
  drawPracticeOverlay();
  drawDemoOverlay();
}

void drawTopBar(boolean wekinatorIsLive) {
  noStroke();
  fill(11, 15, 22, 238);
  rect(0, 0, width, 64);
  stroke(255, 255, 255, 28);
  strokeWeight(1);
  line(0, 64, width, 64);

  fill(255);
  textAlign(LEFT, CENTER);
  textSize(18);
  text("Adaptive Expressive Theremin", 24, 31);

  float chipX = min(width * 0.46, 430);
  chipX = drawStatusChip(chipX, 16, muted ? "Sound muted" : "Sound on", muted ? color(130) : color(112, 232, 163));
  chipX = drawStatusChip(chipX, 16, pitchModeLabel(), color(88, 205, 255));
  chipX = drawStatusChip(chipX, 16, inputModeLabel(), color(255, 194, 80));
  chipX = drawStatusChip(chipX, 16, useWekinator && wekinatorIsLive ? "ML live" : "Direct", useWekinator && wekinatorIsLive ? color(112, 232, 163) : color(185));
  drawStatusChip(chipX, 16, practiceTypeLabel(), practiceType == PRACTICE_OFF ? color(160) : color(255, 194, 80));
}

float drawStatusChip(float x, float y, String label, int accent) {
  textSize(12);
  float w = textWidth(label) + 26;
  noStroke();
  fill(255, 255, 255, 24);
  rect(x, y, w, 30, 6);
  fill(accent);
  ellipse(x + 12, y + 15, 7, 7);
  fill(235);
  textAlign(LEFT, CENTER);
  text(label, x + 22, y + 15);
  return x + w + 8;
}

String practiceTypeLabel() {
  if (practiceType == PRACTICE_MELODY) {
    return "Melody game";
  }
  if (practiceType == PRACTICE_TRAJECTORY) {
    return "Trajectory rehab";
  }
  return "Practice off";
}

void drawTrajectoryGuide() {
  if (practiceType != PRACTICE_TRAJECTORY || trajectoryTargetPath.size() == 0) {
    return;
  }

  noFill();
  stroke(255, 194, 80, 220);
  strokeWeight(4);
  beginShape();
  for (int i = 0; i < trajectoryTargetPath.size(); i++) {
    PVector point = trajectoryTargetPath.get(i);
    vertex(point.x * width, point.y * height);
  }
  endShape();

  for (int i = 0; i < trajectoryTargetPath.size(); i++) {
    PVector point = trajectoryTargetPath.get(i);
    float x = point.x * width;
    float y = point.y * height;
    noStroke();
    fill(i == 0 ? color(112, 232, 163) : color(255, 194, 80));
    ellipse(x, y, i == 0 ? 14 : 10, i == 0 ? 14 : 10);
  }

  if (trajectoryUserPath.size() > 1) {
    noFill();
    stroke(88, 205, 255, 220);
    strokeWeight(3);
    beginShape();
    for (int i = 0; i < trajectoryUserPath.size(); i++) {
      PVector point = trajectoryUserPath.get(i);
      vertex(point.x * width, point.y * height);
    }
    endShape();
  }
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

float pitchFieldStartX() {
  return constrain(width * pitchFieldStartRatio, 40, pitchAntennaX() - 150);
}

float pitchFieldRange() {
  return max(150, pitchAntennaX() - pitchFieldStartX());
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

  drawPitchFieldGuide();
}

void drawPitchFieldGuide() {
  float y = pitchAntennaTop() + 20;
  float startX = pitchFieldStartX();
  float endX = pitchAntennaX();

  stroke(88, 205, 255, 78);
  strokeWeight(2);
  line(startX, y, endX, y);
  line(startX, y - 8, startX, y + 8);
  line(endX, y - 8, endX, y + 8);
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
  String mode = useWekinator ? "WEKINATOR" : "DIRECT PREVIEW";
  String live = wekinatorIsLive ? "receiving" : "waiting";
  String muteText = muted ? "muted" : "sound on";
  String profileText = wekinatorProfileLabel();
  String pitchText = pitchModeLabel();
  String noteText = currentPitchNoteLabel();
  String sendText = sendToWekinator ? "sending" : "paused";
  String testText = testTone ? " / TEST TONE" : "";
  String inputText = inputModeLabel();
  if ((inputMode == INPUT_MOTION || inputMode == INPUT_EYES) && !cameraAvailable) {
    inputText += ", mouse fallback";
  } else if (inputMode == INPUT_ARDUINO && !arduinoIsLive()) {
    inputText += ", mouse fallback";
  }
  String cameraText = cameraStatusText();
  String arduinoText = arduinoIsLive()
    ? "arduino: " + int(arduinoPitchMm) + "mm/" + int(arduinoVolumeMm) + "mm"
    : "arduino: not connected, press O";
  String sensorText = sensorStatusText();
  String expressiveText = "speed: " + nf(movementSpeed, 1, 2)
    + " / accel: " + nf(movementAcceleration, 1, 2)
    + " / noise: " + nf(sensorNoise, 1, 2)
    + " / vib: " + nf(smoothVibrato, 1, 2)
    + " / bright: " + nf(smoothBrightness, 1, 2)
    + " / melody speed: " + nf(melodyStepSpeed, 1, 2);
  String logText = dataLogging ? "log on " + trainingLabel : "log off";
  String practiceText = practiceTypeLabelForData();
  String demoText = demoGuide ? "demo guide on" : "demo guide off";

  textAlign(LEFT, TOP);
  textSize(14);
  fill(255);
  text("Mode: " + mode + " / " + live + testText, 24, height - 154);
  text("Sound: " + muteText + " / Pitch: " + pitchText + noteText, 24, height - 132);
  text("Freq: " + int(freq) + " Hz / Amp: " + nf(amp, 1, 3) + " / OSC: " + sendText + " / " + profileText + " / Sent: " + oscSentCount, 24, height - 110);
  text("Input: " + inputText + " / " + cameraText + " / " + arduinoText + " / " + sensorText, 24, height - 82);
  text("Expression: " + expressiveText, 24, height - 58);
  text("Session: arrows trainer, U presentation, C input, Q pitch, W Weki, P exercise, Z trajectory, G/F calibrate, L log", 24, height - 34);

  textAlign(RIGHT, TOP);
  fill(190);
  float rightY = 78;
  text("pitch antenna proximity: " + nf(inputPitch, 1, 2), width - 24, rightY);
  text("volume loop distance: " + nf(inputVolume, 1, 2), width - 24, rightY + 22);
  text("motion confidence: " + nf(handConfidence, 1, 2), width - 24, rightY + 44);
  text("weki pitch: " + nf(wekiPitch, 1, 2), width - 24, rightY + 66);
  text("weki volume: " + nf(wekiVolume, 1, 2), width - 24, rightY + 88);
  text("weki vibrato: " + nf(wekiVibrato, 1, 2), width - 24, rightY + 110);
  text("weki brightness: " + nf(wekiBrightness, 1, 2), width - 24, rightY + 132);
  text(logText + " / rows " + dataLogRows + " / " + practiceText, width - 24, rightY + 154);
  text("exercise: " + currentExerciseName() + " / " + demoText, width - 24, rightY + 176);
  if (inputMode == INPUT_EYES) {
    text("eye raw: " + nf(eyeRawX, 1, 2) + ", " + nf(eyeRawY, 1, 2), width - 24, rightY + 198);
  }
}

String currentExerciseName() {
  if (practiceType == PRACTICE_TRAJECTORY) {
    return trajectoryExerciseName;
  }
  if (practiceType == PRACTICE_MELODY) {
    return activeExerciseName;
  }
  return "none";
}

String sensorStatusText() {
  if (inputMode == INPUT_KEYBOARD) {
    return "trainer pitch/vol: " + nf(keyboardPitch, 1, 2) + "/" + nf(keyboardVolume, 1, 2)
      + " / melody speed: " + nf(melodyStepSpeed, 1, 2) + " steps/s"
      + " / pitch start: " + int(pitchFieldStartX()) + "px";
  }
  if (inputMode == INPUT_EYES) {
    return "eye gain X/Y: " + nf(eyeSensitivityX, 1, 1) + "/" + nf(eyeSensitivityY, 1, 1)
      + " / dark: " + int(eyeDarkOffset)
      + " / pixels: " + eyeDarkPixels;
  }
  if (inputMode == INPUT_ARDUINO) {
    return "physical pitch/vol: " + nf(arduinoPitchControl, 1, 2) + "/" + nf(arduinoVolumeControl, 1, 2)
      + " / sensor speed: " + nf(arduinoSpeed, 1, 2);
  }
  return "motion: " + motionPixels + " / threshold: " + int(motionThreshold)
    + " / pitch start: " + int(pitchFieldStartX()) + "px";
}

String cameraStatusText() {
  if (cameraAvailable) {
    return "camera on";
  }
  if (cameraStarting) {
    int elapsed = millis() - cameraStartMillis;
    if (elapsed > 4500) {
      return "camera starting, check macOS permission";
    }
    return "camera starting";
  }
  return cameraStatus;
}

void drawPracticeOverlay() {
  if (practiceType == PRACTICE_OFF) {
    return;
  }

  if (practiceType == PRACTICE_TRAJECTORY) {
    drawTrajectoryPracticeOverlay();
    return;
  }

  drawMelodyPracticeOverlay();
}

void drawMelodyPracticeOverlay() {
  int targetNote = practiceTargetMidi();
  float progress = constrain(practiceHoldSeconds / practiceRequiredSeconds, 0, 1);
  boolean noteMatches = currentMidiNote == targetNote && smoothVolume > 0.08;

  float panelX = width * 0.5 - 170;
  float panelY = 104;
  float panelW = 340;
  float panelH = 94;

  noStroke();
  fill(12, 17, 24, 218);
  rect(panelX, panelY, panelW, panelH, 7);

  fill(255);
  textAlign(CENTER, TOP);
  textSize(18);
  text(activeExerciseName + ": " + midiNoteName(targetNote), width * 0.5, panelY + 12);

  fill(noteMatches ? color(112, 232, 163) : color(255, 194, 80));
  textSize(14);
  text("score " + practiceScore + " / step " + (practiceStep + 1) + " of " + practiceLength(), width * 0.5, panelY + 40);

  fill(255, 255, 255, 45);
  rect(panelX + 28, panelY + 68, panelW - 56, 10, 5);
  fill(noteMatches ? color(112, 232, 163) : color(255, 194, 80));
  rect(panelX + 28, panelY + 68, (panelW - 56) * progress, 10, 5);
}

void drawTrajectoryPracticeOverlay() {
  float panelX = width * 0.5 - 190;
  float panelY = 104;
  float panelW = 380;
  float panelH = 126;
  boolean matched = trajectoryScore >= trajectoryRequiredScore && trajectoryCompletion > 0.72;

  noStroke();
  fill(12, 17, 24, 224);
  rect(panelX, panelY, panelW, panelH, 7);

  fill(255);
  textAlign(CENTER, TOP);
  textSize(18);
  text(trajectoryExerciseName, width * 0.5, panelY + 12);

  fill(matched ? color(112, 232, 163) : color(255, 194, 80));
  textSize(14);
  text(
    "score " + int(trajectoryScore) + " / best " + int(trajectoryBestScore)
      + " / reps " + trajectoryReps + " of " + trajectoryTargetReps
      + " / " + (trajectoryExerciseIndex + 1) + "/" + max(1, trajectoryExercisePaths.size()),
    width * 0.5,
    panelY + 40
  );

  fill(205);
  textSize(13);
  text(trajectoryExerciseGoal, width * 0.5, panelY + 62);

  fill(175);
  text(
    "gesture " + trajectoryDetectedGesture + " / target " + trajectoryExpectedGesture
      + " / smooth " + int(trajectorySmoothness * 100)
      + " / tol " + nf(trajectoryTolerance, 1, 2),
    width * 0.5,
    panelY + 78
  );

  fill(255, 255, 255, 45);
  rect(panelX + 28, panelY + 102, panelW - 56, 10, 5);
  fill(matched ? color(112, 232, 163) : color(88, 205, 255));
  rect(panelX + 28, panelY + 102, (panelW - 56) * trajectoryCompletion, 10, 5);
}

void drawDemoOverlay() {
  if (!demoGuide) {
    return;
  }

  float panelW = 430;
  float panelH = 146;
  float panelX = 24;
  float panelY = 112;

  noStroke();
  fill(12, 17, 24, 226);
  rect(panelX, panelY, panelW, panelH, 7);

  fill(255);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Demo " + (demoStep + 1) + "/" + demoStepCount() + ": " + demoStepTitle(), panelX + 18, panelY + 14);

  fill(205);
  textSize(13);
  text("Setup: " + demoStepSetup(), panelX + 18, panelY + 42);
  text("Show: " + demoStepAction(), panelX + 18, panelY + 66);
  text("Why: " + demoStepPurpose(), panelX + 18, panelY + 90);

  fill(160);
  text("N next step / B hide guide", panelX + 18, panelY + 118);
}

int demoStepCount() {
  return 6;
}

String demoStepTitle() {
  if (demoStep == 1) {
    return "Precise notes";
  }
  if (demoStep == 2) {
    return "Guided melody";
  }
  if (demoStep == 3) {
    return "Practice game";
  }
  if (demoStep == 4) {
    return "Rehab trajectory";
  }
  if (demoStep == 5) {
    return "Wekinator expression";
  }
  return "Direct theremin";
}

String demoStepSetup() {
  if (demoStep == 1) {
    return "Press Q until Pitch: chromatic.";
  }
  if (demoStep == 2) {
    return "Press Q until Pitch: ode to joy.";
  }
  if (demoStep == 3) {
    return "Press P for practice mode.";
  }
  if (demoStep == 4) {
    return "Press P again for trajectory mode.";
  }
  if (demoStep == 5) {
    return "Press X for expressive 6x4, train Wekinator, then press W.";
  }
  return "Use mouse hand, DIRECT PREVIEW, sound on with M.";
}

String demoStepAction() {
  if (demoStep == 1) {
    return "Move horizontally and point out exact note names.";
  }
  if (demoStep == 2) {
    return "Move across the pitch field to discover the melody.";
  }
  if (demoStep == 3) {
    return "Hit and hold each target note until score advances.";
  }
  if (demoStep == 4) {
    return "Follow the arc; DTW scores the movement path.";
  }
  if (demoStep == 5) {
    return "Compare learned stabilization, vibrato, and brightness.";
  }
  return "Move near/far from antennas for pitch and volume.";
}

String demoStepPurpose() {
  if (demoStep == 1) {
    return "Shows musical precision instead of random frequencies.";
  }
  if (demoStep == 2) {
    return "Frames control as melody learning.";
  }
  if (demoStep == 3) {
    return "Connects music control with gamified exercise.";
  }
  if (demoStep == 4) {
    return "Shows measurable movement practice for rehab-style tasks.";
  }
  if (demoStep == 5) {
    return "Shows AI as personalized expressive mapping.";
  }
  return "Establishes the fixed baseline before ML.";
}

void loadExerciseConfig() {
  practiceMelodyMidi = subset(odeToJoyMidi, 0, odeToJoyMidi.length);
  loadDefaultTrajectoryExercises();
  boolean loadedTrajectoryConfig = false;

  try {
    File configFile = new File(sketchPath("../../../config/exercises.json"));
    if (!configFile.exists()) {
      configFile = new File(sketchPath("../config/exercises.json"));
    }
    if (!configFile.exists()) {
      println("Exercise config not found, using built-in Ode to Joy practice.");
      return;
    }

    JSONObject config = loadJSONObject(configFile.getAbsolutePath());
    JSONArray exercises = config.getJSONArray("exercises");
    if (exercises == null) {
      return;
    }

    for (int i = 0; i < exercises.size(); i++) {
      JSONObject exercise = exercises.getJSONObject(i);
      String type = jsonString(exercise, "type", "");

      if ("melody_hold".equals(type)) {
        loadMelodyExercise(exercise);
      } else if ("trajectory_match".equals(type)) {
        if (!loadedTrajectoryConfig) {
          clearTrajectoryExercises();
          loadedTrajectoryConfig = true;
        }
        registerTrajectoryExercise(exercise);
      }
    }
    setTrajectoryExercise(0);
  } catch (Exception e) {
    println("Exercise config could not be loaded: " + e.getMessage());
  }
}

void loadMelodyExercise(JSONObject exercise) {
  JSONArray notes = exercise.getJSONArray("targetNotes");
  if (notes == null || notes.size() == 0) {
    return;
  }

  int[] parsedNotes = new int[notes.size()];
  for (int n = 0; n < notes.size(); n++) {
    parsedNotes[n] = midiFromNoteName(notes.getString(n));
  }

  practiceMelodyMidi = parsedNotes;
  activeExerciseId = jsonString(exercise, "id", activeExerciseId);
  activeExerciseName = jsonString(exercise, "name", activeExerciseName);
  activeExerciseGoal = jsonString(exercise, "goal", activeExerciseGoal);
  practiceRequiredSeconds = jsonFloat(exercise, "holdSeconds", practiceRequiredSeconds);
  exerciseConfigLoaded = true;
  println("Loaded melody exercise: " + activeExerciseName + " notes=" + practiceMelodyMidi.length);
}

void clearTrajectoryExercises() {
  trajectoryExercisePaths.clear();
  trajectoryExerciseIds.clear();
  trajectoryExerciseNames.clear();
  trajectoryExerciseGoals.clear();
  trajectoryExpectedGestures.clear();
  trajectoryExerciseTolerances.clear();
  trajectoryExerciseRequiredScores.clear();
  trajectoryExerciseRepetitions.clear();
  trajectoryExerciseSampleCounts.clear();
  trajectoryExerciseIndex = 0;
}

void registerTrajectoryExercise(JSONObject exercise) {
  JSONArray path = exercise.getJSONArray("path");
  if (path == null || path.size() < 2) {
    return;
  }

  ArrayList<PVector> parsedPath = new ArrayList<PVector>();
  for (int i = 0; i < path.size(); i++) {
    JSONObject point = path.getJSONObject(i);
    parsedPath.add(new PVector(
      constrain(jsonFloat(point, "x", 0.5), 0, 1),
      constrain(jsonFloat(point, "y", 0.5), 0, 1)
    ));
  }

  registerTrajectoryExercise(
    jsonString(exercise, "id", trajectoryExerciseId),
    jsonString(exercise, "name", trajectoryExerciseName),
    jsonString(exercise, "goal", trajectoryExerciseGoal),
    jsonString(exercise, "expectedGesture", "controlled_reach"),
    parsedPath,
    jsonFloat(exercise, "tolerance", trajectoryTolerance),
    jsonFloat(exercise, "requiredScore", trajectoryRequiredScore),
    int(jsonFloat(exercise, "repetitions", trajectoryTargetReps)),
    int(jsonFloat(exercise, "sampleCount", trajectorySampleCount))
  );
  exerciseConfigLoaded = true;
}

void registerTrajectoryExercise(
  String id,
  String name,
  String goal,
  String expectedGesture,
  ArrayList<PVector> path,
  float tolerance,
  float requiredScore,
  int repetitions,
  int sampleCount
) {
  trajectoryExercisePaths.add(path);
  trajectoryExerciseIds.add(id);
  trajectoryExerciseNames.add(name);
  trajectoryExerciseGoals.add(goal);
  trajectoryExpectedGestures.add(expectedGesture);
  trajectoryExerciseTolerances.add(tolerance);
  trajectoryExerciseRequiredScores.add(requiredScore);
  trajectoryExerciseRepetitions.add(repetitions);
  trajectoryExerciseSampleCounts.add(sampleCount);
  println("Registered trajectory exercise: " + name + " points=" + path.size());
}

void setTrajectoryExercise(int index) {
  if (trajectoryExercisePaths.size() == 0) {
    loadDefaultTrajectoryExercises();
  }
  trajectoryExerciseIndex = constrain(index, 0, max(0, trajectoryExercisePaths.size() - 1));
  trajectoryTargetPath = trajectoryExercisePaths.get(trajectoryExerciseIndex);
  trajectoryExerciseId = trajectoryExerciseIds.get(trajectoryExerciseIndex);
  trajectoryExerciseName = trajectoryExerciseNames.get(trajectoryExerciseIndex);
  trajectoryExerciseGoal = trajectoryExerciseGoals.get(trajectoryExerciseIndex);
  trajectoryExpectedGesture = trajectoryExpectedGestures.get(trajectoryExerciseIndex);
  trajectoryTolerance = trajectoryExerciseTolerances.get(trajectoryExerciseIndex);
  trajectoryRequiredScore = trajectoryExerciseRequiredScores.get(trajectoryExerciseIndex);
  trajectoryTargetReps = trajectoryExerciseRepetitions.get(trajectoryExerciseIndex);
  trajectorySampleCount = trajectoryExerciseSampleCounts.get(trajectoryExerciseIndex);
  resetTrajectoryPractice(false);
}

void loadDefaultTrajectoryExercises() {
  clearTrajectoryExercises();
  ArrayList<PVector> arc = new ArrayList<PVector>();
  arc.add(new PVector(0.23f, 0.58f));
  arc.add(new PVector(0.36f, 0.46f));
  arc.add(new PVector(0.50f, 0.40f));
  arc.add(new PVector(0.64f, 0.46f));
  arc.add(new PVector(0.78f, 0.58f));
  registerTrajectoryExercise("rehab_horizontal_arc", "Guided Reach Arc", "Follow the arc with a smooth controlled movement.", "arc", arc, 0.42, 72, 3, 48);
  setTrajectoryExercise(0);
}

String jsonString(JSONObject object, String key, String fallback) {
  try {
    if (object != null && object.hasKey(key)) {
      return object.getString(key);
    }
  } catch (Exception e) {
  }
  return fallback;
}

float jsonFloat(JSONObject object, String key, float fallback) {
  try {
    if (object != null && object.hasKey(key)) {
      return object.getFloat(key);
    }
  } catch (Exception e) {
  }
  return fallback;
}

int midiFromNoteName(String noteName) {
  if (noteName == null) {
    return 60;
  }

  String value = trim(noteName).toUpperCase();
  if (value.length() < 2) {
    return 60;
  }

  int semitone = 0;
  char note = value.charAt(0);
  if (note == 'D') {
    semitone = 2;
  } else if (note == 'E') {
    semitone = 4;
  } else if (note == 'F') {
    semitone = 5;
  } else if (note == 'G') {
    semitone = 7;
  } else if (note == 'A') {
    semitone = 9;
  } else if (note == 'B') {
    semitone = 11;
  }

  int index = 1;
  if (index < value.length() && value.charAt(index) == '#') {
    semitone++;
    index++;
  } else if (index < value.length() && value.charAt(index) == 'B') {
    semitone--;
    index++;
  }

  int octave = 4;
  try {
    octave = Integer.parseInt(value.substring(index));
  } catch (Exception e) {
  }

  return constrain((octave + 1) * 12 + semitone, 0, 127);
}

String wekinatorProfileLabel() {
  if (wekinatorProfile == WEKI_FUSION) {
    return "fusion OSC: 10 inputs / 4 outputs";
  }
  if (wekinatorProfile == WEKI_EXPRESSIVE) {
    return "expressive OSC: 6 inputs / 4 outputs";
  }
  return "basic OSC: 2 inputs / 2 outputs";
}

String inputModeLabel() {
  if (inputMode == INPUT_KEYBOARD) {
    return "keyboard trainer";
  }
  if (inputMode == INPUT_MOTION) {
    return "camera motion";
  }
  if (inputMode == INPUT_EYES) {
    return "eye motion";
  }
  if (inputMode == INPUT_ARDUINO) {
    return "arduino sensor";
  }
  return "mouse hand";
}
