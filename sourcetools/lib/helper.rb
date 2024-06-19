# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'


class Helper
  attr_reader :doc, :parents
  attr_accessor :parent_parameters

  # Stores the nearesh Hash for each Hash.
  def store_parents(obj, parent = nil)
    if obj.is_a?(Hash)
      @parents[obj.object_id] = parent
      obj.each do |k, v|
        store_parents(v, obj)
      end
    elsif obj.is_a?(Array)
      obj.each do |v|
        store_parents(v, parent)
      end
    end
  end

  def initialize(doc)
    @doc = doc
    # For each hash in doc, set parent?
    # Build an object_id to parent object mapping and use parent method?
    @parents = {}
    store_parents(@doc)
  end

  def parent(object)
    @parents[object.object_id]
  end

  COMPONENTS = '#/components/'

  def category_and_name(ref_or_obj)
    ref = ref_or_obj.is_a?(Hash) ? ref_or_obj['$ref'] : ref_or_obj
    return nil unless ref.is_a?(String)
    return nil unless ref.start_with?(Helper::COMPONENTS)
    idx = ref.index('/', Helper::COMPONENTS.size)
    return nil if idx.nil?
    category = ref[Helper::COMPONENTS.size...idx]
    [ category, ref[(idx + 1)...ref.size] ]
  end

  def dereference(ref_or_obj)
    cn = category_and_name(ref_or_obj)
    return nil if cn.nil?
    cs = @doc.dig('components', cn.first) || {}
    cs[cn.last]
  end

  def basename(ref_or_obj)
    cn = category_and_name(ref_or_obj)
    return nil if cn.nil?
    cn.last
  end

  def parameters(operation_object, empty_unless_local = false)
    return [] if empty_unless_local && !operation_object.key?('parameters')
    cps = @doc.dig('components', 'parameters') || {}
    uniqs = {}
    path_item_object = parent(operation_object)
    [path_item_object, operation_object].each do |p|
      p.fetch('parameters', []).each do |param|
        r = basename(param)
        r = cps[r] if r.is_a?(String)
        uniqs["#{r['name']}:#{r['in']}"] = param
      end
    end
    uniqs.keys.sort!.map { |k| uniqs[k] }
  end
end


class HelperTask
  include TaskInterface

  def generate(context_binding)
    Gen.h = Helper.new(Gen.doc)
  end

  def output_name
    nil
  end

  def discard
    true
  end
end

