#!/bin/sh

O="../bin/openapi-order"

(
for DOC in ../test-order/*-doc.yaml
do
    PREFIX=$(basename "$DOC" -doc.yaml)
    ORDER="../test-order/${PREFIX}-order.yaml"

    if [ ! -f "$ORDER" ]; then
        echo "####COMMAND No order file for $PREFIX"
        echo "####CODE 1"
        echo "####OUT"
        echo "####ERR"
        echo "No order file found: $ORDER"
        continue
    fi

    echo "####COMMAND Order ${PREFIX}"
    $O --input "$DOC" --order "$ORDER" >o 2>e
    CODE=$?
    echo "####CODE $CODE"
    echo "####OUT"
    cat o
    echo "####ERR"
    cat e
done
) | grep -v -e '^Finished in' > $(basename $0 .sh).res

rm -f o e
