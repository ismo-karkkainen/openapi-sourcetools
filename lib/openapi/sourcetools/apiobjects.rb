# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require 'set'


module OpenAPISourceTools
  # Various classes for handling objects in the API specification.
  # Used in various programs.
  module ApiObjects

    def self.same(a, b, ignored_keys = Set.new(%w[summary description]))
      return a == b unless a.is_a?(Hash) && b.is_a?(Hash)
      keys = Set.new(a.keys + b.keys) - ignored_keys
      keys.to_a.each do |k|
        return false unless a.key?(k) && b.key?(k)
        return false unless same(a[k], b[k], ignored_keys)
      end
      true
    end

    def self.ref_string(name, schema_path)
      "#{schema_path}/#{name}"
    end

    def self.reference(obj, schemas, schema_path, ignored_keys = Set.new(%w[summary description]), prefix = 'Schema')
      # Check if identical schema has been added and if so, return the $ref string.
      schemas.keys.sort.each do |k|
        return ref_string(k, schema_path) if same(obj, schemas[k], ignored_keys)
      end
      # One of the numbers will not match existing keys. More number than keys.
      (schemas.size + 1).times do |n|
        # 'x' is to simplify find and replace (Schema1x vs Schema1 and Schema10)
        k = "#{prefix}#{n}x"
        next if schemas.key?(k)
        schemas[k] = obj.merge
        return ref_string(k, schema_path)
      end
    end

    # A component in the API specification for reference and anchor handling.
    class Components
      attr_reader :path, :prefix, :anchor2ref, :schema_names
      attr_accessor :items, :ignored_keys

      def initialize(path, prefix, ignored_keys = %w[summary description examples example $anchor])
        path = "#/#{path.join('/')}/" if path.is_a?(Array)
        path = "#{path}/" unless path.end_with?('/')
        @path = path
        @prefix = prefix
        @anchor2ref = {}
        @schema_names = Set.new
        @items = {}
        @ignored_keys = Set.new(ignored_keys)
      end

      def add_options(opts)
        opts.on('--use FIELD', 'Use FIELD in comparisons.') do |f|
          @ignored_keys.delete(f)
        end
        opts.on('--ignore FIELD', 'Ignore FIELD in comparisons.') do |f|
          @ignored_keys.add(f)
        end
      end

      def help
        %(All fields are used in object equality comparisons except:\n#{@ignored_keys.to_a.sort!.join("\n")})
      end

      def add_schema_name(name)
        @schema_names.add(name)
      end

      def ref_string(name)
        return nil if name.nil?
        "#{@path}#{name}"
      end

      def reference(obj)
        # Check if identical schema has been added. If so, return the $ref string.
        @items.each do |k, v|
          return ref_string(k) if ApiObjects.same(obj, v, @ignored_keys)
        end
        # One of the numbers will not match existing keys. More number than keys.
        (@items.size + 1).times do |n|
          # 'x' is to simplify find and replace (Schema1x vs Schema1 and Schema10)
          cand = "#{@prefix}#{n}x"
          next if @items.key?(cand)
          @items[cand] = obj.merge
          @schema_names.add(cand)
          return ref_string(cand)
        end
      end

      def store_anchor(obj, ref = nil)
        anchor_name = obj['$anchor']
        return if anchor_name.nil?
        ref = obj['$ref'] if ref.nil?
        raise StandardError, 'ref is nil and no $ref or it is nil' if ref.nil?
        @anchor2ref[anchor_name] = ref
      end

      def alter_anchors
        replacements = {}
        @anchor2ref.each_key do |a|
          next if @schema_names.member?(a)
          replacements[a] = ref_string(a)
          @schema_names.add(a)
        end
        replacements.each do |a, r|
          @anchor2ref[a] = r
        end
      end

      def anchor_ref_replacement(ref)
        @anchor2ref[ref[1...ref.size]] || ref
      end
    end

    # Represents path with fixed parts and variables.
    class ServerPath
      # Probably moves to a separate file once processpaths and frequencies receive
      # some attention.
      include Comparable

      attr_accessor :parts

      def initialize(parts)
        @parts = parts
      end

      # Variables are after fixed strings.
      def <=>(other)
        pp = other.is_a?(Array) ? other : p.parts
        parts.each_index do |k|
          return 1 if pp.size <= k # Longer comes after shorter.
          pk = parts[k]
          ppk = pp[k]
          if pk.is_a? String
            if ppk.is_a? String
              c = pk <=> ppk
            else
              return -1
            end
          else
            if ppk.is_a? String
              return 1
            else
              c = pk.fetch('var', '') <=> ppk.fetch('var', '')
            end
          end
          return c unless c.zero?
        end
        (parts.size < pp.size) ? -1 : 0
      end

      # Not fit for sorting. Variable equals anything.
      def compare(p, range = nil)
        pp = p.is_a?(Array) ? p : p.parts
        if range.nil?
          range = 0...parts.size
        elsif range.is_a? Number
          range = range...(range + 1)
        end
        range.each do |k|
          return 1 if pp.size <= k # Longer comes after shorter.
          ppk = pp[k]
          next unless ppk.is_a? String
          pk = parts[k]
          next unless pk.is_a? String
          c = pk <=> ppk
          return c unless c.zero?
        end
        (parts.size < pp.size) ? -1 : 0
      end
    end
  end
end
