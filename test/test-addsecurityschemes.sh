#!/bin/sh

M="../bin/openapi-addsecurityschemes"

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

echo "####COMMAND Input with missing security schema"
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
security:
- token: []
- some: []
  other: [ implicit ]
- missing: []
paths:
  something:
    parameters:
    - "\$ref": "#/components/parameters/TopName"
    get:
      operationId: getSomething
      other: 123
      parameters:
      - name: foo
        in: path
        schema:
          "\$ref": "#/components/schemas/Name"
      - name: toplevel
        in: path
        schema:
          "\$ref": "#/components/schemas/TopName"
      security:
      - {}
    method:
      no: parameters
    post:
      operationId: postSomething
      parameters:
      - name: foo
        in: path
        schema:
          "\$ref": "#/components/schemas/Name"
      security: []
    put:
      operationId: putSomething
      parameters:
      - name: foo
        in: path
        schema:
          "\$ref": "#/components/schemas/Name"
  otherthing:
    method:
      operationId: methodOtherthing
      parameters:
      - name: foo
        in: path
        schema:
          "\$ref": "#/components/schemas/Name"
      security:
      - different: []
components:
  securitySchemes:
    token:
      type: http
      scheme: bearer
    some:
      type: apikey
      in: header
    other:
      type: oauth2
      flows:
        implicit:
          authorizationUrl: https://example.com/api/oauth/dialog
          scopes: {}
    different:
      type: mutualTLS
EOF
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
security:
- token: []
- some: []
  other: [ implicit ]
paths:
  something:
    parameters:
    - "\$ref": "#/components/parameters/TopName"
    get:
      operationId: getSomething
      other: 123
      parameters:
      - name: foo
        in: path
        schema:
          "\$ref": "#/components/schemas/Name"
      - name: toplevel
        in: path
        schema:
          "\$ref": "#/components/schemas/TopName"
      security:
      - {}
    method:
      no: parameters
    post:
      operationId: postSomething
      parameters:
      - name: foo
        in: path
        schema:
          "\$ref": "#/components/schemas/Name"
      security: []
    put:
      operationId: putSomething
      parameters:
      - name: foo
        in: path
        schema:
          "\$ref": "#/components/schemas/Name"
  otherthing:
    method:
      operationId: methodOtherthing
      parameters:
      - name: foo
        in: path
        schema:
          "\$ref": "#/components/schemas/Name"
      security:
      - different: []
components:
  securitySchemes:
    token:
      type: http
      scheme: bearer
    some:
      type: apikey
      in: header
    other:
      type: oauth2
      flows:
        implicit:
          authorizationUrl: https://example.com/api/oauth/dialog
          scopes: {}
    different:
      type: mutualTLS
EOF
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e

) > $(basename $0 .sh).res

rm -f x o e
