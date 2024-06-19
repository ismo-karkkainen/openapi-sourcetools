#!/bin/sh

M="../bin/openapi-processpaths"

(
cd ../test-processpaths

echo "####COMMAND Invalid output file"
$M --input small.yaml --output /in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid input file"
$M --input /in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Output file"
$M --input small.yaml --output x >o 2>e
echo "####CODE $?"
echo "####OUT"
cat x o
echo "####ERR"
cat e

echo "####COMMAND Simple output"
$M --input small.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Conflicting paths"
$M --input error.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Conflicting paths, only warning"
$M --warn --input error.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

rm -f x o e
) > $(basename $0 .sh).res
