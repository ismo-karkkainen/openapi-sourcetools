#!/bin/sh

M="../bin/openapi-addschemas"

(
echo "####COMMAND Unit tests"
./unittest-addschemas >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
) > $(basename $0 .sh).res

rm -f o e
