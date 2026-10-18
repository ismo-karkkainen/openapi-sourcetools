#!/bin/sh

# Copyright © 2026 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$DIR/../../bin"
RESFILE="$DIR/$(basename "$0" .sh).res"

(
echo "####COMMAND Missing name"
"$BIN_DIR/openapi-schema-in" --input openapi.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Both from stdin"
"$BIN_DIR/openapi-schema-in" --name Inserted >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Bad input path data as JSON-encoded string"
"$BIN_DIR/openapi-schema-in" --name Inserted --input openapi.yaml --inputpaths '"invalid"' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Bad input path data as not JSON"
"$BIN_DIR/openapi-schema-in" --name Inserted --input openapi.yaml --inputpaths invalid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Bad schema path data as not JSON"
"$BIN_DIR/openapi-schema-in" --name Inserted --input openapi.yaml --schemapaths invalid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Name has path separator"
"$BIN_DIR/openapi-schema-in" --name foo/bar --input openapi.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Input content is invalid"
"$BIN_DIR/openapi-schema-in" --name Inserted --input invalid.txt --schema schema.json >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Schema content is invalid"
"$BIN_DIR/openapi-schema-in" --name Inserted --input openapi.yaml --schema invalid.txt >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid format"
"$BIN_DIR/openapi-schema-in" --format invalid --input openapi.yaml --schema schema.json --name Inserted >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Insert with dependencies"
"$BIN_DIR/openapi-schema-in" --input openapi.yaml --schema schema.json --name Inserted >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Save to file, drop key"
"$BIN_DIR/openapi-schema-in" --input openapi.yaml --schema schema.json --name Inserted --output tmp --drop '$schema' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o tmp
echo "####ERR"
cat e

echo "####COMMAND Insert without dependencies"
"$BIN_DIR/openapi-schema-in" --no-refs --input openapi.yaml --schema schema.json --name Inserted >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Reverse overwrite with dependencies"
"$BIN_DIR/openapi-schema-in" --schemapaths openapi --schema openapi.yaml --format pretty_json --inputpaths jsonschema --input schema.json --name UserNumber >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Reverse insert without dependencies"
"$BIN_DIR/openapi-schema-in" --no-refs --schemapaths openapi --schema openapi.yaml --inputpaths jsonschema --input schema.json --name UserNumber >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

) > "$RESFILE"

rm -f o e tmp
