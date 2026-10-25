---
name: map-code
description: Thoroughly map the existing code before making changes.
disable-model-invocation: true
---

Before we change anything, map this entire codebase. Trace every piece of code this task and session will touch, what depends on it, and what breaks if it changes. Flag any dead code, hidden side effects, and literally anything you're guessing about that's not proven by code reads and specific lines. No code edits until I approve the map manually. For anything you call unused, say where you searched. Put every guess in one list at the end.
