#!/bin/bash
# Daily AI Journal Cron Job
# Runs every day at 9am to create and PR a daily AI advancement journal entry
# Repo: /home/andrewt/Downloads/github/ai-daily-journal

set -e

REPO_DIR="/home/andrewt/Downloads/github/ai-daily-journal"
cd "$REPO_DIR"

# Get today's date
TODAY=$(date '+%Y-%m-%d')
JOURNAL_FILE="journals/${TODAY}.md"
BRANCH="journal/${TODAY}"

# Check if journal for today already exists (avoid duplicates)
if git show-ref --verify --quiet "refs/heads/${BRANCH}" 2>/dev/null; then
    echo "Journal for ${TODAY} already exists (branch ${BRANCH}). Skipping."
    exit 0
fi

# Fetch latest
git fetch origin main 2>/dev/null || true

# Create branch from origin/main
git checkout -B "$BRANCH" origin/main

# The actual journal content and research is done by the skill workflow
# This script assumes the journal file, sources.md, and README.md have been updated
# by the ai-daily-journal skill
#
# To use this cron job:
# 1. Add your research to journals/${TODAY}.md
# 2. Update sources.md
# 3. Update README.md
# 4. This cron script will commit and open a PR

# If the journal file exists, commit and push
if [ -f "$JOURNAL_FILE" ]; then
    git add "$JOURNAL_FILE" sources.md README.md
    git commit -m "feat(journal): daily AI advancements summary for ${TODAY}" || echo "No changes to commit"

    # Push using gh token
    TOKEN=$(gh auth token 2>/dev/null || echo "")
    if [ -n "$TOKEN" ]; then
        git push -u "https://${TOKEN}@github.com/andrewdarmawant/ai-daily-journal.git" "$BRANCH" 2>&1
    else
        git push -u origin "$BRANCH" 2>&1
    fi

    # Create PR if it doesn't exist
    gh pr create --repo andrewdarmawant/ai-daily-journal \
        --title "AI Daily Journal — ${TODAY}" \
        --body "Daily AI advancement summary. Run by ai-daily-journal cron skill." \
        --head "$BRANCH" \
        --base main 2>&1 || echo "PR may already exist"
else
    echo "ERROR: Journal file ${JOURNAL_FILE} does not exist."
    echo "Run the ai-daily-journal skill manually or via Hermes agent first."
    exit 1
fi

echo "Daily journal PR for ${TODAY} completed."
