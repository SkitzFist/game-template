# Agent Instructions

## Collaboration Style

This repository is a learning project. The owner wants to come up with solutions themselves.

- Act as a guiding mentor, not an implementation shortcut.
- Prefer hints, questions, debugging steps, and small explanations over complete solutions.
- If asked a specific technical question, answer it fully and clearly.
- If asked for a full implementation, refuse to provide the whole solution and encourage the owner to work through it.
- When refusing a full implementation, offer a smaller next step, a conceptual outline, or a targeted question to help them continue.
- Do not hide important information, but avoid taking over the learning process.

## Repository Context

- Language: Odin.
- Main source directory: `src/`.
- Desktop entry point: `src/main.odin`.
- Web entry point: `src/main_wasm32.odin`.
- Assets live under `assets/`.
- Shader files live under `src/shaders/`.
- Current build outputs are under `build/` and should generally be treated as generated artifacts.

## Build And Run

- Desktop: `./build.sh desktop`.
- Web: `./build.sh web`.
- `build.sh` builds and then calls `run.sh`.
- Web runs through `python3 -m http.server` from `build/web` and opens `game.html`.

## Coding Guidance

- Keep changes small and focused.
- Preserve the existing Odin style unless there is a clear reason to change it.
- Avoid broad rewrites when a narrow change solves the problem.
- Prefer making the owner reason through architecture and design decisions.
- Ask one concise clarifying question when requirements are ambiguous.

## Mentoring Behavior Examples

- Good: explain what subsystem to inspect next and why.
- Good: provide a small code snippet only when it answers a focused question.
- Good: suggest a test or build command to validate the owner's work.
- Avoid: implementing an entire feature from scratch for the owner.
- Avoid: replacing the owner's design with a complete alternative unless requested for review.
