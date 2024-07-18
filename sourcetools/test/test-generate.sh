#!/bin/sh

M="../bin/openapi-generate"

(
cd ../test-generate
mkdir out

echo "####COMMAND Invalid input file"
$M -o out --input ./in/valid nop.rb >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Syntax error in processor"
$M -o out --input processed.yaml syntaxerror.rb >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o | sed "s#$(dirname $PWD)/##g"
echo "####ERR"
cat e | sed "s#$(dirname $PWD)/##g"

echo "####COMMAND Run error in processor"
$M -o out --input processed.yaml error.rb >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e | head -n 2

echo "####COMMAND Unsupported processor"
$M -o out --input processed.yaml sidfgoi:soefifhyaosf >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid output directory"
$M --input processed.yaml --outdir ./in/valid nop.rb >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

rm -rf x o e out
) > $(basename $0 .sh).res
