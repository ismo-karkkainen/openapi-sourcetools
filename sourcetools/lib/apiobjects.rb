# frozen_string_literal: true

require_relative './common'
require 'set'

def same(a, b, ignored_keys = Set.new(%w[summary description]))
  return a == b unless a.is_a?(Hash) && b.is_a?(Hash)
  keys = Set.new(a.keys + b.keys) - ignored_keys
  keys.to_a.each do |k|
    return false unless a.key?(k) && b.key?(k)
    return false unless same(a[k], b[k], ignored_keys)
  end
  true
end

def ref_string(name, schema_path)
  "#{schema_path}/#{name}"
end

def reference(obj, schemas, schema_path, ignored_keys = Set.new(%w[summary description]), prefix = 'Schema')
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
      return ref_string(k) if same(obj, v, @ignored_keys)
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
    raise Exception, 'ref is nil and no $ref or it is nil' if ref.nil?
    @anchor2ref[anchor_name] = ref
  end

  def alter_anchors
    replacements = {}
    @anchor2ref.each do |a, r|
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

class ServerPath
  # Probably moves to a separate file once processpaths and frequencies receive
  # some attention.
  include Comparable

  attr_accessor :parts

  def initialize(parts)
    @parts = parts
  end

  def <=>(other) # Variables are after fixed strings.
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

  def compare(p, range = nil) # Not fit for sorting. Variable equals anything.
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

# The rest probably ends up in a gem that orders schemas and does nothing else.

# Adds all refs found in the array to refs with given required state.
def gather_array_refs(refs, items, required)
  items.each do |s|
    r = s['$ref']
    next if r.nil?
    refs[r] = required || refs.fetch(r, false)
  end
end

# For any key '$ref' adds to refs whether referred type is required.
# Requires that there are no in-lined schemas, openapi-addschemas has been run.
def gather_refs(refs, schema)
  # This implies types mixed together according to examples. Needs mixed type.
  # AND. Also, mixing may fail. Adds a new schema, do here.
  items = schema['allOf']
  return gather_array_refs(refs, items, true) unless items.nil?
  # As long as one schema is fulfilled, it is ok. OR, first that fits.
  items = schema['anyOf'] if items.nil?
  # oneOf implies selection between different types. No multiple matches. XOR.
  # Needs to ensure that later types do not match.
  # Should check if there is enough difference to ensure single match.
  # Use separate program run after addschemas to create allOf mixed schema
  # and verify the others can be dealt with.
  items = schema['oneOf'] if items.nil?
  return gather_array_refs(refs, items, false) unless items.nil?
  # Defaults below handle it if "type" is not "object".
  reqs = schema.fetch('required', [])
  schema.fetch('properties', {}).each do |name, spec|
    r = spec['$ref']
    next if r.nil?
    refs[r] = reqs.include?(name) || refs.fetch(r, false)
  end
end

class SchemaInfo
  attr_accessor :ref, :schema, :direct_refs, :name, :post_refs

  def initialize(ref, name, schema)
    @ref = ref
    @name = name
    @schema = schema
    @direct_refs = {}
    gather_refs(@direct_refs, schema)
  end

  def set_post_refs(seen)
    @post_refs = Set.new(@direct_refs.keys) - seen
  end

  def to_s
    v = @direct_refs.keys.sort.map { |k| "#{k}:#{@direct_refs[k] ? 'req' : 'opt'}" }
    "#{@ref}: #{v.join(' ')}"
  end
end

def var_or_method_value(x, name)
  if name.start_with?('@')
    n = name
  else
    n = "@#{name}"
  end
  return x.instance_variable_get(n) if x.instance_variable_defined?(n)
  return x.public_send(name) if x.respond_to?(name)
  raise ArgumentError, "#{name} is not #{x.class} instance variable nor public method"
end

class SchemaOrderer
  attr_accessor :schemas, :order, :orderer

  def initialize(path, schema_specs)
    @schemas = {}
    schema_specs.each do |name, schema|
      r = "#{path}#{name}"
      @schemas[r] = SchemaInfo.new(r, name, schema)
    end
  end

  def sort!(orderer = 'required_first')
    case orderer
    when 'required_first' then @order = required_first
    when '<=>' then @order = @schemas.values.sort { |a, b| a <=> b }
    else
      @order = @schemas.values.sort do |a, b|
        va = var_or_method_value(a, orderer)
        vb = var_or_method_value(b, orderer)
        va <=> vb
      end
    end
    @orderer = orderer
    seen = Set.new
    @order.each do |si|
      si.set_post_refs(seen)
      seen.add(si.ref)
    end
    @order
  end

  def required_first
    chosen = []
    until chosen.size == @schemas.size
      used = Set.new(chosen.map { |si| si.ref })
      avail = @schemas.values.select { |si| !used.member?(si.ref) }
      best = nil
      avail.each do |si|
        prereq = chosen.count { |x| x.direct_refs.fetch(si.ref, false) }
        fulfilled = chosen.count { |x| si.direct_refs.fetch(x.ref, false) }
        postreq = si.direct_refs.size - (prereq + fulfilled)
        better = false
        if best.nil?
          better = true
        else
          # Minimize preceding types requiring this.
          if prereq < best.first
            better = true
          elsif prereq == best.first
            # Minimize remaining unfulfilled requires.
            if postreq < best[1]
              better = true
            elsif postreq == best[1]
              # Check mutual direct requirements.
              best_req_si = best.last.direct_refs.fetch(si.ref, false)
              si_req_best = si.direct_refs.fetch(best.last.ref, false)
              if best_req_si
                better = true unless si_req_best
              end
              # Order by name if no other difference.
              better = si.ref < best.last.ref unless better
            end
          end
        end
        best = [ prereq, postreq, si ] if better
      end
      chosen.push(best.last)
    end
    chosen
  end
end
