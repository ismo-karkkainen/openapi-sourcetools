#!/bin/sh

M="../bin/openapi-generate-checkconfig"

(
cd ../test-generate

echo "####COMMAND No config"
$M >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Config"
$M -c cfg+/filewdir >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Config, empty separator"
$M -c cfg+/filewdir -s '' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Config, separator"
$M -c cfg+/filewdir -s + >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Config, separator, read info"
$M -c cfg+/filewdir -s + -r >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Config, separator, empty keys"
$M -c cfg__/filewdir -s __ -k '' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Config, separator, only separator keys"
$M -c cfg__/filewdir -s __ -k '///' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Config, separator, keys"
$M -c cfg__/filewdir -s __ -k 'root0/key1/key10' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Config, separator, keys, read info"
$M -c cfg__/filewdir -s __ -k 'root0/key1/key10' -r >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

rm -f o e
) > $(basename $0 .sh).res
