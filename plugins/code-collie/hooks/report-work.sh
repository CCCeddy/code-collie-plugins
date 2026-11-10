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
tmp=$TMPDIR
[ -n "$tmp" ] || tmp=/tmp
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
remote=$(git -C "$dir" remote get-url origin 2>/dev/null |
  sed -E 's#^([a-zA-Z+]+://)[^/@]*@#\1#')
[ -n "$remote" ] || exit 0
branch=$(git -C "$dir" symbolic-ref --short -q HEAD)
worktree=$(printf '%s' "$root" | git hash-object --stdin) || exit 0

repos="$tmp/code-collie-repos-$session"
grep -qxF -- "$root" "$repos" 2>/dev/null || printf '%s\n' "$root" >>"$repos"
sent="$tmp/code-collie-work-$session-$worktree"
path="$(git -C "$dir" rev-parse --show-prefix)$(basename "$file")"
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

send() {
  curl -fsS -m 3 -o /dev/null -X POST \
    -H 'content-type: application/json' \
    -d "{\"session_id\":\"$session\",\"repository\":\"$(json "$remote")\",\"worktree\":\"$worktree\",\"branch\":$name,\"path\":\"$(json "$1")\"$2}" \
    'https://app.codecollie.com/api/work/report' 2>/dev/null &&
    { [ -n "$2" ] || printf '%s\n' "$1" >>"$sent"; }
}
send "$path"
exit 0
