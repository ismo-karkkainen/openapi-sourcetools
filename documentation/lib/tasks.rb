# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

# Namespace for functions with supposedly only internal use.
module OpenAPISourceToolsDocumentation
  def self.template_directory
    File.join(File.dirname(__FILE__), '..', 'template')
  end
  private_class_method :template_directory

  FIRST = 'SETUP.ERB'

  def self.template_names
    erbs = Dir.entries(template_directory).select { |name| name.upcase.end_with?('.ERB') }
    first = erbs.select { |name| name.upcase == FIRST }
    others = erbs.reject { |name| name.upcase == FIRST }
    first.concat(others.sort!)
  end

  def self.write_content_names
    o = Dir.entries(template_directory).reject do |name|
      name.upcase.end_with?('.ERB') || File.directory?(File.join(template_directory, name))
    end
    o.sort!
  end

  def self.load(name)
    File.read(File.join(template_directory, name))
  end

  NAME = 'openapi-sourcetools-documentation'
  VERSION = '0.1.0'
end

# Runs when the gem is loaded from openapi-generate.
unless defined?(Gen).nil?
  OpenAPISourceToolsDocumentation.template_names.each do |name|
    t = OpenAPISourceToolsDocumentation.load(name)
    Gen.add(source: Gen.doc, template: t, template_name: name)
  end
  OpenAPISourceToolsDocumentation.write_content_names.each do |name|
    Gen.add_write_content(name: name,
      content: OpenAPISourceToolsDocumentation.load(name))
  end
  Gen.g['gem_name'] = OpenAPISourceToolsDocumentation::NAME
  Gen.g['gem_version'] = OpenAPISourceToolsDocumentation::VERSION
end
