# openapi-sourcetools

A collection of small tools for OpenAPI format API specifications.

# openapi-merge

Takes multiple documents and adds content without over-writing.

Intended use is to keep common components in one file and add them to
multiple API documents to avoid information duplication. Also
applies to adding health check path or similar.

# openapi-processpaths

Splits paths into parts that are fixed or have a variable. Paths that do not
have differences in fixed parts only are reported as errors by default.
Otherwise "look-alike" paths are found and stored.

# openapi-frequencies

Takes the output of openapi-processpaths and a log file with one path per line
and counts occurrences for each path in the processed API document and saves
the count under "freq" key.

# openapi-addschemas

Reads an API specification and for all inlined schemas, creates a reference to
a new schema. Also creates schemas for arrays and objects that are not already
schemas.

The purpose is to take everything that might be considered a type in a
programming language and place them under "#/components/schemas/" so that in a
template there is no need to keep track of whether a type has been defined or
not. The program does the substitytion of type to common schema to the point of
being annoying to humans, as even a simple "type: string" will be turned into a reference and separate schema. Likewise integers with different limits will
each become a separate schema. It is easier to recognize these cases and use
common type with value checks elsewhere than keep track of all occurrences in
case a separate type is actually desired.


# License

Copyright © 2021-2024 Ismo Kärkkäinen

Licensed under Universal Permissive License. See LICENSE.txt.
