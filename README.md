# Code Collie for Claude Code

Code Collie holds the project context your assistant cannot get from the
repository: decisions and why they were made, constraints from outside the
code, and what is in progress. Your assistant fetches it before it edits and
records it when you tell it something new.

## Install

In a terminal, with an up-to-date Claude Code (checked on 2.1.280; if a
command is not recognised, run `claude update` first):

```
claude plugin marketplace add CCCeddy/code-collie-plugins
claude plugin install code-collie@code-collie
claude mcp login plugin:code-collie:code-collie
```

The last command opens your browser: sign in or sign up, and allow. Then start
a new Claude Code session, or run `/reload-plugins` in one that is open. That
is the whole install: no key, and nothing to add to any repository.

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
