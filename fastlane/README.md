fastlane documentation
================
# Installation
```
sudo gem install fastlane
```
# Available Actions
### ci_commit
```
fastlane ci_commit
```
Runs tests and builds example for the given environment

The lane to run by ci on every commit This lanes calls the lanes `test_framework` and `build_example`.

####Example:

```
fastlane ci_commit configuration:Debug --env ios91
```

####Options

 * **`configuration`**: The build configuration to use. (`AF_CONFIGURATION`)


### test_framework
```
fastlane test_framework
```
Runs all tests for the given environment

Set `scan` action environment variables to control test configuration

####Example:

```
fastlane test_framework configuration:Debug --env ios91
```

####Options

 * **`configuration`**: The build configuration to use.


### build_example
```
fastlane build_example
```
Builds the example file

Set `xcodebuild` action environment variables to control build configuration

####Example:

```
fastlane build_example configuration:Debug --env ios91
```

####Options

 * **`configuration`**: The build configuration to use.


### code_coverage
```
fastlane code_coverage
```
Produces code coverage information

Set `scan` action environment variables to control test configuration

####Example:

```
fastlane code_coverage configuration:Debug
```

####Options

 * **`configuration`**: The build configuration to use. The only supported configuration is the `Debug` configuration.


### prepare_framework_release
```
fastlane prepare_framework_release
```
Prepares the framework for release

This lane should be run from your local machine, and will push a tag to the remote when finished.

 * Verifies the git branch is clean

 * Ensures the lane is running on the master branch

 * Verifies the Github milestone is ready for release

 * Pulls the remote to verify the latest the branch is up to date

 * Updates the version of the info plist path used by the framework

 * Updates the the version of the podspec

 * Generates a changelog based on the Github milestone

 * Updates the changelog file

 * Commits the changes

 * Pushes the committed branch

 * Creates a tag

 * Pushes the tag

####Example:

```
fastlane prepare_framework_release version:3.0.0 --env deploy
```

####Options

It is recommended to manage these options through a .env file. See `fastlane/.env.deploy` for an example.

 * **`version`** (required): The new version of the framework

 * **`allow_dirty_branch`**: Allows the git branch to be dirty before continuing. Defaults to false

 * **`remote`**: The name of the git remote. Defaults to `origin`. (`DEPLOY_REMOTE`)

 * **`allow_branch`**: The name of the branch to build from. Defaults to `master`. (`DEPLOY_BRANCH`)

 * **`skip_validate_github_milestone`**: Skips validating a Github milestone. Defaults to false

 * **`skip_git_pull`**: Skips pulling the git remote. Defaults to false

 * **`skip_plist_update`**: Skips updating the version of the info plist. Defaults to false

 * **`plist_path`**: The path of the plist file to update. (`DEPLOY_PLIST_PATH`)

 * **`skip_podspec_update`**: Skips updating the version of the podspec. Defaults to false

 * **`podspec`**: The path of the podspec file to update. (`DEPLOY_PODSPEC`)

 * **`skip_changelog`**: Skip generating a changelog. Defaults to false.

 * **`changelog_path`**: The path to the changelog file. (`DEPLOY_CHANGELOG_PATH`)

 * **`changelog_insert_delimiter`**: The delimiter to insert the changelog after. (`DEPLOY_CHANGELOG_DELIMITER`)


### complete_framework_release
```
fastlane complete_framework_release
```
Completes the framework release

This lane should be from a CI machine, after the tests have passed on the tag build. This lane does the following:

 * Verifies the git branch is clean

 * Ensures the lane is running on the master branch

 * Pulls the remote to verify the latest the branch is up to date

 * Generates a changelog for the Github Release

 * Creates a Github Release

 * Builds Carthage Frameworks

 * Uploads Carthage Framework to Github Release

 * Pushes podspec to pod trunk

 * Lints the pod spec to ensure it is valid

 * Closes the associated Github milestone

####Example:

```
fastlane complete_framework_release --env deploy
```

####Options

It is recommended to manage these options through a .env file. See `fastlane/.env.deploy` for an example.

 * **`version`** (required): The new version of the framework. Defaults to the last tag in the repo

 * **`allow_dirty_branch`**: Allows the git branch to be dirty before continuing. Defaults to false

 * **`remote`**: The name of the git remote. Defaults to `origin`. (`DEPLOY_REMOTE`)

 * **`allow_branch`**: The name of the branch to build from. Defaults to `master`. (`DEPLOY_BRANCH`)

 * **`skip_github_release`**: Skips creating a Github release. Defaults to false

 * **`skip_carthage_framework`**: Skips creating a carthage framework. If building a swift framework, this should be disabled. Defaults to false.

 * **`skip_pod_push`**: Skips pushing the podspec to trunk.

 * **`skip_podspec_update`**: Skips updating the version of the podspec. Defaults to false

 * **`skip_closing_github_milestone`**: Skips closing the associated Github milestone. Defaults to false



----

This README.md is auto-generated and will be re-generated every time to run [fastlane](https://fastlane.tools).  
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).  
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane).
