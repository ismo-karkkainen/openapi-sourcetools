#!/bin/sh

M="../bin/openapi-addparameters"

(
echo "####COMMAND Invalid output file"
printf -- '---\nopenapi: 3.1.0' | $M --output ./in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Invalid input file"
$M --output x --input ./in/valid >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Output file"
printf -- '---\nopenapi: 3.1.0' | $M --output x >o 2>e
echo "####CODE $?"
echo "####OUT"
cat x o
echo "####ERR"
cat e

echo "####COMMAND No input file"
echo | $M >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Input and output"
$M >o 2>e <<EOF
---
openapi: 3.1.0
info:
  title: SomeAPI
  version: 1.0.0
  description: Test stuff
  license:
    name: UPL 1.0
    url: https://opensource.org/license/UPL
tags:
- name: test
  description: Only for testing purposes.
paths:
  /root:
    parameters:
    - name: top
      in: path
      schema:
        "\$ref": "#/components/schemas/Name"
    get:
      parameters:
      - name: add
        in: path
        schema:
          "\$ref": "#/components/schemas/Name2"
  /something:
    parameters:
    - "\$ref": "#/components/parameters/Param1"
    post:
      parameters:
      - name: other
        in: header
        schema:
          "\$ref": "#/components/schemas/Name"
components:
  parameters:
    Param1:
      name: add
      in: path
      schema:
        "\$ref": "#/components/schemas/Name2"
EOF
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

#echo "####COMMAND Processed output"
#$M -i test.yaml >o 2>e
#echo "####CODE $?"
#echo "####OUT"
#cat o
#echo "####ERR"
#cat e
) > $(basename $0 .sh).res

rm -f x o e
