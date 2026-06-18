# Wekinator Projects

This folder is reserved for trained Wekinator projects that are intentionally included in the final deliverable.

## Recommended Project

Save the first real trained project as:

```text
wekinator_projects/expressive_6x4/
```

A ready-to-open scaffold for the expressive demo is included at:

```text
wekinator_projects/expressive_6x4/AdaptiveExpressiveTheremin6x4/AdaptiveExpressiveTheremin6x4.wekproj
```

The first saved bootstrap-trained project is:

```text
wekinator_projects/thereminwekinator/theremin/theremin.wekproj
```

Use this setup:

```text
Inputs: 6
Outputs: 4
Input OSC: /wek/inputs
Input port: 6448
Output OSC: /wek/outputs
Output host: localhost
Output port: 12000
Output type: All continuous
```

## What to Document

When a trained project is added, include a short note in its folder with:

- training date
- input mode used, such as mouse or camera motion
- number of examples
- intended behavior
- known limitations

## Important

Do not present a generated or untested Wekinator project as final. The meaningful artifact is a model trained from a real interaction session, then tested in Processing with `W` mode enabled.

If time is short, `tools/train_wekinator_demo.py` can create a bootstrap model by sending synthetic examples through Wekinator's OSC control messages. Treat that as a recoverable demo baseline, then add real examples manually when possible.
