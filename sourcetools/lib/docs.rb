# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'common'


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

  def add(name, content)
    return false if docs.key?(name)
    @docs[name] = content
    true
  end
end
