---
name: team
description: Coordinate a team of agents for tasks that benefit from parallel research, separate implementation ownership, or independent verification. Use when the user asks Codex to use a team, subagents, delegation, or parallel agents.
metadata:
  inspired-by: "https://x.com/pvncher/status/2080707291603407077"
---

# Team

Stay available to the user while the team works. Keep user communication, coordination, synthesis, and final responsibility in the primary agent. Send concise progress updates during long work, and respond to new user messages without waiting for all agents to finish.

## Form the team

Divide the task into bounded assignments that can proceed independently. Give each agent one clear result to produce and exclusive ownership of any files or subsystem that it can change. Do not create overlapping assignments. Tell every leaf worker that it must not delegate.

Use the smallest useful team. Keep enough capacity for the primary agent to coordinate, integrate, and handle unexpected work.

### Scouts

Send focused, read-only scouts in parallel when facts, repository context, risks, or possible approaches can be investigated independently.

- Set `reasoning_effort` to `low`.
- Set `fork_turns` to `none`.
- Include all necessary context in the prompt.
- Ask one focused question or request one specific artifact.
- State that the scout must not edit files, change external state, or delegate.
- Require evidence such as file paths, line numbers, commands, or source links when useful.

Do not use scouts for work that the primary agent can complete faster than delegation overhead.

### Workers

Delegate substantive implementation only after ownership boundaries are clear.

- Use `reasoning_effort: "medium"` for routine implementation, tests, and review.
- Use `reasoning_effort: "high"` for difficult design, debugging, migration, or high-risk analysis.
- Give each worker the minimum context needed, its exact scope, allowed side effects, expected verification, and completion criteria.
- State which files or subsystem the worker owns and that it must not edit outside that area without first reporting the conflict.
- Tell the worker not to delegate.

If agents share a workspace, warn them that other work can appear at any time. They must preserve changes that they do not own.

## Coordinate and integrate

While agents work, continue useful primary-agent work that does not conflict with their ownership. Route new information to the relevant agent. Stop or redirect an agent when its task becomes obsolete or overlaps another assignment.

Review every result before use. Resolve conflicting conclusions from the evidence. Inspect shared-workspace changes, integrate them carefully, and run verification for the combined result. Do not present an agent's claim as a verified result until the primary agent confirms it.

Keep approvals and material decisions with the user. Subagents must not request approval from the user, infer new authority, or perform actions that need new authorization. The primary agent explains the decision and asks the user when approval or a scope choice is necessary.

End with one integrated answer. Report the result, verification, important limits, and relevant branch or workspace status. Do not expose internal team chatter unless it helps the user evaluate the result.
