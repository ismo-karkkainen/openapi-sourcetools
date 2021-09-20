#!/bin/sh

M="../../bin/openapi-merge"

(
cd merge
for C in components paths webhooks
do
    echo "####COMMAND $C"
    $M all.yaml $C-ok.yaml >o 2>e
    echo "####CODE $?"
    echo "####OUT"
    cat o
    echo "####ERR"
    cat e
    rm -f o e
done
) > $(basename $0 .sh).res
