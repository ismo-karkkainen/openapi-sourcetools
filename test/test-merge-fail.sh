#!/bin/sh

M="../bin/openapi-merge --keep"

(
cd ../test-merge
for C in components info jsonSchemaDialect openapi paths webhooks
do
    echo "####COMMAND $C"
    $M all.yaml $C.yaml >o 2>e
    echo "####CODE $?"
    echo "####OUT"
    cat o
    echo "####ERR"
    cat e
    rm -f o e
done

echo "####COMMAND openapi in first and last"
$M --last openapi --last info --first openapi --first servers first.yaml all.yaml last.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
rm -f o e

echo "####COMMAND info and servers in first and last"
$M --first info --last info --first openapi --first servers --last servers first.yaml all.yaml last.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
rm -f o e

) > $(basename $0 .sh).res
