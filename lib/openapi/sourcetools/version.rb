# frozen_string_literal: true

# Copyright © 2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

module OpenAPISourceTools
  NAME = 'openapi-sourcetools'
  VERSION = '0.9.2'

  def self.info(separator = ': ')
    "#{NAME}#{separator}#{VERSION}"
  end
end
