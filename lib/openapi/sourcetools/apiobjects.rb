# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

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

    # Any value with given key has all but retained keys removed.
    class ValueRetainer
      attr_reader :key
      attr_accessor :retain

      def initialize(trigger_key)
        @key = trigger_key
        @retain = [ trigger_key ]
      end

      def process(obj)
        if obj.is_a?(Array)
          obj.each { |item| process(item) }
          return
        end
        return unless obj.is_a?(Hash)
        if obj.key?(@key)
          obj.delete_if { |k, _v| !@retain.include?(k) }
        end
        obj.each_value do |value|
          process(value)
        end
      end
    end

    # A replacer for value of a given key.
    class ValueReplacer
      attr_reader :key, :components

      def initialize(trigger_key, components)
        @key = trigger_key
        @components = components
      end

      def replace(obj)
        if obj.is_a?(Array)
          obj.each { |item| replace(item) }
          return
        end
        return unless obj.is_a?(Hash)
        obj.each do |key, value|
          if key == @key
            if value.is_a?(Array)
              value.each do |item|
                next unless item.is_a?(Hash)
                next if item.key?('$ref')
                @components.to_reference_object(item)
              end
            elsif value.is_a?(Hash)
              next if value.key?('$ref')
              @components.to_reference_object(value)
            end
          else
            replace(value)
          end
        end
      end
    end

    # A replacer for sub-values of a value of a given key.
    class ValueSubValueReplacer
      attr_reader :key, :components

      def initialize(trigger_key, components)
        @key = trigger_key
        @components = components
      end

      def replace(obj)
        if obj.is_a?(Array)
          obj.each { |item| replace(item) }
          return
        end
        return unless obj.is_a?(Hash)
        obj.each do |key, value|
          if key == @key && value.is_a?(Hash)
            value.keys.sort!.each do |sub_key|
              sub_value = value[sub_key]
              next unless sub_value.is_a?(Hash)
              next if sub_value.key?('$ref')
              @components.to_reference_object(value[sub_key])
            end
          else
            replace(value)
          end
        end
      end
    end

    # A component in the API specification for reference and anchor handling.
    class Components
      attr_reader :path, :prefix, :anchor2ref, :schema_names
      attr_accessor :items, :ignored_keys, :retain_ignored

      def initialize(path, prefix, ignored_keys = %w[summary description examples example $anchor])
        path = "#/#{path.join('/')}/" if path.is_a?(Array)
        path = "#{path}/" unless path.end_with?('/')
        @path = path
        @prefix = prefix
        @anchor2ref = {}
        @schema_names = Set.new
        @items = {}
        @ignored_keys = Set.new(ignored_keys)
        @retain_ignored = false
      end

      def add_options(opts)
        opts.on('--use FIELD', 'Use FIELD in comparisons.') do |f|
          @ignored_keys.delete(f)
        end
        opts.on('--ignore FIELD', 'Ignore FIELD in comparisons.') do |f|
          @ignored_keys.add(f)
        end
        opts.on('--retain-ignored', 'Retain ignored fields in reference object.') do
          @retain_ignored = true
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

      def to_reference_object(obj, ref = nil)
        ref = reference(obj) if ref.nil?
        if @retain_ignored
          obj.delete_if { |k, _v| !@ignored_keys.member?(k) }
        else
          obj.clear
        end
        obj['$ref'] = ref
        obj
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

      # Parameters are after fixed strings.
      def <=>(other)
        pp = other.is_a?(Array) ? other : other.parts
        @parts.size.times do |k|
          return 1 if pp.size <= k # Longer comes after shorter.
          pk = @parts[k]
          ppk = pp[k]
          if pk.key?('fixed')
            if ppk.key?('fixed')
              c = pk['fixed'] <=> ppk['fixed']
            else
              return -1
            end
          else
            if ppk.key?('fixed')
              return 1
            else
              c = pk.fetch('parameter', '') <=> ppk.fetch('parameter', '')
            end
          end
          return c unless c.zero?
        end
        (@parts.size < pp.size) ? -1 : 0
      end

      # Not fit for sorting. Variable equals anything.
      def compare(other, range = nil)
        pp = other.is_a?(Array) ? other : other.parts
        if range.nil?
          range = 0...@parts.size
        elsif range.is_a? Number
          range = range...(range + 1)
        end
        range.each do |k|
          return 1 if pp.size <= k # Longer comes after shorter.
          ppk = pp[k]
          next unless ppk.key?('fixed')
          pk = parts[k]
          next unless pk.key?('fixed')
          c = pk['fixed'] <=> ppk['fixed']
          return c unless c.zero?
        end
        (@parts.size < pp.size) ? -1 : 0
      end
    end

    def self.operation_objects(path_item)
      keys = %w[operationId requestBody responses callbacks]
      out = {}
      path_item.each do |method, op|
        next unless op.is_a?(Hash)
        keys.each do |key|
          next unless op.key?(key)
          out[method] = op
          break
        end
      end
      out
    end

    # Single server variable object.
    class ServerVariableObject
      include Comparable

      attr_reader :name, :default, :enum

      def initialize(name, variable_object)
        @name = name
        @default = variable_object['default']
        @enum = (variable_object['enum'] || []).sort!
      end

      def <=>(other)
        d = @name <=> other.name
        return d unless d.zero?
        d = @default <=> other.default
        return d unless d.zero?
        @enum <=> other.enum
      end
    end

    # Single server object with variables.
    class ServerObject
      include Comparable

      attr_reader :url, :variables

      def initialize(server_object)
        @url = server_object['url']
        vs = server_object['variables'] || {}
        @variables = vs.keys.sort!.map do |name|
          obj = vs[name]
          ServerVariableObject.new(name, obj)
        end
      end

      def <=>(other)
        d = @url <=> other.url
        return d unless d.zero?
        if @variables.nil? || other.variables.nil?
          return -1 if @variables.nil?
          return 1 if other.variables.nil?
        end
        @variables <=> other.variables
      end
    end

    # Combines servers array with set identifier.
    class ServerAlternatives
      include Comparable

      attr_reader :servers
      attr_accessor :set_id

      def initialize(server_objects)
        @servers = server_objects.map { |so| ServerObject.new(so) }
        @servers.sort!
      end

      def <=>(other)
        @servers <=> other.servers
      end
    end

    # Simple holder if security scheme objects.
    class SecurityScheme
      include Comparable

      attr_reader :name, :scheme

      def initialize(name, scheme)
        @name = name
        @scheme = scheme
      end

      def <=>(other)
        @name <=> other.name
      end
    end

    # Simple holder that determines where parameters are placed.
    class SecurityRequirementObject
      include Comparable

      attr_reader :reqs, :extras

      def initialize(reqs, schemes)
        @reqs = reqs
        @extras = {}
        @reqs.each do |name, scopes|
          scheme = schemes[name].scheme
          case scheme['type']
          when 'apiKey'
            if scheme['in'] == 'header'
              h = @extras[:headers] || {}
              h[scheme['name']] = scopes
              @extras[:headers] = h
            elsif scheme['in'] == 'query'
              q = @extras[:query] || {}
              q[scheme['name']] = scopes
              @extras[:query] = q
            end
          when 'http', 'oauth2', 'openIdConnect'
            h = @extras[:headers] || {}
            h['authorization'] = scopes
            @extras[:headers] = h
          else
            raise "Unknown security type: #{scheme['type']} for #{name}"
          end
        end
      end

      def <=>(other)
        d = @reqs.size <=> other.reqs.size
        return d unless d.zero?
        d = @reqs.keys.sort! <=> other.reqs.keys.sort!
        return d unless d.zero?
        @reqs.keys.sort!.each do |name|
          d = @reqs[name].sort <=> other.reqs[name].sort
          return d unless d.zero?
        end
        0
      end
    end

    # Available possibilities.
    class SecurityAlternatives
      include Comparable

      attr_reader :sros, :schemes
      attr_accessor :set_id

      def initialize(sros, schemes)
        @sros = sros
        @schemes = schemes
      end

      def <=>(other)
        @sros.sort <=> other.sros.sort
      end
    end
  end
end
