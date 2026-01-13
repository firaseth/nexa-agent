#!/usr/bin/env bash
# Restructure and flatten repository layout for nexa-agent
# Usage: ./restructure.sh [--push] [--test]
#  --push : push branch to origin after committing
#  --test : run tests (installs in a venv if needed)
set -euo pipefail

BRANCH="chore/flatten-structure"
PUSH=false
RUN_TESTS=false

for arg in "$@"; do
  case "$arg" in
    --push) PUSH=true ;;
    --test) RUN_TESTS=true ;;
    *) echo "Unknown arg: $arg" ;;
  esac
done

# Ensure we are in the repository root (best-effort)
if [ ! -f "README.md" ] && [ ! -d ".git" ]; then
  echo "Warning: README.md or .git not found in current directory. Continue? (y/N)"
  read -r confirm
  if [ "$confirm" != "y" ]; then
    echo "Aborting."
    exit 1
  fi
fi

# Use git if available and inside a repo
USE_GIT=false
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  USE_GIT=true
  echo "Using git for moves and commits."
  git checkout -b "$BRANCH"
else
  echo "Not inside a git repo. Moves will be plain filesystem moves and no commit will be created."
fi

# Helper to create directory and move a file (git mv if possible)
_move_file() {
  src="$1"
  dst="$2"
  dst_dir=$(dirname "$dst")
  mkdir -p "$dst_dir"
  if [ "$USE_GIT" = true ]; then
    # If destination file already exists, remove it first to allow git mv
    if [ -e "$dst" ]; then
      echo "Destination $dst already exists, skipping move of $src"
      return
    fi
    git mv -f "$src" "$dst"
  else
    mv -f "$src" "$dst"
  fi
  echo "Moved: $src -> $dst"
}

# Find and move routine:
# For each target we look for the first matching source in nested paths (safe fallback)
find_and_move() {
  pattern="$1"      # find -path pattern (e.g. "*nexa_script*")
  name="$2"         # filename to find (e.g. engine.py)
  target="$3"       # destination path relative to repo root
  echo "Searching for $name under pattern $pattern ..."
  # Use find to locate candidates, exclude .git and .venv
  mapfile -t candidates < <(find . -type f -path "./.git" -prune -o -path "./.venv" -prune -o -path "./.venv/*" -prune -o -name "$name" -print 2>/dev/null | grep -E "$pattern" || true)
  if [ "${#candidates[@]}" -eq 0 ]; then
    echo "No file named $name found matching pattern $pattern — skipping."
    return
  fi
  # If target already exists, skip to avoid clobbering
  if [ -e "$target" ]; then
    echo "Target $target already exists — skipping move for $name."
    return
  fi
  # Choose the best candidate (first). If there are multiple, print a warning.
  if [ "${#candidates[@]}" -gt 1 ]; then
    echo "Multiple candidates found for $name. Using the first:"
    printf '  %s\n' "${candidates[@]}"
  fi
  src="${candidates[0]}"
  # Normalize src by removing leading ./ if present
  src="${src#./}"
  _move_file "$src" "$target"
}

echo "Creating canonical directories..."
mkdir -p apps/nexa_script apps/nexa_vision apps/nexa_press core docs .github/workflows tests

# Move known files (safe, pattern-based)
find_and_move "nexa_script" "engine.py" "apps/nexa_script/engine.py"
find_and_move "nexa_script" "__init__.py" "apps/nexa_script/__init__.py"

find_and_move "nexa_vision" "router.py" "apps/nexa_vision/router.py"
find_and_move "nexa_vision" "__init__.py" "apps/nexa_vision/__init__.py"

find_and_move "nexa_press" "outreach.py" "apps/nexa_press/outreach.py"
find_and_move "nexa_press" "__init__.py" "apps/nexa_press/__init__.py"

find_and_move "core" "agent_graph.py" "core/agent_graph.py"
find_and_move "core" "guardrails.py" "core/guardrails.py"

# Docs
find_and_move "docs" "BRAND_GUIDE.md" "docs/BRAND_GUIDE.md"
find_and_move "docs" "STRATEGY.md" "docs/STRATEGY.md"

# Move Dockerfile from app/ to repo root if present
if [ -f "Dockerfile" ]; then
  echo "Dockerfile already at repo root; skipping."
else
  docker_src=$(find . -type f -name Dockerfile -path "./app/*" -print -quit 2>/dev/null || true)
  if [ -n "$docker_src" ]; then
    docker_src="${docker_src#./}"
    _move_file "$docker_src" "Dockerfile"
  fi
fi

# Move github workflow if nested
workflow_src=$(find . -type f -name "test.yml" -path "*/.github/workflows/*" -print -quit 2>/dev/null || true)
if [ -n "$workflow_src" ]; then
  workflow_src="${workflow_src#./}"
  _move_file "$workflow_src" ".github/workflows/test.yml"
else
  # Maybe workflow was created under app/.github...
  workflow_src2=$(find . -type f -name "test.yml" -path "*/app/.github/workflows/*" -print -quit 2>/dev/null || true)
  if [ -n "$workflow_src2" ]; then
    workflow_src2="${workflow_src2#./}"
    _move_file "$workflow_src2" ".github/workflows/test.yml"
  fi
fi

# Ensure app/main.py exists at app/main.py (keep as-is if already correct)
if [ -f "app/main.py" ]; then
  echo "app/main.py found."
else
  # Try to find any main.py and move to app/main.py if appropriate
  main_src=$(find . -type f -name "main.py" -path "*/app/*" -print -quit 2>/dev/null || true)
  if [ -n "$main_src" ]; then
    main_src="${main_src#./}"
    _move_file "$main_src" "app/main.py"
  fi
fi

echo "Cleaning up empty directories..."
# Remove empty directories except .git
find . -type d -empty -not -path "./.git" -not -path "./.git/*" -print -exec rmdir {} \; || true

if [ "$USE_GIT" = true ]; then
  echo "Staging changes..."
  git add -A
  # If nothing to commit, skip
  if git diff --cached --quiet; then
    echo "No changes to commit."
  else
    git commit -m "chore: flatten repository structure"
    echo "Committed changes on branch $BRANCH"
    if [ "$PUSH" = true ]; then
      echo "Pushing branch $BRANCH to origin..."
      git push -u origin "$BRANCH"
    else
      echo "Run 'git push -u origin $BRANCH' to push the branch."
    fi
  fi
else
  echo "No git repo; filesystem moves completed. Inspect changes manually."
fi

# Optionally run tests inside a venv (best-effort)
if [ "$RUN_TESTS" = true ]; then
  echo "Running tests in a temporary virtualenv..."
  python_cmd="$(which python3 || which python || true)"
  if [ -z "$python_cmd" ]; then
    echo "Python not found in PATH. Skipping tests."
    exit 0
  fi
  VENV_DIR=".venv_nexa_tmp"
  "$python_cmd" -m venv "$VENV_DIR"
  # shellcheck disable=SC1090
  source "$VENV_DIR/bin/activate"
  pip install --upgrade pip
  if [ -f requirements.txt ]; then
    pip install -r requirements.txt
  fi
  pytest -q || {
    echo "Some tests failed. Deactivate venv and inspect failures."
    deactivate || true
    exit 1
  }
  deactivate || true
  echo "Tests passed."
fi

echo "Restructure complete."
