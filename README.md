# Code Collie for Claude Code

Code Collie holds the project context your assistant cannot get from the
repository: decisions and why they were made, constraints from outside the
code, and what is in progress. Your assistant fetches it before it edits and
records it when you tell it something new.

## Install

In Claude Code (2.1.275 or later):

```
/plugin install code-collie --marketplace CCCeddy/code-collie-plugins
```

Claude Code then says Code Collie needs you to sign in. Run `/mcp`, choose
Code Collie, and sign in or sign up in the browser. That is the whole install:
no key, and nothing to add to any repository.

If you connected Code Collie by hand before (`claude mcp add … code-collie`),
remove that first with `claude mcp remove code-collie`, and delete
`~/.claude/skills/code-collie`. Claude Code ignores a
plugin's server when you already have one at the same address.

## What it sends

The plugin tells Code Collie which session made an edit or recorded
something, so it can count how many sessions change code and how many of those
write anything down. That is the session's id and the tool's name. Never file
contents, commands or messages.

This repository is published automatically; changes made here are
overwritten.
