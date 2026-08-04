#!/usr/bin/env bash
set -euo pipefail

read_project_name() {
  while true; do
    read -r -p "Project name (one word, example: CraftLore): " name
    if [[ "$name" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
      printf '%s\n' "$name"
      return
    fi

    echo "Use exactly one word with only letters and numbers."
  done
}

read_git_remote() {
  while true; do
    read -r -p "Git remote URL (example: https://github.com/yourname/MyPlugin.git): " remote
    remote="${remote#"${remote%%[![:space:]]*}"}"
    remote="${remote%"${remote##*[![:space:]]}"}"

    if [[ -n "$remote" ]]; then
      printf '%s\n' "$remote"
      return
    fi

    echo "Git remote URL is required."
  done
}

lower_camel_case() {
  local value="$1"
  local first="${value:0:1}"
  local rest="${value:1}"
  printf '%s%s\n' "${first,,}" "$rest"
}

replace_in_file() {
  local path="$1"
  python - "$path" "$PROJECT_NAME" "$PACKAGE_NAME" "$COMMAND_NAME" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
project_name = sys.argv[2]
package_name = sys.argv[3]
command_name = sys.argv[4]

content = path.read_text(encoding="utf-8")
updated = content.replace("AntiGoldFarm", project_name)
updated = updated.replace("antiGoldFarm", package_name)
updated = updated.replace("antigoldfarm", command_name)

if updated != content:
    path.write_text(updated, encoding="utf-8", newline="")
PY
}

run_git_soft() {
  local command="$1"
  shift

  echo "> git $command${*:+ $*}"
  if git "$command" "$@"; then
    return 0
  fi

  return 1
}

rename_matching_files() {
  find "$SCRIPT_ROOT" \
    \( -path "$SCRIPT_ROOT/.git" -o -path "$SCRIPT_ROOT/build" -o -path "$SCRIPT_ROOT/.gradle" -o -path "$SCRIPT_ROOT/.idea" \) -prune -o \
    -type f -print0 |
    while IFS= read -r -d '' file; do
      local dir base new_base
      dir="$(dirname "$file")"
      base="$(basename "$file")"
      new_base="${base//AntiGoldFarm/$PROJECT_NAME}"
      new_base="${new_base//antiGoldFarm/$PACKAGE_NAME}"

      if [[ "$new_base" != "$base" ]]; then
        mv "$file" "$dir/$new_base"
      fi
    done
}

rename_matching_directories() {
  mapfile -d '' dirs < <(
    find "$SCRIPT_ROOT" \
      \( -path "$SCRIPT_ROOT/.git" -o -path "$SCRIPT_ROOT/build" -o -path "$SCRIPT_ROOT/.gradle" -o -path "$SCRIPT_ROOT/.idea" \) -prune -o \
      -depth -type d -print0
  )

  for dir in "${dirs[@]}"; do
    local parent base new_base
    parent="$(dirname "$dir")"
    base="$(basename "$dir")"
    new_base="${base//AntiGoldFarm/$PROJECT_NAME}"
    new_base="${new_base//antiGoldFarm/$PACKAGE_NAME}"

    if [[ "$new_base" != "$base" ]]; then
      mv "$dir" "$parent/$new_base"
    fi
  done
}

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_ROOT"

PROJECT_NAME="$(read_project_name)"
PACKAGE_NAME="$(lower_camel_case "$PROJECT_NAME")"
COMMAND_NAME="${PROJECT_NAME,,}"
GIT_REMOTE="$(read_git_remote)"

rm -f README.md
if [[ -f replacement-README.md ]]; then
  mv replacement-README.md README.md
fi

rm -rf .git

while IFS= read -r -d '' file; do
  replace_in_file "$file"
done < <(
  find "$SCRIPT_ROOT" \
    \( -path "$SCRIPT_ROOT/.git" -o -path "$SCRIPT_ROOT/build" -o -path "$SCRIPT_ROOT/.gradle" -o -path "$SCRIPT_ROOT/.idea" \) -prune -o \
    -type f -print0
)

rename_matching_files
rename_matching_directories

current_name="$(basename "$SCRIPT_ROOT")"
if [[ "$current_name" == "AntiGoldFarm" ]]; then
  parent_dir="$(dirname "$SCRIPT_ROOT")"
  renamed_root="$parent_dir/$PROJECT_NAME"
  cd "$parent_dir"
  mv "$SCRIPT_ROOT" "$renamed_root"
  cd "$renamed_root"
  SCRIPT_ROOT="$renamed_root"
fi

git_steps=(
  "init"
  "remote add origin $GIT_REMOTE"
  "add ."
  "commit -m Initial commit"
  "branch -M main"
  "push -u origin main"
)

if ! run_git_soft init ||
   ! run_git_soft remote add origin "$GIT_REMOTE" ||
   ! run_git_soft add . ||
   ! run_git_soft commit -m "Initial commit" ||
   ! run_git_soft branch -M main ||
   ! run_git_soft push -u origin main; then
  echo
  echo "Git setup was not completed automatically."
  echo "Run these commands manually:"
  printf 'git %s\n' "${git_steps[@]}"
fi

rm -f "$SCRIPT_ROOT/setup-template.ps1" "$SCRIPT_ROOT/setup-template.sh"
