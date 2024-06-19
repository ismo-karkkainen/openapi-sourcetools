# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'
require_relative 'helper'


module Gen
  def self.mod_attr_reader(symbol, docstr = nil)
    attr_reader(symbol)
    module_function(symbol)
    return if docstr.nil?
    @docsrc = [] unless Gen.instance_variable_defined?('@docsrc')
    @docsrc.push("- #{symbol.to_s} : #{docstr}")
  end

  def self.mod_attr_accessor(symbol, docstr = nil)
    attr_accessor(symbol)
    module_function(symbol)
    s = symbol.to_s
    module_function((s + '=').to_sym)
    return if docstr.nil?
    @docsrc = [] unless Gen.instance_variable_defined?('@docsrc')
    @docsrc.push("- #{s} : #{docstr}")
  end

  mod_attr_reader :doc, 'OpenAPI document.'
  mod_attr_reader :outdir, 'Output directory name.'
  mod_attr_accessor :in_name, 'OpenAPI document name, nil if stdin.'
  mod_attr_accessor :in_basename, 'OpenAPI document basename, nil if stdin.'
  mod_attr_accessor :tasks, 'Tasks array.'
  mod_attr_accessor :g, 'Hash for storing values visible to all tasks.'
  mod_attr_accessor :a, 'Intended for instance with defined attributes.'
  mod_attr_accessor :h, 'Instance of class with helper methods.'
  mod_attr_accessor :t, 'Current task instance.'
  mod_attr_accessor :task_index, 'Current task index.'
  mod_attr_accessor :loaders, 'Array of generator loader methods.'

  def self.setup(document_content, input_name, output_directory)
    @doc = document_content
    @outdir = output_directory
    if input_name.nil?
      @in_name = nil
      @in_basename = nil
    else
      @in_name = File.basename(input_name)
      @in_basename = File.basename(input_name, '.*')
    end
    @tasks = []
    @g = {}
    @a = nil
    @h = nil
    @t = nil
    @task_index = nil
    @loaders = []
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
