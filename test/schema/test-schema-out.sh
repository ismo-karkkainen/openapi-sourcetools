#!/bin/sh

# Created by OpenCode, gemma4, Ollama

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$DIR/../../bin"
RESFILE="$DIR/$(basename "$0" .sh).res"

(
echo "####COMMAND Missing name"
"$BIN_DIR/openapi-schema-out" --input openapi.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Bad inputpaths as not JSON"
"$BIN_DIR/openapi-schema-out" --name Inserted --input openapi.yaml --inputpaths invalid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Bad inputpaths as JSON-encoded string"
"$BIN_DIR/openapi-schema-out" --name Inserted --input openapi.yaml --inputpaths '"invalid"' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Bad schemapaths as not JSON"
"$BIN_DIR/openapi-schema-out" --name Inserted --input openapi.yaml --schemapaths invalid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Name has path separator"
"$BIN_DIR/openapi-schema-out" --name foo/bar --input openapi.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Document is not an object"
"$BIN_DIR/openapi-schema-out" --name Inserted --input invalid.txt >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Schema not found"
"$BIN_DIR/openapi-schema-out" --name NonExistent --input openapi.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid format"
"$BIN_DIR/openapi-schema-out" --format invalid --input openapi.yaml --name UserNumber >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Writing schema with dependencies"
"$BIN_DIR/openapi-schema-out" --input openapi.yaml --name UserNumber >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Writing schema without dependencies"
"$BIN_DIR/openapi-schema-out" --no-refs --input openapi.yaml --name UserNumber >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Reference schema with dependencies"
"$BIN_DIR/openapi-schema-out" --input openapi.yaml --name JustReference >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Adding keys and values"
"$BIN_DIR/openapi-schema-out" --input openapi.yaml --name UserNumber --add foo:bar '--add=$schema:https://json-schema.org/draft/2020-12/schema' '--add=-key:jsON:{"sub":"value"}' >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND No key:value pair"
"$BIN_DIR/openapi-schema-out" --input openapi.yaml --name UserNumber --add= >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Empty key to add"
"$BIN_DIR/openapi-schema-out" --input openapi.yaml --name UserNumber --add=:value >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

) > "$RESFILE"

rm -f o e
