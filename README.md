# openapi-sourcetools

A collection of small tools for OpenAPI format API specifications.
This is a work in progress.

The end result is intended to make processing an OpenAPI documents easier
for purposes of code generation. As the processing stages done for that
purpose can be useful in themselves, the overall process is split to separate
Ruby programs.

Although code generation was the initial target, the first thing to generate
anything is the simple document generation in documentation sub-directory.

The purpose of openapi-merge is to avoid duplication of parts between
documents. Only one in this category but proved useful.

The various openapi-addsomething programs are intended to ensure there is only
one copy of each practically identical schema, header, parameter, and response.
Besides avoiding duplicated definitions, they also ensure that code generation
does not need to check if same type has already been declared.

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

These programs do not verify that the documents fed to them comply with any
OpenAPI version. If the document is close enough, processing will succeed.

## openapi-addschemas

Checks for presence of schma definitions first inside the schemas under
"components/schemas", and then elsewhere in the document. For any definition
found, adds a definition under "components/schemas" and replaces the original
with a reference.

This does not change existing schemas declared at level immediately under
"components/schemas" that are practically identical to refer to one of them.
The properties of objects will be changed to references.

For simple types such as a string with no size or content limitations, output
may appear annoying. For processing the document later, I think it is easier
to detect that you have another string with different limitations and make a
decision to treat it as a different type or provide a function to check
the limitations, given a generic string, than to keep track of what you have
already encountered when openapi-generate is being run.

## openapi-checkschemas

Checks schemas and reports if they appear to be equivalent. Expects that
openapi-addschemas has been run. Does not modify the source document.

Two schemas with same number or properties with same types but different
property names can be equivalent. That alone does not mean that one should
be dropped as different contexts may have similar types. Mainly intended to
be used for checking if there is something to clean up.

## openapi-addheaders

Checks for presence of header definitions under "components/responses" and
"paths". For any definition found, adds a definition under "components/headers"
and replaces the original with a reference.

This does not change or remove existing header definitions. Those may be
practically identical to each other but they will remain. Headers defined
inside responses end up referring to one of them if they are practically
identical.

You should run openapi-addschemas beforehand to reduce unnecessary variation.

## openapi-addparameters

Checks for presence of parameter definitions under paths. For any definition
found, adds a definition under "components/parameters" and replaces the
original with a reference.

You should run openapi-addschemas beforehand to reduce unnecessary variation.

## openapi-addresponses

Checks for presence of response definitions under paths. For any definition
found, adds a definition under "components/responses" and replaces the original
with a reference.

This does not change existing response definitions even if they are practically
identical to each other.

You should run openapi-addschemas beforehand to reduce unnecessary variation.

## openapi-generate

Loads code that processes the OpenAPI format document and produces output.
Increasingly intended to just manage things rather than to do actual work.

Loaded code can add tasks during load time. After everything has been loaded,
the tasks are run. Task would usually produce output but can omit it.

Sub-directory documentation has the start of a gem that produces some kind of
documentation about the document. A markdown file and source diagam files
for diagrammatron are produced.

The input document can in practice be anything that Ruby YAML module can load.
There is a helper task that by default is added first. Since processors loaded
later can modify the tasks list, it can be removed and replaced with something
else. Hence this might be useful in processing other YAML documents besides
API as originally intended. Main benefit in running all together is that the
tasks can pass information between each other. Processing same file multiple
times would have to rely on code producing exactly same results with regard to
variable naming etc. Remains to be seen if this should be elsewhere or if there
is something that does the job already.

## openapi-merge

Takes multiple documents and adds content without over-writing.

Intended use is to keep common components in one file and add them to multiple
API documents to avoid information duplication. Also applies to adding health
check path or similar.

## openapi-modifypaths

Takes a document and allows, adding, deleting, or replacing path prefixes.

You may want to add for example a version string element into the start of the
path. Prior to joining multiple documents using openapi-merge, you may want
to give each piece an unique suffix. Original API documents could be used with
services behind a load balancer that maps paths in combined document and
passes the request to the respective service. And so on. You probably could
just use sed but this might give you fewer opportunities for error with the
loss of flexibility.

## openapi-processpaths

Splits paths into parts that are fixed or have a variable. Paths that do not
have differences in fixed parts only are reported as errors by default.
Otherwise "look-alike" paths are found and stored.

## openapi-frequencies

Takes the output of openapi-processpaths and a log file with one path per line
and counts occurrences for each path in the processed API document and saves
the count under "freq" key into path object.

## Work in Progress

openapi-oftypes is intended for gathering information and making checks so that
the code generation for allOf, oneOf, and anyOf becomes simpler.

## License

Copyright © 2021-2024 Ismo Kärkkäinen

Licensed under Universal Permissive License. See LICENSE.txt.
