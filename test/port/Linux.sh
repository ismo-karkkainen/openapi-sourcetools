#!/bin/sh

F="/etc/os-release"

if [ ! -f $F ]; then
    echo "No $F"
    exit 1
fi

D=$(grep '^ID=' $F | sed 's/"/ /g' | sed 's/=/ /g' | sed 's/  / /g' | cut -d ' ' -f 2).sh

cd $1
if [ ! -x test/port/$D ]; then
    echo "Not supported:"
    cat /etc/os-release
    exit 1
fi
echo $D
test/port/$D
