#!/bin/sh

M="../bin/openapi-merge"

(
cd ../test-merge
for C in prune
do
    echo "####COMMAND $C"
    $M $C.yaml >o 2>e
    echo "####CODE $?"
    echo "####OUT"
    cat o
    echo "####ERR"
    cat e
    rm -f o e
done
) > $(basename $0 .sh).res
