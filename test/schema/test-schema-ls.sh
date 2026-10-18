#!/bin/sh

# Created by OpenCode, gemma4, Ollama

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$DIR/../../bin"
RESFILE="$DIR/$(basename "$0" .sh).res"

(
echo "####COMMAND Missing input"
"$BIN_DIR/openapi-schema-ls" --input nonexistent.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Bad inputpaths as not JSON"
"$BIN_DIR/openapi-schema-ls" --input openapi.yaml --inputpaths invalid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Bad inputpaths as JSON-encoded string"
"$BIN_DIR/openapi-schema-ls" --input openapi.yaml --inputpaths '"invalid"' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Listing schemas"
"$BIN_DIR/openapi-schema-ls" --input openapi.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Dump paths data"
"$BIN_DIR/openapi-schema-ls" --dump jsonschema --format yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid format"
"$BIN_DIR/openapi-schema-ls" --dump jsonschema --format invalid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

) > "$RESFILE"

rm -f o e
