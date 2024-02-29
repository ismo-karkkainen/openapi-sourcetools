# frozen_string_literal: true

require_relative './common'

class PathOperation
  attr_accessor :path, :operation, :info, :parameters
  attr_accessor :servers, :security, :tags
  attr_accessor :summary, :description
end

# Component storage. Schemas separately?
# Anything that can be referenced should be fed to component storage and
# original reference replaced with object reference?
# Or, component storage is the one that knows what class to use in each case.
# Hence always pass the value to components and it can return an instance of
# the proper class.
# Some pairs like paths and operation object are handled as they are.
# Also webhooks look like path info object, basically.

# Perhaps have a mapping from field name to handler method that creates
# objects into storages. Each uses the same mapping to deal with children
# they do not handle directly?

# Should mapping JSON schema types to native types be a separate step?
# Just add x-openapi-sourcetools-native: nativetype
# Separate program that can pipe modified spec out to code generation?

# JSON schema is way too complex to simplify here. One could have a convenience
# method that determines how many bytes the value needs, and if it needs to be
# signed.

# When creating types for schemas or otherwise, the type name can be added
# into the item and that way be used as an indicator that the type has been
# declared or needs a declaration.

# Digging inline-defined things that should be types means a template will
# need to go through the entire document. That probably should be avoided and
# a scan for inline types done and implicit refs created. Inline types are
# replaced with the ref and the inline type processing should be recursive.
# Once we know what the content is, the type can be compared to existing ones
# and previously seen one used. Hence recursive checking of sub-types is
# done first.

# So, if a type has multiple properties, each property is a type, possibly
# the same as the other types. Create a situation where ref use is maximized.

# Using already existing schemas implies the components scan is done fully
# and loops in references must be flagged as invalid and error produced only
# when the type is actually used. Inline types can not have loops so leaf
# properties will either find an existing non-referencing type or create a
# new type. Hence inline types will not pull in loops.

# If user does not like the generated type names, the types can be declared
# explicitly.

# One option would be to perform the inline type creation and output the
# resulting components object as is to save work from the user.

# The inline and flattening to the maximum degree could be a separate
# program. The output might be useful in its own right.

class ComponentStore
  attr_reader :objects
  attr_reader :spec

  def init(components)
    @objects = {}
    @spec = components
  end

  def get(ref, preceding = [])
    ref = "#/components/securitySchemes/#{ref}" unless ref.start_with?('#/components/')
    obj = @objects.fetch(ref, nil)
    obj = create_object(ref, preceding) if obj.nil?
    obj
  end

private
  def check_loop(ref, preceding)
    return unless preceding.include?(ref)
    msg = "Loop with #{ref} in:\n" + ref.reverse.join("\n")
    aargh(msg, 3)
  end

  def create_object(ref, preceding)
    check_loop(ref, preceding)
    parts = ref.split('/')
    parts.shift(1) if parts.first == '#'
    category = parts[parts.size - 2]
    name = parts.last
    # Get the doc and get referenced objects to create them.
    doc = @spec.dig(*parts)
    return nil if doc.nil?
    # Require that inlined types have been dealt with already.
    # Inlined type here would be second-level object or an array.
    # Inlined type at caller is top-level object or array.
    # Possibly better to figure out what to make a ref here. Clear.
    preceding.push(ref)
    case category
    when 'schemas' then out = create_schema(doc, name, preceding)
    when 'responses' then out = create_response(doc, name, preceding)
    when 'parameters' then out = create_parameter(doc, name, preceding)
    when 'requestBodies' then out = create_request_body(doc, name, preceding)
    # Headers is limited parameters.
    when 'headers' then out = create_header(doc, name, preceding)
    # Callbacks is like pathItems but should be limited to path item.
    when 'callbacks' then out = create_callback(doc, name, preceding)
    when 'pathItems' then out = create_path_item(doc, name, preceding)
    else # examples, securitySchemes, links
      out = doc
    end
    preceding.pop
    @objects[ref] = out
    out
  end

  def create_schema(doc, name, preceding)
  end

  def create_response(doc, name, preceding)
  end

  def create_parameter(doc, name, preceding)
  end

  def create_request_body(doc, name, preceding)
  end

  def create_header(doc, name, preceding)
  end

  def create_callback(doc, name, preceding)
  end

  def create_path_item(doc, name, preceding)
  end
end

def make_path_operations(apidoc)
  # Check openapi
  # Store info as is for reference
  # Store servers as is for default value for PathOperation
  # Process components. Lazy manner, only when referenced.
  # Every time a component is referenced and the object is asked, resolve all
  # references to sub-items and create the objects.
  # Store security as is for default value for PathOperation.
  # Store tags as mapping from name to object for use with PathOperation.
  # Process paths:
  # Store parameters as is for default value for PathOperation.
  # All other fields, check if it looks like OperationObject and create a
  # PathOperation using it. For others, store as is for default value.

end


ServerPath = Struct.new(:parts) do
  def <=>(p) # Variables are after fixed strings.
    pp = p.is_a?(Array) ? p : p.parts
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
