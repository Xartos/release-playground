#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

make_sure_branch_is_up_to_date() {
  if [[ "$(git rev-parse "${1}")" != "$(git rev-parse "origin/${1}")" ]]; then
    log_error "ERROR: Your branch isn't up to date with upstream, please run 'git pull' and try again"
    exit 1
  fi
}

log_info_no_newline() {
  echo -e -n "[\e[34mck8s\e[0m] ${*}" 1>&2
}

log_info() {
  log_info_no_newline "${*}\n"
}

log_warning_no_newline() {
    echo -e -n "[\e[33mck8s\e[0m] ${*}" 1>&2
}

log_warning() {
    log_warning_no_newline "${*}\n"
}

log_error_no_newline() {
    echo -e -n "[\e[31mck8s\e[0m] ${*}" 1>&2
}

log_error() {
    log_error_no_newline "${*}\n"
}

# echo "Release helper!"
log_info_no_newline "What version major version: "
read -r major_version
log_info_no_newline "What version minor version: "
read -r minor_version

if [[ ! "${major_version}" =~ ^[0-9]+$ ]]; then
  log_error "ERROR: Major version must be a number. Got: ${major_version}"
  exit 1
fi

if [[ ! "${minor_version}" =~ ^[0-9]+$ ]]; then
  log_error "ERROR: Minor version must be a number. Got: ${minor_version}"
  exit 1
fi

# Make sure we have latest info
git fetch origin

if git tag -l | grep -P "^v${major_version}.${minor_version}.0$" > /dev/null; then
  log_error "ERROR: tag v${major_version}.${minor_version}.0 already exists"
  exit 1
fi

#TODO fix to output some relevant info
current_commit_hash=$(git rev-parse HEAD)
# Gets current branch name or if detached you get the short hash of the commit
current_branch_or_hash=$(git symbolic-ref -q --short HEAD || git rev-parse --short HEAD)
if git symbolic-ref -q --short HEAD > /dev/null; then
  log_info "Your current git branch is ${current_branch_or_hash}."
  make_sure_branch_is_up_to_date "${current_branch_or_hash}"
else
  log_info "Your currently on a detached commit ${current_branch_or_hash}."
fi

log_warning_no_newline "Do you want to create the release from this (this should probably be main)? (y/n): "
read -r sure_to_release
if [[ ! "${sure_to_release}" =~ ^[yY]$ ]]; then
  exit 1
fi

log_info "Creating release branch for version ${major_version}.${minor_version}"

reuse_existing_release_branch="new-branch"
if git branch -a | grep -P "release-${major_version}-${minor_version}$" > /dev/null; then
  log_warning "Release branch release-${major_version}-${minor_version} already exists"
  log_warning "This might happened if you needed to rerun this script"
  log_info_no_newline "Do you want to reuse that one? (y/n): "
  read -r reuse_existing_release_branch
  if [[ ! "${reuse_existing_release_branch}" =~ ^[yY]$ ]]; then
    exit 1
  fi
  git switch "release-${major_version}-${minor_version}"
  make_sure_branch_is_up_to_date "release-${major_version}-${minor_version}"
else
  git switch -c "release-${major_version}-${minor_version}"
  git push -u origin "release-${major_version}-${minor_version}"
fi

git switch -c "reset-changelog-${major_version}-${minor_version}"
"${here}/reset-changelog.sh" "${major_version}.${minor_version}.0"

for file in $(git diff "${current_commit_hash}" --name-only); do
  if [[ ! "${file}" =~ ^(CHANGELOG.md|WIP-CHANGELOG.md)$ ]]; then
    log_error "ERROR: Didn't expect file ${file} to have been commited, aborting"
    exit 1
  fi
done

git push -u origin "reset-changelog-${major_version}-${minor_version}"

log_info "Get this PR merged NOW!!"

is_merged="n"
until [[ ! "${is_merged}" =~ ^[yY]$ ]]; do
  log_info_no_newline "Is it merged to both release-${major_version}-${minor_version} and main? (y/n): "
  read -r is_merged
done

#TODO Verify that the PR is merged to both
git switch main
git pull


git switch "release-${major_version}-${minor_version}"
git switch -c "QA-${major_version}-${minor_version}"
git push -u origin "QA-${major_version}-${minor_version}"

log_info "Now you're on the QA branch, finish all QA stuff and put all fixes here."
log_info "All changes should be noted in the CHANGELOG.md directly"
log_info "When it's done run the INSERT_NAME_HERE script to create the release"
