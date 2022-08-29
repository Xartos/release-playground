#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

source "${here}/common.sh"

current_branch=$(git symbolic-ref -q --short HEAD)
if [[ ! "${current_branch}" =~ ^release-[0-9]+\.[0-9]+$ ]]; then
  log_error "Error: Expected to be on release branch, e.g. release-1.2. Got: ${current_branch}"
  exit 1
fi

major_version=$(echo "${current_branch}" | sed 's/release-\([0-9]\+\)\.[0-9]\+/\1/')
minor_version=$(echo "${current_branch}" | sed 's/release-[0-9]\+\.\([0-9]\+\)/\1/')

# Make sure branch is up to date with upstream (might happen if someone missed to run pull after merging QA branch)
git fetch origin
make_sure_branch_is_up_to_date "release-${major_version}.${minor_version}"

log_info_no_newline "What patch version do you want to release?: v${major_version}.${minor_version}."
read -r patch_version
if [[ ! "${patch_version}" =~ ^[0-9]+$ ]]; then
  log_error "ERROR: Version must be a number. Got: ${patch_version}"
  exit 1
fi

git switch -c "patch-${major_version}.${minor_version}.${patch_version}"
git push -u origin "patch-${major_version}.${minor_version}.${patch_version}"


log_info "Now you're on the patch branch."
log_info "Add all commits you want to include in this patch by running 'git cherry-pick <commit>' or manually update the files"
log_info "Then run './reset-changelog.sh ${major_version}.${minor_version}.${patch_version}' and merge this branch into the release branch (release-${major_version}.${minor_version})"
log_info "When that's done, run create-patch-release.sh"
