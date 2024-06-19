# frozen_string_literal: true

# Copyright 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

$context = ''
def assert(value, expected, message)
  condition = value == expected
  $stdout.puts("#{condition ? 'ok' : 'fail'}: #{$context}: #{message}")
  $stderr.puts("#{value.to_s} != #{expected.to_s}") unless condition
  $unit_test = 1 unless condition
  return condition
end
