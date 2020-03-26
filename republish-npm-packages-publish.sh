#!/bin/bash

set -e

PACKAGE_DIR=$1

cd packages/$PACKAGE_DIR

# Mac OS specific. -v uses natural sorting (0.0.2 < 0.0.10), which is essencial to publishing order.
FILES=`gls -v *.tgz`

for FILE in $FILES
do
    echo -n "PUBLISHING $FILE..." 
    npm publish --access=public $FILE --otp
    echo "DONE"
    rm $FILE
done

echo "DONE"
