#!/bin/sh

M="../bin/openapi-generatecode"

(
cd ../test-generatecode

echo "####COMMAND Invalid input file"
$M --input ./in/valid --tasks simple.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid tasks file"
$M --input processed.yaml --tasks ./in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid output directory"
$M --input processed.yaml --tasks simple.yaml --outdir ./in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

rm -f x o e
) > $(basename $0 .sh).res
