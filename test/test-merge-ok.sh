#!/bin/sh

M="../bin/openapi-merge --keep"

(
cd ../test-merge
for C in components paths webhooks
do
    echo "####COMMAND $C"
    $M all.yaml $C-ok.yaml >o 2>e
    echo "####CODE $?"
    echo "####OUT"
    cat o
    echo "####ERR"
    cat e
    rm -f o e
done

echo "####COMMAND tagsecsrv"
$M tagsecsrv.yaml tagsecsrv-tags.yaml tagsecsrv-security.yaml tagsecsrv-servers.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
rm -f o e

echo "####COMMAND first"
$M --first openapi --first info --first jsonSchemaDialect --first servers --first paths --first webhooks --first components --first tags --first externalDocs all_first.yaml all.yaml all_last.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
rm -f o e

echo "####COMMAND last"
$M --last openapi --last info --last jsonSchemaDialect --last servers --last paths --last webhooks --last components --last tags --last externalDocsall_first.yaml all.yaml all_last.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
rm -f o e

echo "####COMMAND first partial"
$M --first openapi --first info --first jsonSchemaDialect --first servers first.yaml all.yaml all_last.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
rm -f o e

echo "####COMMAND last partial"
$M --last openapi --last info --last jsonSchemaDialect --last servers all_first.yaml all.yaml last.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
rm -f o e

echo "####COMMAND mixed"
$M --last openapi --last info --first jsonSchemaDialect --first servers first.yaml all.yaml last.yaml >o 2>e
echo "####CODE $?"
echo "####OUT"
cat o
echo "####ERR"
cat e
rm -f o e

) | grep -v -e '^Finished in' > $(basename $0 .sh).res
