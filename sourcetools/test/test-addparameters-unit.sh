#!/bin/sh

(
echo "####COMMAND Unit tests"
./unittest-addparameters >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
) > $(basename $0 .sh).res

rm -f o e