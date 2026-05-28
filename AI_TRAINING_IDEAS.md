# AI Training Ideas for the Processing + Wekinator Theremin

This document organizes possible parameters and behaviors that could be trained with Wekinator in the virtual theremin project.

## What Is the AI Element?

The AI element is Wekinator's supervised machine-learning model.

Processing extracts movement features from the user, sends them to Wekinator through OSC, and Wekinator predicts musical control outputs in real time.

Current flow:

```text
movement / gaze / mouse features -> Wekinator model -> pitch and volume -> sound
```

The prediction is not about guessing the future. It is an estimation of the intended musical control based on the current gesture.

## 1. Continuous Control Parameters

These are parameters where Wekinator predicts a number, usually between `0.0` and `1.0`.

This is the easiest and most direct use of Wekinator for the current project.

| Trainable parameter | Possible input features | Musical use |
| --- | --- | --- |
| Pitch | hand/gaze X, distance to pitch antenna | Controls frequency or melody position |
| Volume | hand/gaze Y, distance from volume loop | Controls amplitude |
| Vibrato depth | movement speed, gaze instability, hand tremor | Adds expressive pitch variation |
| Vibrato rate | movement speed or acceleration | Faster movement creates faster vibrato |
| Timbre brightness | vertical position, speed, gesture intensity | Controls filter cutoff or oscillator mix |
| Reverb amount | distance from center, confidence, slow gestures | Creates spatial/depth effect |
| Attack time | speed of movement onset | Fast gestures create sharper note attacks |
| Release time | speed of movement away from active zone | Controls how long notes fade out |
| Melody step | pitch output in quantized mode | Selects notes from `Ode to Joy` or another melody |

In the current sketch, the most relevant trainable outputs are:

```text
output 1 = pitch or melody position
output 2 = volume
```

A stronger version could add:

```text
output 3 = timbre brightness
output 4 = vibrato amount
output 5 = reverb or effect amount
```

## 2. Improving Coordinate Precision

Wekinator can help with coordinate calibration, but it cannot magically create precise coordinates if the camera tracking is poor.

A good approach is:

```text
raw camera/gaze coordinates -> Wekinator -> corrected musical coordinates
```

For example, the user could train:

| User action | Desired output |
| --- | --- |
| look/point left | corrected X = 0.0 |
| look/point center | corrected X = 0.5 |
| look/point right | corrected X = 1.0 |
| look/point up | corrected Y = 0.0 |
| look/point down | corrected Y = 1.0 |

This would make the model behave like a personalized calibration layer.

Best inputs for coordinate correction:

- raw X position
- raw Y position
- calibrated X offset
- calibrated Y offset
- confidence value
- dark-pixel count in eye mode
- movement amount in motion mode

Best outputs:

- corrected X
- corrected Y
- confidence or activation amount

## 3. Movement Speed and Expressiveness

Speed is useful because it captures intention, not only position.

Possible features:

```text
velocityX = currentX - previousX
velocityY = currentY - previousY
speed = sqrt(velocityX^2 + velocityY^2)
acceleration = currentSpeed - previousSpeed
direction = atan2(velocityY, velocityX)
```

Possible musical mappings:

| Feature | Possible output |
| --- | --- |
| slow movement | soft volume, smoother timbre |
| fast movement | louder attack, brighter timbre |
| sudden movement | trigger a note or accent |
| unstable movement | more vibrato |
| stillness | sustain or reduce volume |

This would make the theremin feel less like a coordinate controller and more like an expressive instrument.

## 4. Recognizing Gesture Types

If the goal is to recognize gesture categories, Wekinator should be used as a classifier.

Possible gesture classes:

| Gesture class | Meaning in the instrument |
| --- | --- |
| left to right | play next phrase or move up melody |
| right to left | move backward in melody |
| up | increase register |
| down | decrease register |
| circle | enable vibrato or tremolo |
| zigzag | switch timbre |
| still center | sustain note |
| quick push | trigger accent |

This would change the AI task from:

```text
predict pitch and volume
```

to:

```text
recognize which gesture the user is performing
```

The output could then control musical modes, effects, or sections of a melody.

## 5. Recognizing Trajectory Shapes

For trajectory shapes, position alone is not enough. The model needs information over time.

There are two possible approaches:

### Option A: Use Dynamic Gesture Recognition

Wekinator can be used for temporal gesture recognition workflows, where examples are recorded as movement sequences instead of single static points.

This is appropriate for recognizing:

