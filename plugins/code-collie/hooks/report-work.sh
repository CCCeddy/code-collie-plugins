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
file=$(field file_path)
[ -n "$file" ] || file=$(field notebook_path)
[ -n "$session" ] && [ -n "$file" ] || exit 0
case "$session" in *[!A-Za-z0-9_-]*) exit 0 ;; esac

dir=$(dirname "$file")
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
remote=$(git -C "$dir" remote get-url origin 2>/dev/null |
  sed -E 's#^([a-zA-Z+]+://)[^/@]*@#\1#')
[ -n "$remote" ] || exit 0
path="$(git -C "$dir" rev-parse --show-prefix)$(basename "$file")"
branch=$(git -C "$dir" symbolic-ref --short -q HEAD)
worktree=$(printf '%s' "$root" | git hash-object --stdin) || exit 0

tmp=$TMPDIR
[ -n "$tmp" ] || tmp=/tmp
sent="$tmp/code-collie-work-$session-$worktree"
if [ "$(head -1 "$sent" 2>/dev/null)" != "branch:$branch" ] ||
  [ -n "$(find "$sent" -mmin +10 2>/dev/null)" ]; then
  printf 'branch:%s\n' "$branch" >"$sent" || exit 0
fi
grep -qxF -- "$path" "$sent" && exit 0

if [ -n "$branch" ]; then
  name="\"$(json "$branch")\""
else
  name=null
fi

curl -fsS -m 3 -o /dev/null -X POST \
  -H 'content-type: application/json' \
  -d "{\"session_id\":\"$session\",\"repository\":\"$(json "$remote")\",\"worktree\":\"$worktree\",\"branch\":$name,\"path\":\"$(json "$path")\"}" \
  'https://app.codecollie.com/api/work/report' 2>/dev/null &&
  printf '%s\n' "$path" >>"$sent"
exit 0
