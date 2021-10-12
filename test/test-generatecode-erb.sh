#!/bin/sh

M="../bin/openapi-generatecode"

(
cd ../test-generatecode

echo "####COMMAND Only template"
$M --input processed.yaml --template template.erb >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND JSON, YAML, text file, and Ruby extension"
$M --input processed.yaml --template status.erb add.yaml add.json add.txt extension.rb >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Error in template"
$M --input processed.yaml --template error.erb add.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Error in extension"
$M --input processed.yaml --template status.erb error.rb >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
# Error message depends on Ruby version so ignore it. Exit code 4 ok.

echo "####COMMAND Run-time error in extension"
$M --input processed.yaml --template runerror.erb runerror.rb >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

rm -f o e
) > $(basename $0 .sh).res
