# App Export

This document describes how to create a macOS app deliverable from the Processing sketch.

## Recommended Deliverable

The most realistic final deliverable is:

```text
Processing macOS app export + Wekinator companion app
```

Wekinator remains a separate application for the current course prototype.

## Export From Processing IDE

1. Open:

```text
Theremin ML/processing_wekinator_theremin/processing_wekinator_theremin.pde
```

2. In Processing:

```text
File -> Export Application
```

3. Choose macOS export.

4. Test the exported app by opening it directly.

## Export From Processing CLI

From repo root:

```bash
/Applications/Processing.app/Contents/MacOS/Processing cli \
  --sketch="/Users/meco/MBP Files/Gits/upf/SC/Theremin ML/processing_wekinator_theremin" \
  --output="/Users/meco/MBP Files/Gits/upf/SC/Theremin ML/dist/processing-export" \
  --force \
  --variant=macos-aarch64 \
  --export
```

Generated exports should remain untracked unless intentionally packaged for final delivery.

Current verification note:

```text
The sketch builds successfully from the CLI, but Processing 4.5.2 on this machine failed during CLI export with an internal NoSuchElementException. If this repeats, export from the Processing IDE instead.
```

## macOS Permissions

The exported app may need permissions for:

- camera
- local network / OSC
- serial port access if Arduino is used
- audio output

If the exported app cannot access camera or serial, open:

```text
System Settings -> Privacy & Security
```

and allow the exported app where appropriate.

## Demo App Checklist

Before considering the app deliverable ready:

- app launches
- sound works after `M`
- `C` cycles input modes without freezing
- `Q` changes pitch mode
- `P` starts practice mode
- `X` changes Wekinator profile
- `W` uses Wekinator output when Wekinator is running
- app still works without Arduino connected

## Future Web Version

A web version would be a separate implementation:

```text
React + WebAudio + Web Serial + TensorFlow.js
```

This is future work, not the primary course deliverable.
