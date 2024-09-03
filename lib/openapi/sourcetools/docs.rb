# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

module OpenAPISourceTools
  # To hold documents loaded via command-line.
  # Provides attribute accessor methods for each document.
  # Exposed via Gen.d to tasks.
  class Docs
    attr_reader :docs

    def initialize
      @docs = {}
    end

    def method_missing(method_name, *args)
      name = method_name.to_s
      if name.end_with?('=')
        name = name[0...(name.size - 1)]
        super unless @docs.key?(name)
        @docs[name] = args.first
        return args.first
      end
      super unless @docs.key?(name)
      @docs[name]
    end

    def respond_to_missing?(method_name, *args)
      name = method_name.to_s
      name = name[0...(name.size - 1)] if name.end_with?('=')
      @docs.key?(name) || super
    end

    def add(name, content)
      return false if docs.key?(name)
      @docs[name] = content
      true
    end
  end
end
