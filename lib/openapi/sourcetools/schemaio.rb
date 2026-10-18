# frozen_string_literal: true

# Copyright © 2026 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'common'
require 'yaml'
require 'json'


# Gem namespace.
module OpenAPISourceTools
  # Methods and classes to get schemas in and out of documents.
  module SchemaIO
    OPENAPI_PATHS = <<EOF
---
separator: "/" # For splitting paths.
ignore: "#" # What to ignore in split paths.
named: "#/components/schemas" # Before named schema.
reference: "$ref" # Reference key name.
referenced: "#/components/schemas" # Reference path before schema name.
EOF

    JSON_SCHEMA_PATHS = <<EOF
---
separator: "/"
ignore: "#"
named: ~
reference: "$ref"
referenced: "#/$defs"
EOF

    JSON_SCHEMA_DEFS_PATHS = <<EOF
---
separator: "/"
ignore: "#"
named: "#/$defs"
reference: "$ref"
referenced: "#/$defs"
EOF

    BUILTINS = {
      openapi: OPENAPI_PATHS,
      jsonschema: JSON_SCHEMA_PATHS,
      jsonschemadefs: JSON_SCHEMA_DEFS_PATHS
    }.freeze

    def self.get(name)
      BUILTINS[name.is_a?(String) ? name.downcase.to_sym : name]
    end

    # Checks format and does some convenience preparations.
    class SchemaFormat
      attr_reader :separator, :named, :reference, :referenced

      def initialize(format)
        f = format.is_a?(Hash) ? format : YAML.safe_load(format)
        raise ArgumentError, 'Format is not an object.' unless f.is_a?(Hash)
        errors = []
        @separator = f['separator']
        errors.push('separator must be a non-empty string.') unless @separator.is_a?(String) && !@separator.empty?
        @ignore = f['ignore']
        errors.push('ignore must be a string or an array of strings.') unless @ignore.is_a?(String) || @ignore.is_a?(Array)
        if @ignore.is_a?(Array)
          errors.push('ignore array values must be non-empty strings') unless @ignore.index { |v| !v.is_a?(String) || v.empty? }.nil?
        else
          @ignore = [ @ignore ]
        end
        @ignore.push('')
        @named = f['named']
        @reference = f['reference']
        errors.push('Reference key must be non-empty string.') if @reference.nil?
        @referenced = f['referenced']
        raise ArgumentError, errors.join("\n") unless errors.empty?
        @named = '' if @named.nil?
        @named += @separator unless @named.empty? || @named.end_with?(@separator)
        @referenced += @separator unless @referenced.nil? || @referenced.empty? || @referenced.end_with?(@separator)
      end

      def ignore?(str)
        @ignore.include?(str)
      end

      def path(str)
        str.split(@separator).reject { |p| ignore?(p) }
      end

      def reference?(key, value)
        # Accurate enough for now.
        @reference == key && value.is_a?(String) && value.start_with?(@referenced)
      end

      def reference_name(ref)
        ref[@referenced.size..]
      end

      def make_reference(name)
        "#{@referenced}#{name}"
      end

      def root_schema?
        @named.empty?
      end
    end

    def self.load_data(data)
      # File name?
      if data.is_a?(String)
        begin
          return YAML.safe_load_file(data)
        rescue StandardError
          # Was not a file, it is ok.
        end
      end
      # Internal key?
      d = get(data)
      return YAML.safe_load(d) unless d.nil?
      # Try to parse as JSON.
      if data.is_a?(String)
        begin
          return JSON.parse(data)
        rescue JSON::ParserError
          # Was not.
        end
      end
      nil
    end

    def self.key_data(data)
      d = load_data(data)
      d.nil? ? nil : SchemaFormat.new(d)
    rescue ArgumentError => e
      Common.aargh(e.to_s)
      nil
    end

    # Changes references from source format to target format.
    def self.alter_refs(schema, source_access, target_access)
      if schema.is_a?(Array)
        schema.each do |v|
          alter_refs(v, source_access, target_access)
        end
      end
      return unless schema.is_a?(Hash)
      schema.keys.each do |key|
        value = schema[key]
        if source_access.format.reference?(key, value)
          # Change the prefix in the reference, unless equal.
          unless target_access.format.referenced == source_access.format.referenced
            value = target_access.format.make_reference(source_access.format.reference_name(value))
          end
          # Change reference key name if needed.
          if source_access.format.reference == target_access.format.reference
            schema[key] = value
          else
            schema.delete(key)
            schema[target_access.format.reference] = value
          end
        elsif value.is_a?(Hash) || value.is_a?(Array)
          alter_refs(value, source_access, target_access)
        end
      end
    end

    # Handles document with schemas in stated places. Reads or modifies.
    class SchemaAccess
      attr_reader :document, :format

      def initialize(format, document)
        @document = document
        @format = format
      end

      # Used when reading from given document.

      def list_schema_names
        schemas = @document.dig(*@format.path(@format.referenced))
        schemas.keys.sort!
      end

      def find_named_schema(name)
        if @format.root_schema?
          # Make a copy and remove the root key to referenced definitions.
          out = {}.merge!(@document)
          first = @format.path(@format.referenced).first
          out.delete(first) unless first.nil?
          out
        else
          find_by_reference(@format.make_reference(name))
        end
      end

      def find_referenced_schemas(name, schema)
        name2schema = {}
        return name2schema if schema.nil?
        existing = Set.new # Stops loops.
        existing.add(name) unless @format.root_schema?
        todo = [ schema ]
        until todo.empty?
          s = todo.pop
          refs = Set.new
          gather_refs(s, refs, existing)
          # Add all new references to the todo list, if present in the file.
          refs.each do |r|
            existing.add(r)
            idx = r.rindex(@format.separator)
            next if idx.nil?
            refd = find_by_reference(r)
            next if refd.nil?
            todo.push(refd)
            name2schema[r[(idx + 1)..]] = todo.last
          end
        end
        name2schema
      end

      # Used when writing to given document.

      def put_named_schema(name, schema)
        if @format.root_schema?
          # If clear was to be done we'd need to retain "$defs" or such.
          # In intended use, JSON schema document is empty when writing to root.
          @document.merge!(schema)
        else
          path = make_path(@format.named, name)
          OpenAPISourceTools::Common.bury(@document, path, schema)
        end
      end

      # Call only after put_named_schema.
      def put_referenced_schema(name, schema)
        path = make_path(@format.referenced, name)
        OpenAPISourceTools::Common.bury(@document, path, schema)
      end

      private

      def make_path(start, name)
        @format.path(start).push(name)
      end

      def find_by_reference(ref)
        # Implicitly expects that references always have same start followed by name.
        @document.dig(*@format.path(ref))
      end

      def gather_refs(schema, found, existing)
        if schema.is_a?(Array)
          schema.each do |v|
            gather_refs(v, found, existing)
          end
        end
        return unless schema.is_a?(Hash)
        schema.each do |key, value|
          if @format.reference?(key, value)
            found.add(value) unless existing.member?(value)
          elsif value.is_a?(Hash) || value.is_a?(Array)
            gather_refs(value, found, existing)
          end
        end
      end
    end
  end
end
