#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $(basename $0) program-suffix-name"
    echo "  E.g. merge to test openapi-merge"
    exit 2
fi

RV=0
cd test
for S in ./test-${1}*.sh
do
    echo $S
    $S
    B=$(basename $S .sh)
    if [ ! -f $B.good ]; then
        echo "No $B.good to compare with."
        continue
    fi
    ../shared/compare $B.good $B.res
    if [ $? -eq 0 ]; then
        echo "Comparison ok."
    else
        RV=1
    fi
done
exit $RV
