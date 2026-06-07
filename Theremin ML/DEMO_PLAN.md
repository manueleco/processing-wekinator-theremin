# Demo Plan

This document defines the practical demo sequence for the Adaptive Expressive Theremin.

## Goal

Show a real, stable demo without requiring Arduino hardware.

Core message:

```text
Processing provides sensing, sound, and visuals.
Wekinator learns a personalized expressive mapping.
The system turns noisy movement into musical control.
```

## Demo Setup

Open:

```text
Theremin ML/processing_wekinator_theremin/processing_wekinator_theremin.pde
```

Run:

```text
Processing sketch + Wekinator
```

Use the Wekinator expressive profile:

```text
Inputs: 6
Outputs: 4
Input OSC: /wek/inputs
Input port: 6448
Output OSC: /wek/outputs
Output port: 12000
```

## Controls to Show

| Key | Demo use |
| --- | --- |
| `M` | unmute |
| `C` | switch input mode |
| `Q` | switch pitch mode |
| `X` | switch Wekinator profile |
| `W` | direct preview / Wekinator mode |
| `P` | practice mode |
| `L` | CSV data logging |
| `O` | Arduino retry, only if hardware is connected |

## Demo Sequence

### 1. Direct Theremin

Use:

```text
Input: mouse hand
Mode: direct preview
Pitch: continuous
```

Show:

- pitch changes with position
- volume changes with distance to the volume loop
- continuous glissando behavior

Purpose:

```text
baseline fixed mapping
```

### 2. Precise Musical Notes

Press `Q` until:

```text
Pitch: chromatic
```

Show:

- notes snap to semitones
- HUD displays note names
- the instrument becomes more musically controllable

Purpose:

```text
musical precision instead of random frequencies
```

### 3. Guided Melody

Press `Q` until:

```text
Pitch: ode to joy
```

Show:

- position selects melody steps
- the output becomes recognizable musical material

Purpose:

```text
education / melody-learning framing
```

### 4. Practice Mode

Press `P`.

Show:

- target note appears
- user must hit and hold the note
- score/step changes after successful hold

Purpose:

```text
gamified control task
```

### 5. Wekinator Expressive Mapping

Press `X` until:

```text
expressive OSC: 6 inputs / 4 outputs
```

Press `W` to use Wekinator after training.

Show:

- learned pitch and volume mapping
- vibrato and brightness react to expressive movement
- noisy movement can be mapped to more stable output

Purpose:

```text
AI as personalized musical mapping, not decorative AI
```

## Success Criteria

The demo is successful if:

- sketch runs without Arduino connected
- `C` cycles input modes without freezing
- sound works after unmuting
- chromatic pitch mode shows note names
- practice mode advances score
- Wekinator receives OSC input
- Wekinator output changes the instrument in `W` mode

## Current Hardware Status

Arduino support is prepared but not hardware-validated.

For now, the real demo should not depend on Arduino.

Arduino can be introduced later as:

```text
optional physical sensor-fusion extension
```
