#!/bin/sh

M="../bin/openapi-addschemas"

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
  /root/{par}:
    parameters:
    - name: par
      in: path
      required: true
      description: Something.
      schema:
        type: string
    get:
      tags:
      - test
      summary: Parameter in path
      description: Afterwards, inlined string type should be a reference.
      operationId: getRootPar
      responses:
        200:
          description: Blah blah blah.
          content:
            application/json:
              schema:
                description: Object.
                type: object
                required:
                - field
                properties:
                  field:
                    type: string
                    minLength: 10
                    maxLength: 32
                  other:
                    type: number
                additionalProperties:
                  type: object
                  properties:
                    addi:
                      type: string
                      minLength: 10
                      maxLength: 32
                    prop:
                      type: object
          headers:
            content-type:
              schema:
                type: string
                pattern: "^application/json$"
            content-length:
              schema:
                type: integer
                minimum: 0
        404:
          description: Error.
          content:
            application/json:
              schema:
                description: Whatever.
                type: object
  /something:
    post:
      summary: Similar types should become equivalent references
      operationId: postSomething
      requestBody:
        content:
          application/json:
            schema:
              description: Object.
              type: object
              required:
              - field
              properties:
                field:
                  type: string
                  minLength: 10
                  maxLength: 32
                other:
                  type: number
              patternProperties:
                "^[a-x]+$":
                  description: From patternProperties.
                  type: integer
                  minimum: 0
              additionalProperties: true
      responses:
        204:
          description: Empty.
        404:
          description: Error.
          content:
            application/json:
              schema:
                description: Whatever.
                type: object
EOF
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

echo "####COMMAND Processed output"
$M -i test.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
) > $(basename $0 .sh).res

rm -f x o e
