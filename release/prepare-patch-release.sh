#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# shellcheck source=release/common.sh
source "${here}/common.sh"

if [ $# -lt 1 ]; then
  log_error "Usage: $0 vX.Y.0"
  exit 1
fi

current_branch=$(git symbolic-ref -q --short HEAD)
if [[ ! "${current_branch}" =~ ^release-[0-9]+\.[0-9]+$ ]]; then
  log_error "Error: Expected to be on release branch, e.g. release-1.2. Got: ${current_branch}"
  exit 1
fi

# shellcheck disable=SC2001
expected_major_version=$(echo "${current_branch}" | sed 's/release-\([0-9]\+\)\.[0-9]\+/\1/')
# shellcheck disable=SC2001
expected_minor_version=$(echo "${current_branch}" | sed 's/release-[0-9]\+\.\([0-9]\+\)/\1/')

# Make sure branch is up to date with upstream (might happen if someone missed to run pull after merging QA branch)
git fetch origin
make_sure_branch_is_up_to_date "release-${expected_major_version}.${expected_minor_version}"

# log_info_no_newline "What patch version do you want to release?: v${major_version}.${minor_version}."
full_version="${1}"
if [[ ! "${full_version}" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
  log_error "ERROR: Version must be in the form vX.Y.0 (where X is major and Y is minor version). Got: ${full_version}"
  exit 1
fi
# shellcheck disable=SC2001
major_version=$(echo "${full_version}" | sed 's/v\([0-9]\+\)\.[0-9]\+\.[0-9]\+/\1/')
# shellcheck disable=SC2001
minor_version=$(echo "${full_version}" | sed 's/v[0-9]\+\.\([0-9]\+\)\.[0-9]\+/\1/')
# shellcheck disable=SC2001
patch_version=$(echo "${full_version}" | sed 's/v[0-9]\+\.[0-9]\+\.\([0-9]\+\)/\1/')
if [ "${expected_major_version}" -ne "${major_version}" ] || [ "${expected_minor_version}" -ne "${minor_version}" ]; then
  log_error "Error: Version mismatch: Expected v${expected_major_version}.${expected_minor_version}.${patch_version} Got: v${major_version}.${minor_version}.${patch_version}"
  exit 1
fi

git switch -c "patch-${major_version}.${minor_version}.${patch_version}"
git push -u origin "patch-${major_version}.${minor_version}.${patch_version}"


log_info "Now you're on the patch branch."
log_info "Add all commits you want to include in this patch by running 'git cherry-pick <commit>' or manually update the files"
log_info "Then run './reset-changelog.sh v${major_version}.${minor_version}.${patch_version}' and merge this branch into the release branch (release-${major_version}.${minor_version})"
log_info "When that's done, switch to that branch and run create-patch-release.sh"
