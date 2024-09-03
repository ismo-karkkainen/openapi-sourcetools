# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'task'
require_relative 'gen'
require 'find'
require 'yaml'

module OpenAPISourceTools
  # Configuration file find and load convenience functions.
  # See the first 3 methods. The rest are intended to be internal helpers.
  module ConfigLoader

    # A function to find all files with a given prefix.
    # Prefix is taken from Gen.config if nil.
    # Returns an array of ConfigFileInfo objects.
    def self.find_files(name_prefix:, extensions: [ '.*' ])
      name_prefix = Gen.config if name_prefix.nil?
      raise ArgumentError, 'name_prefix or config must be set' if name_prefix.nil?
      root, name_prefix = prepare_prefix(name_prefix, Gen.wd)
      file_paths = find_filenames(root, name_prefix)
      splitter = path_splitter(Gen.separator)
      out = file_paths.map { |fp| convert_path_end(fp, splitter, root.size + 1, extensions) }
      out.sort!
    end

    # A function to read all YAML files in an array of ConfigFileInfo objects.
    # Returns the same as contents_array.
    def self.read_contents(config_file_infos)
      config_file_infos.each do |cfi|
        c = YAML.safe_load_file(cfi.path)
        # Check allows e.g. copyright and license files be named with config prefix
        # for clarity, but ignored during config loading.
        next if cfi.keys.empty? && !c.is_a?(Hash)
        cfi.bury_content(c)
      rescue Psych::SyntaxError
        next # Was not YAML. Other files can be named using config prefix.
      end
      contents_array(config_file_infos)
    end

    # Maps an array of ConfigFileInfo objects to an array of their contents.
    def self.contents_array(config_file_infos)
      config_file_infos.map(&:content).reject(&:nil?)
    end

    class ConfigFileInfo
      include Comparable

      attr_reader :root, :keys, :path, :content

      def initialize(pieces, path)
        @keys = []
        @root = nil
        pieces.each do |p|
          if p.is_a?(String)
            if @root.nil?
              @root = p
            else
              @keys.push(p)
            end
          else
            break if p == :extension
          end
        end
        @path = path
        @content = nil
      end

      def bury_content(content)
        # Turns chain of keys into nested Hashes.
        @keys.reverse.each do |key|
          c = { key => content }
          content = c
        end
        @content = content
      end

      def <=>(other)
        d = @root <=> other.root
        return d unless d.zero?
        d = @keys.size <=> other.keys.size
        return d unless d.zero?
        d = @keys <=> other.keys
        return d unless d.zero?
        @path <=> other.path
      end
    end

    def self.prepare_prefix(name_prefix, root)
      name_prefix_dir = File.dirname(name_prefix)
      root = File.realpath(name_prefix_dir, root) unless name_prefix_dir == '.'
      name_prefix = File.basename(name_prefix)
      if name_prefix == '.' # Just being nice. Daft argument.
        name_prefix = File.basename(root)
        root = File.dirname(root)
      end
      [root, name_prefix]
    end

    def self.find_filenames(root, name_prefix)
      full_prefix = File.join(root, name_prefix)
      file_paths = []
      Find.find(root) do |path|
        next if path.size < full_prefix.size
        is_dir = File.directory?(path)
        if path.start_with?(full_prefix)
          file_paths.push(path) unless is_dir
        elsif is_dir
          Find.prune
        end
      end
      file_paths
    end

    def self.path_splitter(separator)
      parts = [ Regexp.quote('/') ]
      parts.push(Regexp.quote(separator)) if separator.is_a?(String) && !separator.empty?
      Regexp.new("(#{parts.join('|')})")
    end

    def self.remove_extension(file_path, extensions)
      extensions.each do |e|
        if e == '.*'
          idx = file_path.rindex('.')
          next if idx.nil? # No . anywhere.
          ext = file_path[idx..]
          next unless ext.index('/').nil? # Last . is before file name.
          return [ file_path[0...idx], ext ]
        elsif file_path.end_with?(e)
          return [ file_path[0..-(1 + e.size)], e ]
        end
      end
      [ file_path, nil ]
    end

    def self.convert_path_end(path, splitter, prefix_size, extensions)
      relevant, ext = remove_extension(path[prefix_size..], extensions)
      pieces = relevant.split(splitter).map do |piece|
        case piece
        when '' then nil
        when '/' then :dir
        when Gen.separator then :separator
        else
          piece
        end
      end
      unless ext.nil?
        pieces.push(:extension)
        pieces.push(ext)
      end
      pieces.compact!
      ConfigFileInfo.new(pieces, path)
    end
  end
end
