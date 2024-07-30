# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'


class Output
  # For indentation.
  attr_accessor :indent_character, :indent_step
  attr_accessor :tab, :tab_replaces_count
  attr_accessor :last_indent

  def initialize
    @indent_character = ' '
    @indent_step = 4
    @tab = "\t"
    @tab_replaces_count = 0
    @last_indent = 0
  end

  def join(blocks, separator = "\n")
    indented = []
    blocks.flatten!
    indent = 0
    blocks.each do |block|
      if block.nil?
        indent = 0
      elsif block.is_a?(Integer)
        indent += block
      elsif block.is_a?(TrueClass)
        indent += @indent_step
      elsif block.is_a?(FalseClass)
        indent -= @indent_step
      else
        block = block.to_s unless block.is_a?(String)
        if indent.zero?
          indented.push(block)
          next
        end
        if 0 < @tab_replaces_count
          tabs = @tab * (indent / @tab_replaces_count)
          chars = @indent_character * (indent % @tab_replaces_count)
        else
          tabs = ''
          chars = @indent_character * indent
        end
        lines = block.lines(chomp: true)
        lines.each do |line|
          indented.push("#{tabs}#{chars}#{line}")
        end
      end
    end
    @last_indent = indent
    indented.join(separator)
  end
end