- circles
- swipes
- zigzags
- arcs
- repeated up/down movement
- intentional eye-motion patterns

### Option B: Send Summary Features

If staying with the current continuous/classifier setup, Processing can summarize the last short movement window and send features such as:

- start X / start Y
- end X / end Y
- total distance traveled
- average speed
- maximum speed
- direction angle
- bounding box width
- bounding box height
- duration
- number of direction changes
- curvature

Then Wekinator can classify the trajectory shape.

Example:

```text
trajectory features -> Wekinator classifier -> circle / swipe / zigzag / hold
```

## 6. Timbres and Instrument Parameters

The current sketch uses a sine-wave theremin sound. That is faithful to the theremin idea, but the project could become more interesting if Wekinator controls timbre.

Possible timbre parameters:

| Parameter | Effect |
| --- | --- |
| waveform mix | blend sine, triangle, saw, or square waves |
| filter cutoff | darker or brighter sound |
| filter resonance | more nasal or electronic tone |
| vibrato depth | more expressive pitch movement |
| tremolo depth | volume modulation |
| reverb | sense of space |
| delay | echo effect |
| distortion | more aggressive tone |
| sample selection | switch between instrument sounds |

Possible instrument modes:

- theremin sine tone
- flute-like soft tone
- violin-like sustained tone
- synth lead
- choir pad
- bell or mallet sound

Wekinator could predict:

```text
output 1 = pitch
output 2 = volume
output 3 = timbre brightness
output 4 = vibrato depth
output 5 = instrument blend
```

## 7. Suggested Project Versions

### Version 1: Current Theremin

Goal:

```text
control pitch and volume with mouse, motion, or eye movement
```

Wekinator task:

```text
continuous regression
```

Outputs:

```text
pitch, volume
```

### Version 2: Calibrated Eye Theremin

Goal:

```text
learn a personalized mapping from rough eye movement to stable musical coordinates
```

Wekinator task:

```text
continuous regression
```

Inputs:

```text
raw eye X, raw eye Y, confidence, dark-pixel count
```

Outputs:

```text
corrected X, corrected Y
```

### Version 3: Expressive Theremin

Goal:

```text
use speed and gesture intensity to control expressiveness
```

Wekinator task:

```text
continuous regression
```

Inputs:

```text
X, Y, speed, acceleration, direction, confidence
```

Outputs:

```text
pitch, volume, vibrato, brightness
```

### Version 4: Gesture-Recognizing Theremin

Goal:

```text
recognize movement shapes and use them as musical commands
```

Wekinator task:

```text
classification or temporal gesture recognition
```

Possible classes:

```text
swipe left, swipe right, up, down, circle, zigzag, hold
```

Outputs:

```text
gesture label or class
```

### Version 5: Melody Trainer

Goal:

```text
guide the user toward reproducing a known melody such as Ode to Joy
```

Wekinator task:

```text
continuous regression or classification
```

Possible outputs:

```text
melody step, note intensity, phrase section
```

This version is useful for education because the user learns pitch direction, musical memory, and motor coordination through interactive feedback.

## 8. Health, Education, and Accessibility Angle

This project can be justified beyond music performance.

Possible benefits:

- supports playful motor coordination practice
- connects movement to immediate auditory feedback
- can be adapted for users with limited hand movement
- can encourage eye-control experimentation
- can be used for pitch perception and melody learning
- can make rehabilitation exercises more engaging
- can support cause-and-effect learning in educational contexts

The strongest explanation is:

```text
The system turns small body or gaze movements into musical feedback, creating an interactive environment where users can train coordination, attention, timing, and expressive control.
```

## 9. Technologies That Could Complement It

Possible extensions:

- MediaPipe or OpenCV for stronger hand, face, or eye tracking
- Max/MSP, SuperCollider, Ableton Live, or Logic Pro for richer sound design
- MIDI output to control external instruments
- OSC to communicate with other creative coding tools
- webcam calibration for more stable gaze estimation
- wearable sensors such as accelerometers or EMG
- adaptive difficulty for education or therapy exercises
- data logging to analyze user progress over time

## Recommended Next Step

The most realistic next improvement is to add movement features to Processing:

```text
X, Y, velocityX, velocityY, speed, acceleration, confidence
```

Then create a new Wekinator project with more inputs and train outputs such as:

```text
pitch, volume, vibrato, timbre brightness
```

After that, a second experiment can focus on trajectory classification:

```text
circle, swipe, up, down, zigzag, hold
```

