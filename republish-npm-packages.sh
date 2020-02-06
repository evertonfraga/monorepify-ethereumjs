#!/bin/bash

CURRENT_PACKAGE=$1
NEW_PACKAGE_NAME=$2

function show_usage() {
    echo "Usage: $0 current_package_name new_package_name"
    exit
}

if ! [[ -n "$CURRENT_PACKAGE" ]]; then show_usage; fi;
if ! [[ -n "$NEW_PACKAGE_NAME" ]]; then show_usage; fi;

mkdir -p packages/$CURRENT_PACKAGE
CWD=`pwd`/$CURRENT_PACKAGE
cd $CWD

# Grabbing all published versions
VERSIONS=`npm view $CURRENT_PACKAGE versions | grep -E -o "(\d+\.\d+\.\d+)"`
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
    cat package.json | jq --arg NAME "$NEW_PACKAGE_NAME-1" '.name = $NAME' > package.json

    # Displaying new name saved on package.json
    cat package.json | jq '{.name}'

    # We need to skip the execution of npm publish scripts.
    # So we'll pack them to tgz first, then upload.
    npm pack
    npm publish --access=public

    rm ../$CURRENT_PACKAGE-$VERSION.tgz
    cd $CWD
done
