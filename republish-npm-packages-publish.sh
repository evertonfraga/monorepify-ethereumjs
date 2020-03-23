#!/bin/bash

PACKAGE_DIR=$1

cd packages/$PACKAGE_DIR

FILES=find . -iname "*.tgz" | sort

for FILE in $FILES
do
    echo -n "PUBLISHING $FILE..." 
    npm publish --access=public $FILE --dry-run
    echo "DONE"
done

echo "DONE"