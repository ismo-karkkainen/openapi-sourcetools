#!/bin/sh

M="../bin/openapi-frequencies"

(
cd ../test-frequencies

echo "####COMMAND Invalid input file"
$M --input /in/valid --paths paths.txt >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid path log file"
$M --input processed.yaml --paths /in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid output file"
$M --input processed.yaml --paths paths.txt --output /in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Unprocessed input file"
$M --input unprocessed.yaml --paths paths.txt >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Output"
$M --input processed.yaml --paths paths.txt >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

rm -f x o e
) > $(basename $0 .sh).res
