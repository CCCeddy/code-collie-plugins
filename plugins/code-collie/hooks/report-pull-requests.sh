#!/bin/sh
input=$(cat)

field() {
  printf '%s' "$input" | grep -o "\"$1\": *\"[^\"]*\"" | head -1 |
    sed 's/^"[^"]*": *"//; s/"$//; s/\\\\/\\/g'
}
json() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

session=$(field session_id)
dir=$(field cwd)
[ -n "$session" ] && [ -n "$dir" ] || exit 0
case "$session" in *[!A-Za-z0-9_-]*) exit 0 ;; esac

tmp=$TMPDIR
[ -n "$tmp" ] || tmp=/tmp
checked="$tmp/code-collie-prs-$session"
[ -f "$checked" ] && [ -z "$(find "$checked" -mmin +5 2>/dev/null)" ] && exit 0
(: >"$checked") 2>/dev/null || exit 0

command -v gh >/dev/null 2>&1 || exit 0

check() {
  remote=$(git -C "$1" remote get-url origin 2>/dev/null |
    sed -E 's#^([a-zA-Z+]+://)[^/@]*@#\1#')
  name=$(printf '%s' "$remote" |
    sed -nE 's#^([a-z+]+://)?(git@)?github\.com[:/]+([^/]+/[^/]+)/*$#\3#p' |
    sed 's/\.git$//')
  [ -n "$name" ] || return 0

  prs=$(GH_FORCE_TTY= CLICOLOR_FORCE=0 gh pr list -R "github.com/$name" \
    --author @me --state all --limit 20 \
    --json number,title,headRefName,state,isDraft,isCrossRepository,mergedAt,closedAt \
    --jq 'map(select(.isCrossRepository | not) | {number, title, branch: .headRefName, state, draft: .isDraft, at: (.mergedAt // .closedAt)})' \
    2>/dev/null) || return 0
  [ -n "$prs" ] && [ "$prs" != "[]" ] || return 0

  curl -fsS -m 3 -o /dev/null -X POST \
    -H 'content-type: application/json' \
    -d "{\"session_id\":\"$session\",\"repository\":\"$(json "$remote")\",\"pull_requests\":$prs}" \
    'https://app.codecollie.com/api/work/pull-requests' 2>/dev/null
}

{
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null
  cat "$tmp/code-collie-repos-$session" 2>/dev/null
} | sort -u | head -5 | while IFS= read -r repo; do check "$repo"; done
exit 0
