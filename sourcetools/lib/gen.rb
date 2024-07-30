# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'
require_relative 'helper'
require_relative 'docs'
require_relative 'output'


module Gen
  def self.add_doc(symbol, docstr)
    return if docstr.nil?
    @docsrc = [] unless instance_variable_defined?('@docsrc')
    @docsrc.push("- #{symbol.to_s} : #{docstr}")
  end

  def self.read_attr(symbol, default)
    return if symbol.nil?
    attr_reader(symbol)
    module_function(symbol)
    instance_variable_set("@#{symbol.to_s}", default)
  end

  def self.mod_attr2_reader(symbol, symbol2, docstr = nil, default = nil)
    read_attr(symbol, default)
    read_attr(symbol2, default)
    add_doc(symbol, docstr)
  end

  def self.mod_attr_reader(symbol, docstr = nil, default = nil)
    mod_attr2_reader(symbol, nil, docstr, default)
  end

  def self.rw_attr(symbol, default)
    attr_accessor(symbol)
    module_function(symbol)
    s = symbol.to_s
    module_function((s + '=').to_sym)
    instance_variable_set("@#{s}", default)
  end

  def self.mod_attr2_accessor(symbol, symbol2, docstr = nil, default = nil)
    rw_attr(symbol, default)
    rw_attr(symbol2, default) unless symbol2.nil?
    add_doc(symbol, docstr)
  end

  def self.mod_attr_accessor(symbol, docstr = nil, default = nil)
    mod_attr2_accessor(symbol, nil, docstr, default)
  end

  mod_attr_reader :doc, 'OpenAPI document.'
  mod_attr_reader :outdir, 'Output directory name.'
  mod_attr_reader :d, 'Other documents object.', Docs.new
  mod_attr_accessor :in_name, 'OpenAPI document name, nil if stdin.'
  mod_attr_accessor :in_basename, 'OpenAPI document basename, nil if stdin.'
  mod_attr_accessor :tasks, 'Tasks array.', []
  mod_attr_accessor :g, 'Hash for storing values visible to all tasks.', {}
  mod_attr_accessor :a, 'Intended for instance with defined attributes.'
  mod_attr_accessor :h, 'Instance of class with helper methods.'
  mod_attr2_accessor :task, :t, 'Current task instance.'
  mod_attr_accessor :task_index, 'Current task index.'
  mod_attr_accessor :loaders, 'Array of generator loader methods.', []
  mod_attr2_accessor :output, :o, 'Output-related methods.', Output.new

  def self.setup(document_content, input_name, output_directory)
    @doc = document_content
    @outdir = output_directory
    unless input_name.nil?
      @in_name = File.basename(input_name)
      @in_basename = File.basename(input_name, '.*')
    end
    add_task(task: HelperTask.new)
  end

  def self.add_task(task:, name: nil, executable: false, x: nil)
    @tasks.push(task)
    # Since this method allows the user to pass their own task type instance,
    # assign optional values with defaults only when clearly given.
    @tasks.last.name = name unless name.nil?
    @tasks.last.executable = executable unless executable == false
    @tasks.last.x = x unless x.nil?
  end

  def self.add_write_content(name:, content:, executable: false)
    add_task(task: WriteTask.new(name, content, executable))
  end

  def self.add(source:, template: nil, template_name: nil, name: nil, executable: false, x: nil)
    add_task(task: Task.new(source, template, template_name), name: name, executable: executable, x: x)
  end

  def self.document
    @docsrc.join("\n") + %(
- add_task(task:, name: nil, executable: false, x: nil) : Adds task object.
- add_write_content(name:, content:, executable: false) : Add file write task.
- add(source:, template: nil, template_name: nil, name: nil,
    executable: false, x: nil) :
  Adds template task with source as object to process.
)
  end
end
