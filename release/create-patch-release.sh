#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

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

expected_major_version=$(echo "${current_branch}" | sed 's/release-\([0-9]\+\)\.[0-9]\+/\1/')
expected_minor_version=$(echo "${current_branch}" | sed 's/release-[0-9]\+\.\([0-9]\+\)/\1/')

# Make sure branch is up to date with upstream (might happen if someone missed to run pull after merging QA branch)
git fetch origin
make_sure_branch_is_up_to_date "release-${expected_major_version}.${expected_minor_version}"

full_version="${1}"
if [[ ! "${full_version}" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
  log_error "ERROR: Version must be in the form vX.Y.0 (where X is major and Y is minor version). Got: ${full_version}"
  exit 1
fi
major_version=$(echo "${full_version}" | sed 's/v\([0-9]\+\)\.[0-9]\+\.[0-9]\+/\1/')
minor_version=$(echo "${full_version}" | sed 's/v[0-9]\+\.\([0-9]\+\)\.[0-9]\+/\1/')
patch_version=$(echo "${full_version}" | sed 's/v[0-9]\+\.[0-9]\+\.\([0-9]\+\)/\1/')
if [ ${expected_major_version} -ne ${major_version} ] || [ ${expected_minor_version} -ne ${minor_version} ]; then
  log_error "Error: Version mismatch: Expected v${expected_major_version}.${expected_minor_version}.${patch_version} Got: v${major_version}.${minor_version}.${patch_version}"
  exit 1
fi

current_tags=$(git tag --points-at HEAD)
if [[ "${current_tags}" != "" ]]; then
  log_error "Error: commit already has tags: ${current_tags}"
  log_error "Maybe you forgott to cherry-pick fixes to this branch before running this"
  exit 1
fi

tag="v${major_version}.${minor_version}.${patch_version}"
log_warning_no_newline "You're about to create the release ${tag} are you sure? (y/n): "
read -r sure_to_release
if [[ ! "${sure_to_release}" =~ ^[yY]$ ]]; then
  exit 1
fi

git tag "${tag}"
git push --tags
