#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $(basename $0) program-suffix-name"
    echo "  E.g. merge to test openapi-merge"
    exit 2
fi

RV=0
cd test
if [ -d ${1} ]; then
    DIR=${1}
    PARENT='../..'
else
    DIR='.'
    PARENT='..'
fi
cd ${DIR}
for S in test-*.sh
do
    if [ ! -e "$S" ]; then
        echo "No tests found for ${1}"
        break
    fi
    echo $S
    ./$S
    B=$(basename "$S" .sh)
    if [ ! -f "$B.good" ]; then
        echo "No $B.good to compare with."
        continue
    fi
    ${PARENT}/shared/compare "$B.good" "$B.res"
    if [ $? -eq 0 ]; then
        echo "Comparison ok."
    else
        RV=1
    fi
done
exit $RV
