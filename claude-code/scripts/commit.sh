#!/bin/bash

# Custom /commit slash command for Claude Code
# Follows Conventional Commits specification v1.0.0
# https://www.conventionalcommits.org/en/v1.0.0/

set -e

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Get git status and diff
echo "=== Git Status ==="
git status --short

echo ""
echo "=== Staged Changes ==="
git diff --cached --stat

echo ""
echo "=== Unstaged Changes ==="
git diff --stat

# Check if there are any changes
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit"
    exit 0
fi

# Output instructions for Claude
cat << 'INSTRUCTIONS'

Please help create a Conventional Commit following the specification:

COMMIT FORMAT:
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]

RULES:
1. Type is REQUIRED (feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert)
2. Scope is OPTIONAL - noun describing codebase section in parentheses
3. Description is REQUIRED - short summary in imperative present tense
4. Breaking changes indicated by:
   - ! after type/scope (e.g., feat!: or feat(api)!:)
   - OR BREAKING CHANGE: in footer
5. Body is OPTIONAL - detailed explanation (blank line after description)
6. Footer is OPTIONAL - uses format: token: value or BREAKING CHANGE: description

IMPORTANT INSTRUCTIONS:
- Do NOT add any co-author information
- Do NOT add "Generated with Claude Code"
- Do NOT add robot emojis or any Claude attribution
- Keep commit messages clean and professional
- Use lowercase for type and scope
- No period at end of description
- Description should be imperative: "add" not "added" or "adds"

WORKFLOW:
1. Analyze the changes shown above
2. Stage appropriate files with git add
3. Create commit with git commit -m (for single line) or heredoc for multiline
4. For multiline commits with body/footer, use:
   git commit -m "type(scope): description" -m "" -m "body" -m "" -m "footer"
   OR use heredoc:
   git commit -F- <<'END'
   type(scope): description

   body paragraph

   footer: value
   END

Please analyze the changes and create an appropriate Conventional Commit.
INSTRUCTIONS