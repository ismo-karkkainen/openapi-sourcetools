# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

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

  def self.loaders
    [ method(:gem_loader), method(:ruby_loader) ]
  end

  def self.document
    %(
- #{Loaders::GEM_PREFIX}gem_name : requires the gem.
- ruby_file#{Loaders::RUBY_EXT} : changes to Ruby file directory and requires the file.
)
  end

end
