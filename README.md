# openapi-sourcetools

A collection of small tools for OpenAPI format API specifications.

# openapi-merge

Takes multiple documents and adds content without over-writing.

Intended use is to keep common components in one file and add them to
multiple API documents without having to duplicate information. Also
applies to adding health check path or similar.

# openapi-processpaths

Splits paths into parts that are fixed or have a variable. Paths that do not
have differences in fixed parts only are reported as errors by default.
Otherwise "look-alike" paths are found and stored.

# openapi-frequencies

Takes the output of openapi-processpaths and a log file with one path per line
and counts occurrences for each path in the processed API document and saves
the count under "freq" key.

# openapi-generatecode

Takes an ERB-template, processed API document, and optional files that have
their contents added to the context passed to the ERB. Output is what the
ERB-template produces.

# License

Copyright © 2021 Ismo Kärkkäinen

Licensed under Universal Permissive License. See LICENSE.txt.
