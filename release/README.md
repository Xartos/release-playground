# Release process

The releases will follow semantic versioning and be handled with git tags.
https://semver.org/

## Major and minor releases

1. To release a major or minor version, switch to the branch you want to create the release from (probably main) and run:

    ```bash
    git switch main
    release/feature-freeze-for-major-minor-release.sh
    ```

1. Now you should be on the QA branch, so now is the time to do QA and add all fixes on this branch.

    **NOTE**: All changes made in QA should be added to `CHANGELOG.md` and **NOT** `WIP-CHANGELOG.md`.

1. When you're done with QA, create a PR to the release branch and merge it.

1. When the PR is merged switch to that branch and run:

    ```bash
    release/create-major-minor-release.sh
    ```

    *When the script is done a [GitHub actions workflow pipeline](/.github/workflows/release.yml) should've created a GitHub release from that tag.*

1. If there were any changes in the QA branch the script should've prompted you with some cherry-pick commands that you should run.
    When you've run those commands you should create a PR from this branch to main so all QA fixes is merged back to main.

## Patch releases

1. Check out the release branch you want to create a release for:

    ```bash
    git switch release-X.Y
    ```

1. Run the prepare patch command:

    ```bash
    release/prepare-patch-release.sh
    ```

1. You should now be on the patch branch.
    Cherry-pick or manually add all fixes that you want to include in the patch.

1. Run reset-changelog:

    ```bash
    release/reset-changelog.sh vX.Y.Z
    ```

1. Create a PR into the release branch and merge it.

1. When the PR is merged, run:

    ```bash
    release/create-patch-release.sh
    ```

    *When the script is done a [GitHub actions workflow pipeline](/.github/workflows/release.yml) should've created a GitHub release from that tag.*
