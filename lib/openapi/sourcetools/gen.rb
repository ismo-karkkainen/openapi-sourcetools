# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'
require_relative 'helper'
require_relative 'docs'
require_relative 'output'
require_relative 'config'
require 'deep_merge'


# The generation module that contains things visible to tasks.
module Gen
  def self.add_doc(symbol, docstr)
    return if docstr.nil?
    @docsrc = [] unless instance_variable_defined?('@docsrc')
    @docsrc.push("- #{symbol} : #{docstr}")
  end
  private_class_method :add_doc

  def self.read_attr(symbol, default)
    return if symbol.nil?
    attr_reader(symbol)
    module_function(symbol)
    instance_variable_set("@#{symbol}", default)
  end
  private_class_method :read_attr

  def self.mod_attr2_reader(symbol, symbol2, docstr = nil, default = nil)
    read_attr(symbol, default)
    read_attr(symbol2, default)
    add_doc(symbol, docstr)
  end
  private_class_method :mod_attr2_reader

  def self.mod_attr_reader(symbol, docstr = nil, default = nil)
    mod_attr2_reader(symbol, nil, docstr, default)
  end
  private_class_method :mod_attr_reader

  def self.rw_attr(symbol, default)
    attr_accessor(symbol)
    module_function(symbol)
    s = symbol.to_s
    module_function((s + '=').to_sym)
    instance_variable_set("@#{s}", default)
  end
  private_class_method :rw_attr

  def self.mod_attr2_accessor(symbol, symbol2, docstr = nil, default = nil)
    rw_attr(symbol, default)
    rw_attr(symbol2, default) unless symbol2.nil?
    add_doc(symbol, docstr)
  end
  private_class_method :mod_attr2_accessor

  def self.mod_attr_accessor(symbol, docstr = nil, default = nil)
    mod_attr2_accessor(symbol, nil, docstr, default)
  end
  private_class_method :mod_attr_accessor

  mod_attr_reader :doc, 'OpenAPI document.'
  mod_attr_reader :outdir, 'Output directory name.'
  mod_attr_reader :d, 'Other documents object.', OpenAPISourceTools::Docs.new
  mod_attr_reader :wd, 'Original working directory', Dir.pwd
  mod_attr_reader :configuration, 'Generator internal configuration'
  mod_attr_accessor :config, 'Configuration file name for next gem or Ruby file.'
  mod_attr_accessor :separator, 'Key separator in config file names.', nil
  mod_attr_accessor :in_name, 'OpenAPI document name, nil if stdin.'
  mod_attr_accessor :in_basename, 'OpenAPI document basename, nil if stdin.'
  mod_attr_reader :g, 'Hash for storing values visible to all tasks.', {}
  mod_attr_accessor :x, 'Hash for storing values visible to tasks from processor.', {}
  mod_attr_accessor :h, 'Instance of class with helper methods.'
  mod_attr_accessor :tasks, 'Tasks array.', []
  mod_attr2_accessor :task, :t, 'Current task instance.'
  mod_attr_accessor :task_index, 'Current task index.'
  mod_attr_accessor :loaders, 'Array of processor loader methods.', []
  mod_attr_accessor :output, 'Output-formatting helper.', OpenAPISourceTools::Output.new

  def self.load_config(config_prefix)
    cfg = {}
    cfgs = OpenAPISourceTools::ConfigLoader.find_files(name_prefix: config_prefix)
    cfgs = OpenAPISourceTools::ConfigLoader.read_contents(cfgs)
    cfgs.each { |c| cfg.deep_merge!(c) }
    cfg
  end
  private_class_method :load_config

  def self.setup(document_content, input_name, output_directory, config_prefix)
    @doc = document_content
    @outdir = output_directory
    unless input_name.nil?
      @in_name = File.basename(input_name)
      @in_basename = File.basename(input_name, '.*')
    end
    @configuration = load_config(config_prefix)
    add_task(task: OpenAPISourceTools::HelperTask.new)
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
    add_task(task: OpenAPISourceTools::WriteTask.new(name, content, executable))
  end

  def self.add(source:, template: nil, template_name: nil, name: nil, executable: false, x: nil)
    add_task(task: OpenAPISourceTools::Task.new(source, template, template_name),
      name:, executable:, x:)
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
