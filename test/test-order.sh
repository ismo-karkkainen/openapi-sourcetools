#!/bin/sh

O="../bin/openapi-order"

(
echo "####COMMAND Invalid output file"
echo '{"foo":"bar"}' | $O --output /in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid input file"
$O --input /in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid order file"
$O --input ../test-order/basic-hash-doc.yaml --order /in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid format"
echo '{"foo":"bar"}' | $O --format invalid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Output default order"
$O --default --output x >o 2>e
echo "####CODE $?"
echo "####OUT"
cat x | head -n 60 # Long enough to contain an alias and reference.
echo "####ERR"
cat e

echo "####COMMAND Help"
$O --help >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o | head -5
echo "####ERR"
cat e
) | grep -v -e '^Finished in' > $(basename $0 .sh).res

rm -f x o e
