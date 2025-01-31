# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'sourcetools/task'
require_relative 'sourcetools/config'
require_relative 'sourcetools/version'
require_relative 'sourcetools/apiobjects'
# Other modules or classes are exposed via Gen attributes as class instances as needed.
# Docs is only needed for run-time storage of whatever loaders can handle.
# Loaders array is exposed and can be added to at run-time.
# Helper instance is accessible via Gen.h.
# Output is exposed via Gen.o and Gen.output. Note that if you assign to one,
# the other will not change.
# The rest are for internal implementation.
