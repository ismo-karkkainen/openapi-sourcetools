# openapi-sourcetools

A collection of small tools for OpenAPI format API specifications.
This is a work in progress.

The end result is intended to make processing an OpenAPI documents easier
for purposes of code generation. As the processing stages done for that
purpose can be useful in themselves, the overall process is split to separate
Ruby programs.

The purpose of openapi-merge is to avoid duplication of parts between
documents. Only one in this category but proved useful.

The various openapi-addsomething programs are intended to ensure there is only
one copy of each practically identical schema, header, and response. Besides
avoiding duplicated definitions, they also ensure that code generation does
not need to check if same type has already been declared.

The practically identical is from a programming point of view. Summary,
description, and examples are ignored by default.

If you want to check for duplicate definitions, run the program and compare
output with original file. Copy and rename definitions from processed file to
the original as appropriate. Names for added component definitions follow the
same pattern of TypeNx where Type is Schema, Header, etc. N is a number and x
is present only to make find and replace easier as e.g. Schema1x is distinct
from Schema10x whereas Schema1 and Schema10 might have issues with replacement
in wrong places.

The openapi-processpaths and openapi-frequencies were intended to obtain
data about how much various paths are used. Arguably simple to implement even
though need for these may be low.

These programs are not intended to verify that the documents fed to them
comply with any OpenAPI version. If the document is close enough, processing
will succeed. Given the intended end task of producing code from the document,
it is not guaranteed the output will be strictly an OpenAPI format document.

## openapi-addheaders

Checks for presence of header definitions under components/responses and
paths. For any definition found, adds a definition under components/headers
and replaces the original with a reference.

This does not change or remove existing header definitions. Those may be
practicaly identical to each other but they will remain. Headers defined
inside responses end up referring to one of them if they are practically
identical.

You should run openapi-addschemas beforehand to ensure that practically
identical schemas have been replaced with identical references.

## openapi-addresponses

Checks for presence of response definitions under paths. For any definition
found, adds a definition under components/responses and replaces the original
with a reference.

This does not change existing response definitions even if they are practically
identical to each other.

You should run openapi-addheaders beforehand to ensure that practically
identical headers have been replaced with identical references.

## openapi-addschemas

Checks for presence of schma definitions first inside the schemas under
components/schemas, and then elsewhere in the document. For any definition
found, adds a definition under components/schemas and replaces the original
with a reference.

This does not change existing schemas declared at level immediately under
components/schemas that are practically identical to refer to one of them.
The properties of objects will be changed to references.

## openapi-merge

Takes multiple documents and adds content without over-writing.

Intended use is to keep common components in one file and add them to
multiple API documents to avoid information duplication. Also
applies to adding health check path or similar.

## openapi-processpaths

Splits paths into parts that are fixed or have a variable. Paths that do not
have differences in fixed parts only are reported as errors by default.
Otherwise "look-alike" paths are found and stored.

## openapi-frequencies

Takes the output of openapi-processpaths and a log file with one path per line
and counts occurrences for each path in the processed API document and saves
the count under "freq" key into path object.

## Work in Progress

openapi-checkschemas is for giving the user some information about types.

openapi-oftypes is intended for gathering information and making checks that
the code generation for allOf, oneOf, and anyOf becomes simpler.

openapi-generatecode is turning to something that helps in orchestrating the
code generation processing. Duplicate checks have been separated into other
programs to keep this simpler, in part.

## License

Copyright © 2021-2024 Ismo Kärkkäinen

Licensed under Universal Permissive License. See LICENSE.txt.
