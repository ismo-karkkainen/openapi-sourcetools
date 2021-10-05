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

echo "####COMMAND Files via env"
OUT=x IN=processed.yaml PATHS=paths.txt $M >o 2>e
echo "####CODE $?"
echo "####OUT"
cat x o
echo "####ERR"
cat e

echo "####COMMAND YAML"
$M --input processed.yaml --paths paths.txt >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND JSON"
$M --input processed.yaml --paths paths.txt --json >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND JSON via env"
FORMAT=JSON $M --input processed.yaml --paths paths.txt >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid format"
FORMAT=INVALID $M --input processed.yaml --paths paths.txt >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

rm -f x o e
) > $(basename $0 .sh).res
