# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.


# Original loader functions. These are accessible via Gen.loaders. New loaders
# should be added there.
module Loaders

  GEM_PREFIX = 'gem:'

  def self.gem_loader(name)
    return false unless name.downcase.start_with?(GEM_PREFIX)
    begin
      require(name.slice(GEM_PREFIX.size...name.size))
    rescue LoadError => e
      raise StandardError, "Failed to require #{name}\n#{e.to_s}"
    rescue Exception => e
      raise StandardError, "Problem with #{name}\n#{e.to_s}"
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
      require(File.join(Dir.pwd, File.basename(name)))
    rescue LoadError => e
      raise StandardError, "Failed to require #{name}\n#{e.to_s}"
    rescue Exception => e
      raise StandardError, "Problem with #{name}\n#{e.to_s}"
    end
    Dir.chdir(origwd) unless d == '.'
    true
  end

  YAML_PREFIX = 'yaml:'
  YAML_EXTS = [ '.yaml', '.yml' ]

  def self.yaml_loader(name)
    d = name.downcase
    if d.start_with?(YAML_PREFIX)
      name = name.slice(YAML_PREFIX.size...name.size)
    else
      return false if (YAML_EXTS.index { |s| d.end_with?(s) }).nil?
    end
    n, sep, f = name.partition(':')
    raise StandardError, "No name given." if n.empty?
    raise StandardError, "No filename given." if f.empty?
    doc = YAML.safe_load(File.read(f))
    raise StandardError, "#{name} #{n} exists already." unless Gen.d.add(n, doc)
    true
  rescue Errno::ENOENT
    raise StandardError, "Not found: #{f}\n#{e.to_s}"
  rescue Exception => e
    raise StandardError, "Failed to read as YAML: #{f}\n#{e.to_s}"
  end

  BIN_PREFIX = 'bin:'

  def self.bin_loader(name)
    return false unless name.downcase.start_with?(BIN_PREFIX)
    n, sep, f = name.slice(BIN_PREFIX.size...name.size).partition(':')
    raise StandardError, "No name given." if n.empty?
    raise StandardError, "No filename given." if f.empty?
    doc = IO.binread(f)
    raise StandardError, "#{name} #{n} exists already." unless Gen.d.add(n, doc)
    true
  rescue Errno::ENOENT
    raise StandardError, "Not found: #{f}\n#{e.to_s}"
  rescue Exception => e
    raise StandardError, "Failed to read #{f}\n#{e.to_s}"
  end

  def self.loaders
    pre = @preloaders
    [ method(:gem_loader), method(:ruby_loader), method(:yaml_loader), method(:bin_loader) ]
  end

  def self.document
    %(
- #{Loaders::GEM_PREFIX}gem_name : requires the gem.
- ruby_file#{Loaders::RUBY_EXT} : changes to Ruby file directory and requires the file.
- #{Loaders::YAML_PREFIX}name:filename : Loads YAML file into Gen.d.name.
- name:filename.{#{(Loaders::YAML_EXTS.map { |s| s[1...s.size] }).join('|')}} : Loads YAML file into Gen.d.name.
- #{Loaders::BIN_PREFIX}name:filename : Loads binary file into Gen.d.name.
)
  end

end
