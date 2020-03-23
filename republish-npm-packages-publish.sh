#!/bin/bash

PACKAGE_DIR=$1

cd packages/$PACKAGE_DIR

FILES=`find . -name "*.tgz" | sort`

for FILE in $FILES
do
    echo -n "PUBLISHING $FILE..." 
    npm publish --access=public $FILE --otp 
    echo "DONE"
    rm $FILE
done

echo "DONE"