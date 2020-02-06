#!/bin/bash

CURRENT_PACKAGE=$1
NEW_PACKAGE_NAME=$2

function show_usage() {
    cat << EOT
$0

Usage: $0 current_package_name new_package_name [--publish]

This script runs in dry-run mode by default. To publish packages to npm, use --publish flag

It downloads all published npm versions from current_package_name, unpacks and renames them, and prepare for publishing. If --publish is used, it also attempts to publish to npm. Make sure to have logged in to NPM on your current shell.

When publishing, for 2-FA users, it will prompt for the OTP (one-time password), that should be inserted manually as usual.

Examples:
$0 ethereumjs-account @ethereumjs/account

$0 ethereumjs-account @ethereumjs/account --publish
EOT
    exit 1
}

# Check for required variables/commands
if ! [[ -n "$CURRENT_PACKAGE" ]]; then show_usage; fi;
if ! [[ -n "$NEW_PACKAGE_NAME" ]]; then show_usage; fi;

if ! command -v foo 2>/dev/null; then
    echo ""
    echo -e "\033[0;31mJQ is required for package.json manipulation.\033[0m"
    echo "Download it at https://stedolan.github.io/jq/ and make sure to have jq available in your path."
    echo "done."
    exit 1
fi

exit 0

mkdir -p packages/$CURRENT_PACKAGE
CWD=`pwd`/$CURRENT_PACKAGE
cd $CWD

# Fetching and downloading all versions for specified package
VERSIONS=`npm view $CURRENT_PACKAGE versions | grep -E -o "\d+\.\d+\.\d+"`
echo "Versions returned for $CURRENT_PACKAGE: $VERSIONS "


for VERSION in $VERSIONS
do
    cd $CWD

    # Downloads the tarball with the specified version
    npm pack $CURRENT_PACKAGE@$VERSION

    # Create a directory for each version, to receive the unpacked package
    mkdir $VERSION

    # Unpacks files to the corresponding directory.
    #   strip-components=1 removes the /package directory from the tarball
    #   -C defines the destination path
    tar -xvzf $CURRENT_PACKAGE-$VERSION.tgz --strip-components=1 -C $VERSION

    cd $VERSION

    # Changing package name
    cat package.json | jq --arg NAME "$NEW_PACKAGE_NAME" '.name = $NAME' > package.json

    # Displaying new name saved on package.json
    cat package.json | jq '{.name}'

    rm ../$CURRENT_PACKAGE-$VERSION.tgz
    cd $CWD
done


for $VERSION in $VERSIONS
do
    cd $CWD/$VERSION

    # We need to skip the execution of npm publish scripts.
    # So we'll pack them to tgz first, then upload.
    npm pack
    npm publish --access=public


done
