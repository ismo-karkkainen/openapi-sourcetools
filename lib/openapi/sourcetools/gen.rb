# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'
require_relative 'helper'
require_relative 'docs'
require_relative 'output'
require_relative 'config'
require 'deep_merge'
require 'singleton'

# The generation module that contains things visible to tasks.
class Gen
  include Singleton

  @docsrc = []
  def self.add_doc(symbol, docstr)
    @docsrc.push("- #{symbol} : #{docstr}")
  end
  private_class_method :add_doc

  def self.attrib_reader(symbol, docstr, initial_value = nil)
    add_doc(symbol, docstr)
    attr_reader(symbol)
    instance_eval("def #{symbol}; Gen.instance.#{symbol}; end")
    Gen.instance.instance_variable_set("@#{symbol}", initial_value) unless initial_value.nil?
  end
  private_class_method :attrib_reader

  def self.attrib_accessor(symbol, docstr, initial_value = nil)
    add_doc(symbol, docstr)
    attr_accessor(symbol)
    instance_eval("def #{symbol}; Gen.instance.#{symbol}; end")
    instance_eval("def #{symbol}=(v); Gen.instance.#{symbol} = v; end")
    Gen.instance.instance_variable_set("@#{symbol}", initial_value) unless initial_value.nil?
  end
  private_class_method :attrib_accessor

  attrib_reader :doc, 'OpenAPI document.'
  attrib_reader :outdir, 'Output directory name.'
  attrib_reader :d, 'Other documents object.', OpenAPISourceTools::Docs.new
  attrib_reader :wd, 'Original working directory', Dir.pwd
  attrib_reader :configuration, 'Generator internal configuration'
  attrib_accessor :config, 'Configuration file name for next gem or Ruby file.'
  attrib_accessor :separator, 'Key separator in config file names.'
  attrib_accessor :in_name, 'OpenAPI document name, nil if stdin.'
  attrib_accessor :in_basename, 'OpenAPI document basename, nil if stdin.'
  attrib_reader :g, 'Hash for storing values visible to all tasks.', {}
  attrib_accessor :x, 'Hash for storing values visible to tasks from processor.', {}
  attrib_accessor :h, 'Instance of class with helper methods.'
  attrib_accessor :tasks, 'Tasks array.', []
  attrib_accessor :t, 'Current task instance.'
  attrib_accessor :task_index, 'Current task index.'
  attrib_accessor :loaders, 'Array of processor loader methods.', []
  attrib_accessor :output, 'Output-formatting helper.', OpenAPISourceTools::Output.new

  def self.load_config(name_prefix, extensions = [ '.*' ])
    cfg = {}
    cfgs = OpenAPISourceTools::ConfigLoader.find_files(name_prefix:, extensions:)
    cfgs = OpenAPISourceTools::ConfigLoader.read_contents(cfgs)
    cfgs.each { |c| cfg.deep_merge!(c) }
    cfg
  end

  def setup(document_content, input_name, output_directory, config_prefix)
    @doc = document_content
    @outdir = output_directory
    unless input_name.nil?
      @in_name = File.basename(input_name)
      @in_basename = File.basename(input_name, '.*')
    end
    @configuration = Gen.load_config(config_prefix)
    add_task(task: OpenAPISourceTools::HelperTask.new)
  end

  def self.setup(document_content, input_name, output_directory, config_prefix)
    Gen.instance.setup(document_content, input_name, output_directory, config_prefix)
  end

  def add_task(task:, name: nil, executable: false, x: nil)
    @tasks.push(task)
    # Since this method allows the user to pass their own task type instance,
    # assign optional values with defaults only when clearly given.
    @tasks.last.name = name unless name.nil?
    @tasks.last.executable = executable unless executable == false
    @tasks.last.x = x unless x.nil?
  end

  def self.add_task(task:, name: nil, executable: false, x: nil)
    Gen.instance.add_task(task:, name:, executable:, x:)
  end

  def add_write_content(name:, content:, executable: false)
    add_task(task: OpenAPISourceTools::WriteTask.new(name, content, executable))
  end

  def self.add_write_content(name:, content:, executable: false)
    Gen.instance.add_write_content(name:, content:, executable:)
  end

  def add(source:, template: nil, template_name: nil, name: nil, executable: false, x: nil)
    add_task(task: OpenAPISourceTools::Task.new(source, template, template_name),
      name:, executable:, x:)
  end

  def self.add(source:, template: nil, template_name: nil, name: nil, executable: false, x: nil)
    Gen.instance.add(source:, template:, template_name:, name:, executable:, x:)
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
