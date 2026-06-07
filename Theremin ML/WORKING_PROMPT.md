# Working Prompt

Use this prompt before making changes to this project.

```text
Before making any change in this project, first review the current project context and documentation:
- README.md
- PROCESS.md
- DONE.md
- NEXT_STEPS.md
- FUTURE_WORK.md
- PROJECT_FORMALIZATION.md
- AI_TRAINING_IDEAS.md

For every task:
1. Check what has already been implemented.
2. Check what is pending or planned.
3. Validate whether the requested change fits the project scope and formal justification.
4. Follow existing project structure and naming conventions.
5. Prefer small, safe, incremental changes.
6. Avoid breaking the current Processing/Wekinator demo.
7. If adding code, update the relevant documentation.
8. If adding hardware, ML, gamification, or app-delivery features, document the rationale and future implications.
9. Run the appropriate verification:
   - Processing compile when editing `.pde`
   - Python syntax/test checks when editing `ml/`
   - Documentation consistency check when editing `.md`
10. After the change, summarize:
   - what was changed
   - what was verified
   - what remains pending
   - recommended next step

Always keep the project aligned with its core idea:
Adaptive Expressive Theremin is a machine-learning musical interface where Processing handles sensing/sound/visuals, Wekinator learns real-time personalized mappings, Arduino can provide physical sensor data, TensorFlow is a future/offline training path, and gamification can support educational or rehabilitation-style exercises.

Do not treat new ideas as isolated features. Relate every change to one of these pillars:
- musical control
- sensor fusion
- noise reduction
- expressivity
- accessibility/education
- gamified practice
- app deliverability

Before committing or finalizing, check:
- no unrelated files were added
- generated files are ignored
- docs reflect the new state
- the next step is clear
```

Short version:

```text
Before each project change, review README, PROCESS, DONE, NEXT_STEPS, FUTURE_WORK, PROJECT_FORMALIZATION, and AI_TRAINING_IDEAS. Keep changes small, aligned with the project pillars, documented, verified, and clear about what is done vs pending.
```

