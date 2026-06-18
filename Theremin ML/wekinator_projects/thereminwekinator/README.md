# thereminwekinator

Saved Wekinator project for the Adaptive Expressive Theremin demo.

## Status

```text
Saved: 2026-06-11
Profile: expressive 6 inputs / 4 outputs
Input OSC: /wek/inputs
Input port: 6448
Output OSC: /wek/outputs
Output host: localhost
Output port: 12000
Output type: All continuous
```

## Files

```text
theremin/theremin.wekproj
theremin/inputConfig.xml
theremin/outputConfig.xml
theremin/current/currentData.arff
theremin/current/models/model0.xml
theremin/current/models/model1.xml
theremin/current/models/model2.xml
theremin/current/models/model3.xml
```

## Training Summary

```text
Training rows: 544
Inputs: 6
Outputs/models: 4
```

The saved data comes from the bootstrap Wekinator training flow. It is suitable as a demo baseline for showing real-time learned mapping, but it should be framed as a bootstrap model. If time allows, add a few real user examples in Wekinator before the final presentation.

## Demo Use

1. Open `theremin/theremin.wekproj` in Wekinator.
2. Click `Start listening` if needed.
3. Click `Run`.
4. Open the Processing sketch.
5. Press `X` until `expressive OSC: 6 inputs / 4 outputs`.
6. Press `W` to use Wekinator.
7. Confirm Processing says `Mode: WEKINATOR / receiving`.
