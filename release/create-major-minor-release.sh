#!/bin/bash

set -eu -o pipefail

current_branch=$(git symbolic-ref -q --short HEAD)
commit_lookback=10
if [[ ! "${current_branch}" =~ ^release-[0-9]+-[0-9]+$ ]]; then
  #TODO Log something here
  exit 1
fi

major_version=$(echo "${current_branch}" | sed 's/release-\([0-9]\+\)-[0-9]\+/\1/')
minor_version=$(echo "${current_branch}" | sed 's/release-[0-9]\+-\([0-9]\+\)/\1/')

# Compare and see if there's any diff from release branch

git tag "v${major_version}.${minor_version}.0"
git push --tags

if ! git log -1 --format=%s | grep -P "^Reset changelog for release v${major_version}.${minor_version}.0$" > /dev/null; then
  echo "Changes in QA"
  # Merge to main

  release_head_commit=$(git rev-parse --short HEAD)
  reset_commit=$(git log "-${commit_lookback}" --oneline | grep -P "Reset changelog for release v0.1.0$" | awk '{print $1}')

  git switch main
  git pull

  git switch -c "patches-from-release-${major_version}-${minor_version}"

  for commit in $(git log "${reset_commit}..${release_head_commit}" --format=%h); do
    git cherry-pick "${commit}"
  done
else
  echo "No changes in QA"
fi
