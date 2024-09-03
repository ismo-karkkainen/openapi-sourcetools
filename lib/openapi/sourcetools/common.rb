# frozen_string_literal: true

# Copyright © 2021-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require 'pathname'
require 'yaml'

module OpenAPISourceTools
  # Common methods used in programs and elsewhere gathered into one place.
  module Common

    def self.aargh(message, return_value = nil)
      message = message.map(&:to_s).join("\n") if message.is_a? Array
      $stderr.puts message
      return_value
    end

    def self.yesno(boolean)
      boolean ? 'yes' : 'no'
    end

    def self.bury(doc, path, value)
      (path.size - 1).times do |k|
        p = path[k]
        doc[p] = {} unless doc.key?(p)
        doc = doc[p]
      end
      doc[path.last] = value
    end

    module Out
      attr_reader :count
      module_function :count
      attr_accessor :quiet
      module_function :quiet
      module_function :quiet=

      def self.put(message)
        Common.aargh(message) unless @quiet
        @count = @count.nil? ? 1 : @count + 1
      end
    end

    def self.split_path(p, spec = false)
      parts = []
      p = p.strip
      unless spec
        q = p.index('?')
        p.slice!(0...q) unless q.nil?
      end
      p.split('/').each do |s|
        next if s.empty?
        s = { var: s } if spec && s.include?('{')
        parts.push(s)
      end
      parts
    end

    def self.load_source(input)
      YAML.safe_load(input.nil? ? $stdin : File.read(input))
    rescue Errno::ENOENT
      aargh "Could not load #{input || 'stdin'}"
    rescue StandardError => e
      aargh "#{e}\nFailed to read #{input || 'stdin'}"
    end

    def self.dump_result(output, doc, error_return)
      doc = YAML.dump(doc, line_width: 1_000_000) unless doc.is_a?(String)
      if output.nil?
        $stdout.puts doc
      else
        fp = Pathname.new output
        fp.open('w') do |f|
          f.puts doc
        end
      end
      0
    rescue StandardError => e
      aargh([ e, "Failed to write output: #{output || 'stdout'}" ], error_return)
    end
  end
end
