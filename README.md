# Processing Wekinator Theremin

Virtual theremin built with Processing and Wekinator.

The sketch simulates a theremin with two virtual antennas:

- A vertical pitch antenna on the right.
- A volume loop on the left.
- A virtual hand controlled by the mouse, camera motion detection, or experimental eye-motion detection.

Processing sends the virtual hand features to Wekinator through OSC. Wekinator learns a continuous mapping and sends back `pitch` and `volume`, which Processing turns into a sine-wave theremin sound and reactive visuals.

## Main Sketch

Open this sketch in Processing:

`processing_wekinator_theremin/processing_wekinator_theremin.pde`

## Processing Libraries

Install these Processing libraries:

- `oscP5`
- `Sound`
- `Video Library for Processing 4`

In this machine they are installed under:

`~/Documents/Processing/libraries`

If Processing says `No library found for processing.video`, fully quit Processing with `Cmd+Q` and reopen it. Processing only scans contributed libraries when the app starts. Also check:

`Processing > Settings/Preferences > Sketchbook location`

It should point to:

`/Users/meco/Documents/Processing`

The mixed sketch imports `processing.video.*` at compile time, so the `Video Library for Processing 4` must be installed even when using the mouse input mode.

## Wekinator Setup

Create a new Wekinator project:

- Inputs: `2`
- Outputs: `2`
- Output type: `All continuous`
- Input OSC message: `/wek/inputs`
- Input OSC port: `6448`
- Output OSC message: `/wek/outputs`
- Output host: `localhost`
- Output port: `12000`

Meaning of the inputs:

- Input 1: proximity to the pitch antenna.
- Input 2: distance from the volume loop.

Meaning of the outputs:

- Output 1: pitch, from `0.0` to `1.0`.
- Output 2: volume, from `0.0` to `1.0`.

## Controls

- `C`: switch input mode, mouse hand / camera motion / eye motion.
- `M`: mute / unmute.
- `W`: direct preview / Wekinator mode.
- `Q`: continuous pitch / pentatonic pitch.
- `T`: test tone.
- `R`: recalibrate camera motion background.
- `V`: mirror camera.
- `[` and `]`: adjust motion threshold.
  In eye mode, these adjust dark-pixel sensitivity instead.

## Training Example

Record 1-2 seconds for each example in Wekinator:

| Gesture | Pitch | Volume |
| --- | ---: | ---: |
| hand on the left volume loop | 0.0 | 0.0 |
| hand far from loop and far from pitch antenna | 0.15 | 0.8 |
| hand in the center | 0.45 | 0.65 |
| hand medium close to pitch antenna | 0.7 | 0.75 |
| hand very close to pitch antenna | 1.0 | 0.85 |
| hand high and close to pitch antenna | 1.0 | 1.0 |

Then press `Train` and `Run` in Wekinator. In Processing, press `W` until the HUD says:

`Mode: WEKINATOR / receiving`

## MacBook Pro Camera Notes

The camera motion mode uses motion detection, not anatomical hand tracking. It works best when:

- The room has stable lighting.
- Only one hand is moving.
- The background is not moving.
- You press `R` while still to recalibrate the background.

On macOS, the first camera run may require permission:

`System Settings > Privacy & Security > Camera > Processing`

Enable Processing, then restart Processing.

## Eye Motion Mode

Eye mode is experimental. A MacBook Pro webcam cannot detect the retina. It can only estimate eye or pupil movement from the visible eye region in the camera image.

To try it:

1. Press `C` until the HUD says `Input: eye motion`.
2. Sit close to the MacBook camera.
3. Keep your face mostly still.
4. Make sure your eyes are inside the yellow `eye region`.
5. Look left, right, up, and down.
6. Use `[` and `]` if the dark-pixel count is too high or too low.

This works best with good frontal light and without strong reflections on glasses.

For a stronger GitHub/class explanation, call it `experimental gaze-inspired control`, not medical eye tracking.

## macOS Permission Troubleshooting

### Camera permission

If camera mode does not show video, check:

`System Settings > Privacy & Security > Camera > Processing`

Enable Processing, then fully quit and reopen Processing.

### Documents or sketchbook permission

If Processing cannot read sketches or libraries from `Documents`, check:

`System Settings > Privacy & Security > Files and Folders`

Allow Processing to access the Documents folder. If that option does not appear, try opening the sketch directly from Processing with:

`File > Open...`

### Local network / OSC permission

If Wekinator and Processing do not communicate even though the ports are correct, macOS may ask for Local Network access. Check:

`System Settings > Privacy & Security > Local Network`

Enable Processing and Wekinator if they appear there. Then restart both apps.

### Blocked library files

If macOS blocks a downloaded Processing library, remove quarantine attributes from the installed library folder:

```bash
xattr -dr com.apple.quarantine ~/Documents/Processing/libraries/video
```

For this machine, the same can be useful for the other libraries:

```bash
xattr -dr com.apple.quarantine ~/Documents/Processing/libraries/sound
xattr -dr com.apple.quarantine ~/Documents/Processing/libraries/oscP5
```

### GitHub push permission

If `git push` fails with authentication errors, use one of these:

- HTTPS with browser/token authentication.
- SSH with a GitHub SSH key.
- GitHub CLI login with `gh auth login`.

Common errors:

- `Permission denied (publickey)`: SSH key is missing or not linked to GitHub.
- `Authentication failed`: HTTPS credentials/token need refresh.
- `remote origin already exists`: the repo already has a remote configured; update it instead of adding it again.

## Course Connection

This project demonstrates a machine-learning digital music interface:

`gesture features -> Wekinator model -> musical control outputs -> sound/visual feedback`

The direct mode shows a programmed mapping. The Wekinator mode shows a learned mapping, allowing non-linear and more expressive behavior than a fixed `mouseX -> pitch` rule.
