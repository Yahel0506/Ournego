#!/usr/bin/env bash
# Validates Conventional Commits subjects read from stdin, one per line.
#
#   <type>(<optional scope>)<optional !>: <description>
#
# Used by .githooks/commit-msg (local) and .github/workflows/commit-lint.yml (CI).
set -uo pipefail

types='feat|fix|perf|refactor|docs|style|test|build|ci|chore|revert'
pattern="^(${types})(\([A-Za-z0-9._/-]+\))?!?: .+"

status=0
while IFS= read -r subject; do
  [ -z "$subject" ] && continue
  # Merge commits and git-generated reverts/fixups are not authored by hand.
  case "$subject" in
    "Merge "* | "Revert \""* | "fixup! "* | "squash! "*) continue ;;
  esac
  if ! [[ "$subject" =~ $pattern ]]; then
    echo "Invalid commit subject: $subject" >&2
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  cat >&2 <<MSG

Commit subjects must follow Conventional Commits:
  <type>(<optional scope>)<optional !>: <description>
Types: ${types//|/, }
Examples:
  feat(map): add zone search
  fix(auth): handle expired sessions
  feat(api)!: drop legacy endpoint   (breaking change -> minor bump while 0.x)
See docs/development/release-process.md
MSG
fi
exit "$status"
