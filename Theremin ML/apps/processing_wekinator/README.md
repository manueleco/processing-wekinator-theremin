# Processing + Wekinator App

This is the main demo application for Adaptive Expressive Theremin.

Open the sketch:

```text
apps/processing_wekinator/processing_wekinator_theremin/processing_wekinator_theremin.pde
```

Core modes:

```text
DIRECT PREVIEW: fixed mapping from position to sound
WEKINATOR: learned mapping from movement features to expressive controls
MELODY GAME: guided Ode to Joy note-hold exercise
TRAJECTORY REHAB: DTW-scored movement trajectory exercise
```

The Processing sketch is responsible for sensing, sound, visuals, OSC, CSV logging, and the live presentation experience. Wekinator should be run as a companion app for the 6-input / 4-output expressive profile.
