#!/bin/sh

(
echo "####COMMAND Unit tests"
./unittest-apiobjects >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Loaders unit tests"
./unittest-loaders >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Task unit tests"
./unittest-task >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o | sed "s#$(dirname $PWD)/##g"
echo "####ERR"
cat e | grep -v 'erb.rb' | sed "s#$(dirname $PWD)/##g"

echo "####COMMAND Gen unit tests"
./unittest-gen >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Generate unit tests"
./unittest-generate >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
) > $(basename $0 .sh).res

rm -f o e
