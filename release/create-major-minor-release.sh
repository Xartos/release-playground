#!/bin/bash

set -eu -o pipefail

current_branch=$(git symbolic-ref -q --short HEAD)
if [[ ! "${current_branch}" =~ ^release-[0-9]+\.[0-9]+$ ]]; then
  #TODO Log something here
  exit 1
fi

major_version=$(echo "${current_branch}" | sed 's/release-\([0-9]\+\)-[0-9]\+/\1/')
minor_version=$(echo "${current_branch}" | sed 's/release-[0-9]\+-\([0-9]\+\)/\1/')

# Compare and see if there's any diff from release branch

git tag "v${major_version}.${minor_version}.0"
git push --tags
