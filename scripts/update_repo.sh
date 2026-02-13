
#!/usr/bin/env bash
set -eo pipefail

# Expected env from the fastbuild framework:
#   OPENWRT_CUR_DIR, REPO_URL, REPO_BRANCH
# See "Important directories" in README for OPENWRT_* meaning.
# https://github.com/OpenWRT-fanboy/openwrt-fastbuild  (docs)
# (This script is executed inside the builder container.)

: "${OPENWRT_CUR_DIR:?OPENWRT_CUR_DIR must be set}"
: "${REPO_URL:?REPO_URL must be set}"
: "${REPO_BRANCH:?REPO_BRANCH must be set}"

mkdir -p "${OPENWRT_CUR_DIR}"
cd "${OPENWRT_CUR_DIR}"

# Initialize a repo if needed
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init
fi

# Ensure 'origin' exists and points to REPO_URL
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "${REPO_URL}"
else
  git remote add origin "${REPO_URL}"
fi

# Fetch the requested ref/branch (shallow) and check out a local branch tracking it
# This works for normal branch names and also for tags/commits when REPO_BRANCH is a ref.
git fetch --depth=1 origin "${REPO_BRANCH}" || {
  echo "ERROR: fetch of '${REPO_BRANCH}' from '${REPO_URL}' failed." >&2
  echo "       Verify REPO_URL and REPO_BRANCH in user/<target>/settings.ini." >&2
  exit 1
}

# Create/force a local branch at FETCH_HEAD; avoids detached HEAD and handles tag/commit too
git checkout -B "${REPO_BRANCH}" FETCH_HEAD

# Optional: show the current HEAD for debugging
git --no-pager log -1 --oneline
