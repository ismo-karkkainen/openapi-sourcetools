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

) > $(basename $0 .sh).res
