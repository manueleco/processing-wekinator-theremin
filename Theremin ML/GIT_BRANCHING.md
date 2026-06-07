# Git Branching

This project uses three long-lived branches:

```text
dev
main
prod
```

## Branch Roles

### dev

Use `dev` for active implementation:

- Processing sketch changes
- Wekinator/demo workflow changes
- ML tooling changes
- documentation updates while they are still being shaped

This is the default branch for day-to-day work.

### main

Use `main` as the reviewed project branch:

- changes from `dev` after verification
- course-ready documentation
- stable Processing demo code
- tested ML scripts and setup notes

Before merging into `main`, run the relevant checks:

```text
Processing compile when `.pde` changes
Python syntax/checker when `ml/` changes
documentation consistency checks when `.md` changes
```

### prod

Use `prod` only for final/demo-ready snapshots:

- final presentation state
- exported app-ready state
- stable deliverable tags or release references

`prod` should move less often than `main`.

## Recommended Flow

```text
dev -> main -> prod
```

1. Work on `dev`.
2. Verify the change.
3. Merge or fast-forward `dev` into `main`.
4. Move `prod` only when the project is ready for a demo or final delivery.

## Current Rule

Unless explicitly requested otherwise, new project work should start on `dev`.
