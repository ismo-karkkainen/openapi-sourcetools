# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'


# Original loader functions. These are accessible via Gen.loaders. New loaders
# should be added there.
module OpenAPISourceTools
  # Loaders used to load gems and files and set config etc.
  # Exposed as Gen.loaders if you need to modify the array.
  module Loaders
    # Prefix etc. and loader pairs for all loaders.

    REQ_PREFIX = 'req:'

    def self.req_loader(name)
      return false unless name.downcase.start_with?(REQ_PREFIX)
      begin
        t = OpenAPISourceTools::RestoreProcessorStorage.new({})
        Gen.tasks.push(t)
        base = name.slice(REQ_PREFIX.size...name.size)
        require(base)
        Gen.config = nil
        t.x = Gen.x # In case setup code replaced the object.
      rescue LoadError => e
        raise StandardError, "Failed to require #{name}\n#{e}"
      rescue Exception => e
        raise StandardError, "Problem with #{name}\n#{e}\n#{e.backtrace.join("\n")}"
      end
      true
    end

    REREQ_PREFIX = 'rereq:'

    def self.rereq_loader(name)
      return false unless name.downcase.start_with?(REREQ_PREFIX)
      begin
        t = OpenAPISourceTools::RestoreProcessorStorage.new({})
        Gen.tasks.push(t)
        code = name.slice(REREQ_PREFIX.size...name.size)
        eval(code)
        Gen.config = nil
        t.x = Gen.x # In case setup code replaced the object.
      rescue LoadError => e
        raise StandardError, "Failed to require again #{name}\n#{e}"
      rescue Exception => e
        raise StandardError, "Problem with #{name}\n#{e}\n#{e.backtrace.join("\n")}"
      end
      true
    end

    RUBY_EXT = '.rb'

    def self.ruby_loader(name)
      return false unless name.downcase.end_with?(RUBY_EXT)
      origwd = Dir.pwd
      d = File.dirname(name)
      Dir.chdir(d) unless d == '.'
      begin
        t = OpenAPISourceTools::RestoreProcessorStorage.new({})
        Gen.tasks.push(t)
        base = File.basename(name)
        Gen.config = base[0..-4] if Gen.config.nil?
        require(File.join(Dir.pwd, base))
        Gen.config = nil
        t.x = Gen.x # In case setup code replaced the object.
      rescue LoadError => e
        raise StandardError, "Failed to require #{name}\n#{e}"
      rescue Exception => e
        raise StandardError, "Problem with #{name}\n#{e}\n#{e.backtrace.join("\n")}"
      end
      Dir.chdir(origwd) unless d == '.'
      true
    end

    YAML_PREFIX = 'yaml:'
    YAML_EXTS = [ '.yaml', '.yml' ].freeze

    def self.yaml_loader(name)
      d = name.downcase
      if d.start_with?(YAML_PREFIX)
        name = name.slice(YAML_PREFIX.size...name.size)
      elsif (YAML_EXTS.index { |s| d.end_with?(s) }).nil?
        return false
      end
      n, _sep, f = name.partition(':')
      raise StandardError, 'No name given.' if n.empty?
      raise StandardError, 'No filename given.' if f.empty?
      doc = YAML.safe_load_file(f)
      raise StandardError, "#{name} #{n} exists already." unless Gen.d.add(n, doc)
      true
    rescue Errno::ENOENT
      raise StandardError, "Not found: #{f}\n#{e}"
    rescue Exception => e # Whatever was raised, we want it.
      raise StandardError, "Failed to read as YAML: #{f}\n#{e}"
    end

    BIN_PREFIX = 'bin:'

    def self.bin_loader(name)
      return false unless name.downcase.start_with?(BIN_PREFIX)
      n, _sep, f = name.slice(BIN_PREFIX.size...name.size).partition(':')
      raise StandardError, 'No name given.' if n.empty?
      raise StandardError, 'No filename given.' if f.empty?
      doc = File.binread(f)
      raise StandardError, "#{name} #{n} exists already." unless Gen.d.add(n, doc)
      true
    rescue Errno::ENOENT
      raise StandardError, "Not found: #{f}\n#{e}"
    rescue Exception => e # Whatever was raised, we want it.
      raise StandardError, "Failed to read #{f}\n#{e}"
    end

    CONFIG_PREFIX = 'config:'

    def self.config_loader(name)
      return false unless name.downcase.start_with?(CONFIG_PREFIX)
      raise StandardError, "Config name remains: #{Gen.config}" unless Gen.config.nil?
      n = name.slice(CONFIG_PREFIX.size...name.size)
      raise StandardError, 'No name given.' if n.empty?
      # Interpretation left completely to config loading.
      Gen.config = n
      true
    end

    SEPARATOR_PREFIX = 'separator:'

    def self.separator_loader(name)
      return false unless name.downcase.start_with?(SEPARATOR_PREFIX)
      n = name.slice(SEPARATOR_PREFIX.size...name.size)
      n = nil if n.empty?
      Gen.separator = n
      true
    end

    def self.loaders
      [
        method(:req_loader),
        method(:rereq_loader),
        method(:ruby_loader),
        method(:yaml_loader),
        method(:bin_loader),
        method(:config_loader),
        method(:separator_loader)
      ]
    end

    def self.document
      <<EOB
- #{Loaders::REQ_PREFIX}req_name : requires the gem.
- #{Loaders::REREQ_PREFIX}code : runs code to add gem tasks again.
- ruby_file#{Loaders::RUBY_EXT} : changes to Ruby file directory and requires the file.
- #{Loaders::YAML_PREFIX}name:filename : Loads YAML file into Gen.d.name.
- name:filename.{#{(Loaders::YAML_EXTS.map { |s| s[1...s.size] }).join('|')}} : Loads YAML file into Gen.d.name.
- #{Loaders::BIN_PREFIX}name:filename : Loads binary file into Gen.d.name.
- #{Loaders::CONFIG_PREFIX}name : Sets Gen.config for next gem/Ruby file configuration loading.
- #{Loaders::SEPARATOR_PREFIX}string : Sets Gen.separator to string.
EOB
    end
  end
end
