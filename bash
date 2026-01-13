# interactive, fills title/body from your editor:
gh pr create --base main --head chore/flatten-structure

# or non-interactive with title/body:
gh pr create --base main --head chore/flatten-structure \
  --title "chore: flatten repository structure" \
  --body "This PR flattens and normalizes repository layout: moves engine, router, outreach and core modules into apps/ and core/, moves Dockerfile to repo root, and updates CI/workflow paths. Please review and run CI."
