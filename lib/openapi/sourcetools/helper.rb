# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'

module OpenAPISourceTools
  # Helper class supposed to contain helpful methods.
  # Exposed as Gen.h if HelperTask has been run. It is automatically
  # added as the first task but later tasks can remove it.
  class Helper
    attr_reader :doc, :parents
    attr_accessor :parent_parameters

    # Stores the nearest Hash for each Hash.
    def store_parents(obj, parent = nil)
      if obj.is_a?(Hash)
        @parents[obj] = parent
        obj.each_value do |v|
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
      @parents = {}.compare_by_identity
      store_parents(@doc)
    end

    def parent(object)
      @parents[object]
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

    def response_codes(responses_object)
      responses_object.keys.sort! do |a, b|
        ad = a.downcase
        bd = b.downcase
        if ad == 'default'
          1
        elsif bd == 'default'
          -1
        else
          ax = ad.end_with?('x')
          bx = bd.end_with?('x')
          if ax && bx || !ax && !bx
            a <=> b # Both numbers or patterns.
          else
            ax ? 1 : -1
          end
        end
      end
    end

    def response_code_condition(code, var: 'code', op_and: '&&', op_lte: '<=', op_eq: '==')
      low = []
      high = []
      code.downcase.each_char do |c|
        if c == 'x'
          low.push('0')
          high.push('9')
        else
          low.push(c)
          high.push(c)
        end
      end
      low = low.join
      high = high.join
      if low == high
        "#{var} #{op_eq} #{low}"
      else
        "(#{low} #{op_lte} #{var}) #{op_and} (#{var} #{op_lte} #{high})"
      end
    end
  end

  # Task class to add an Helper instance to Gen.h, for convenience.
  class HelperTask
    include OpenAPISourceTools::TaskInterface

    def generate(_context_binding)
      Gen.h = Helper.new(Gen.doc) if Gen.h.nil?
    end

    def discard
      true
    end
  end
end
