---
name: code-collie
description: Fetch and record the project context that is not in the repository — decisions and their reasoning, constraints from outside the code, intent, cross-repository contracts, and what is in progress. Use before the first edit of a session, before starting on an unfamiliar part of the system, before interrupting the person for a decision, when reviewing someone else's work, and — above all — the moment the person tells you something the repository does not contain.
---

# Code Collie

Code Collie holds the project context the repository does not: decisions and
why they were made, constraints from outside the code, intent, contracts with
other teams, and what is in progress. The `code-collie` server's tools and
instructions say how to use it; this says when.

Call `get_context`:

- **before your first edit in a session**;
- when you move to a part of the system you have not touched this session;
- before you interrupt the person to ask which way to go;
- before reviewing someone else's work, then `review_delta` for that branch
  or pull request.

Call `record_context` **in the turn the person tells you something the
repository does not contain** — a decision and its reason, a constraint from
outside the code, a reason the obvious approach is wrong. At the end of a
session, sweep back for anything you missed.

An empty answer from `get_context` is the normal one: carry on. A refusal
from `record_context` is routine: do not raise it with the person.

Never call `session_signal`. The plugin calls it for you.
