#!/bin/sh

M="../bin/openapi-checkschemas"

(
echo "####COMMAND Input and output"
$M -e -t -r -c >o 2>e <<EOF
paths:
  "/root/{par}":
    parameters:
    - name: par
      in: path
      required: true
      description: Something.
      schema:
        "$ref": "#/components/schemas/Schema6x"
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
                "$ref": "#/components/schemas/Schema2x"
          headers:
            content-type:
              schema:
                "$ref": "#/components/schemas/Schema4x"
            content-length:
              schema:
                "$ref": "#/components/schemas/Schema3x"
        404:
          description: Error.
          content:
            application/json:
              schema:
                "$ref": "#/components/schemas/Schema5x"
  "/something":
    post:
      summary: Similar types should become equivalent references
      operationId: postSomething
      requestBody:
        content:
          application/json:
            schema:
              "$ref": "#/components/schemas/Schema2x"
      responses:
        204:
          description: Empty.
        404:
          description: Error.
          content:
            application/json:
              schema:
                "$ref": "#/components/schemas/Schema5x"
components:
  schemas:
    Schema0x:
      type: string
      minLength: 10
      maxLength: 32
    Schema1x:
      type: number
    Schema2x:
      description: Object.
      type: object
      required:
      - field
      properties:
        field:
          "$ref": "#/components/schemas/Schema0x"
        other:
          "$ref": "#/components/schemas/Schema1x"
    Schema3x:
      type: integer
      minimum: 0
    Schema4x:
      type: string
      pattern: application/json
    Schema5x:
      description: Whatever.
      type: object
    Schema2b:
      description: Copycat.
      type: object
      required:
      - foo
      properties:
        foo:
          "$ref": "#/components/schemas/Schema0x"
        bar:
          "$ref": "#/components/schemas/Schema1x"
    Schema6x:
      type: string
    Schema0b:
      type: string
      minLength: 10
      maxLength: 32
    Schema2c:
      description: Undetected.
      type: object
      required:
      - foo
      properties:
        foo:
          "$ref": "#/components/schemas/Schema0b"
        bar:
          "$ref": "#/components/schemas/Schema1x"
EOF
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
) > $(basename $0 .sh).res

rm -f x o e
