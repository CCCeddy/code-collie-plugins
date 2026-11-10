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
checked="$tmp/code-collie-changes-$session"
[ -f "$checked" ] && [ -z "$(find "$checked" -mmin +1 2>/dev/null)" ] && exit 0
(: >"$checked") 2>/dev/null || exit 0

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
remote=$(git -C "$dir" remote get-url origin 2>/dev/null |
  sed -E 's#^([a-zA-Z+]+://)[^/@]*@#\1#')
[ -n "$remote" ] || exit 0
branch=$(git -C "$dir" symbolic-ref --short -q HEAD)
worktree=$(printf '%s' "$root" | git hash-object --stdin) || exit 0

repos="$tmp/code-collie-repos-$session"
grep -qxF -- "$root" "$repos" 2>/dev/null || printf '%s\n' "$root" >>"$repos"
sent="$tmp/code-collie-work-$session-$worktree"

gitdir=$(git -C "$root" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
for state in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply; do
  [ -e "$gitdir/$state" ] && exit 0
done

dirty() {
  git --no-optional-locks -C "$root" -c core.quotePath=false \
    status --porcelain -z --no-renames --untracked-files=all 2>/dev/null |
    tr '\0' '\n' | cut -c4-
}

before="$tmp/code-collie-before-$session-$worktree"
if [ ! -f "$before" ]; then
  {
    printf 'since:%s\n' "$(date +%s)"
    dirty
  } >"$before.$$" 2>/dev/null && mv "$before.$$" "$before"
  exit 0
fi
since=$(sed -n '1s/^since://p' "$before")

committed() {
  git --no-optional-locks -C "$root" -c core.quotePath=false \
    -c log.showSignature=false \
    log -z --format= --name-only --no-merges --no-renames \
    "--since=$since" HEAD --not --remotes 2>/dev/null |
    tr '\0' '\n'
}

was=$(head -1 "$sent" 2>/dev/null)
earlier=$(sed 1d "$sent" 2>/dev/null)
if [ "$(head -1 "$sent" 2>/dev/null)" != "branch:$branch" ] ||
  [ -n "$(find "$sent" -mmin +10 2>/dev/null)" ]; then
  printf 'branch:%s\n' "$branch" >"$sent" || exit 0
fi
still=
if [ "$was" = "branch:$branch" ] && [ -n "$earlier" ] &&
  [ -z "$(sed 1d "$sent")" ]; then
  printf '%s\n' "$earlier" >>"$sent" || exit 0
  still=$(printf '%s\n' "$earlier" | tail -n 1)
fi

known="$before.known.$$"
LC_ALL=C sort -u "$before" "$sent" >"$known" || exit 0
new=$({ dirty; committed; } | LC_ALL=C grep -v -e '^$' -e '[[:cntrl:]]' |
  LC_ALL=C sort -u | LC_ALL=C comm -23 - "$known" | head -5)
rm -f "$known"

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
if [ -n "$new" ]; then
  printf '%s\n' "$new" | while IFS= read -r path; do send "$path"; done
elif [ -n "$still" ]; then
  send "$still" ',"still_working":true'
fi
exit 0
