# TSP Platform

## Purpose

This repository coordinates independently versioned TSP repositories. It owns repository inventory, compatibility policy, workspace bootstrap helpers, and cross-repository integration checks.

## Boundaries

- Do not copy application source from `TSP-template`, `TSP-backend`, or game repositories into this repository.
- Do not add Git submodules unless reproducible commit-level composition becomes a demonstrated requirement.
- Keep component builds, releases, migrations, and platform matrices in the component repository that owns them.
- Add only cross-repository checks that exercise a public contract between registered repositories.
- Treat `repositories.json` as the machine-readable inventory and compatibility declaration.
- A game entry must identify its template ref, backend REST API major, and WebSocket protocol version.
- Keep API implementation and schemas with their owning repository until multiple independent consumers justify a separately versioned contract repository.

## Documentation and CI

- Keep `README.md` and explanatory documents in Korean. Preserve commands, paths, identifiers, and configuration names exactly.
- Pin third-party GitHub Actions to full commit SHAs.
- Grant workflows read-only permissions unless a concrete job requires more.
- Never place credentials, tokens, generated clients, build output, or cloned component repositories in Git.
- Use `.tmp/qa/` for local integration logs and other disposable verification artifacts.

## Verification

- Validate `repositories.json` after inventory changes.
- Run both bootstrap helpers in non-destructive conditions when their behavior changes.
- Run the backend integration smoke helper after changing health, echo, process startup, or CI wiring.
- Do not weaken component quality gates to make the integration workflow pass.
