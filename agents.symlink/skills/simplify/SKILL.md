---
name: simplify
description: Review completed or proposed work against its goal, remove unnecessary parts, and simplify what remains. Use when the user asks to challenge assumptions, reduce complexity, or check whether a solution does more than needed.
---

# Simplify

Check whether the work is the simplest solution that meets the user's goal.
Prefer deleting over simplifying, simplifying over optimizing, and optimizing
over automating. No change is a valid result.

## Review

1. Identify the intended outcome and the requirements that must still be met.
   Use the request and available context. Ask only if a missing fact would change
   the decision.
2. Examine the current work. Focus on the requested scope or recent changes.
   Look for weak assumptions, duplicate work, unused parts, and complexity added
   for needs that do not exist yet. Check assumptions against available evidence.
3. Ask what can be deleted without losing required behavior. Check uses and
   dependencies before removing anything. Tests, error handling, and documentation
   can serve a requirement even when they do not affect the normal path.
4. Simplify what remains. Make a change only when you can explain how it reduces
   complexity while preserving the intended outcome. Do not add abstractions,
   configuration, or automation without a current need.

## Apply and verify

Make the useful changes within the authorized scope. If the user asked only for
a review, report recommendations instead. Do not expand the task to unrelated work.

Use checks appropriate to the change to confirm that requirements still hold.
Stop when there is no clear, supported improvement left within scope. Do not
rewrite working code or text just to produce a change.

Briefly report what changed, why it is simpler, and what was checked. If no change
is needed, say why. Identify any important assumption that remains unverified.
