#!/bin/sh

(
echo "####COMMAND Unit tests"
./unittest-oftypes >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e | sed 's/ //g'
) > $(basename $0 .sh).res

rm -f o e
