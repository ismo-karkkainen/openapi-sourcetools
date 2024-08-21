# frozen_string_literal: true

# Copyright © 2021-2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require 'pathname'


def aargh(message, return_value = nil)
  message = message.map(&:to_s).join("\n") if message.is_a? Array
  $stderr.puts message
  return_value
end

def yesno(boolean)
  boolean ? 'yes' : 'no'
end

def bury(doc, path, value)
  (path.size - 1).times do |k|
    p = path[k]
    doc[p] = {} unless doc.key?(p)
    doc = doc[p]
  end
  doc[path.last] = value
end

module Out
  attr_reader :count

  def put(message)
    aargh(message)
    count += 1
  end
end

def split_path(p, spec = false)
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

def load_source(input)
  YAML.safe_load(input.nil? ? $stdin : File.read(input))
rescue Errno::ENOENT
  aargh "Could not load #{input || 'stdin'}"
rescue StandardError => e
  aargh "#{e}\nFailed to read #{input || 'stdin'}"
end

def dump_result(output, doc, error_return)
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

ServerPath = Struct.new(:parts) do
  # Variables are after fixed strings.
  def <=>(other)
    pp = other.is_a?(Array) ? other : other.parts
    parts.each_index do |k|
      return 1 if pp.size <= k # Longer comes after shorter.
      pk = parts[k]
      ppk = pp[k]
      if pk.is_a? String
        return -1 unless ppk.is_a? String
        c = pk <=> ppk
      else
        return 1 if ppk.is_a? String
        c = pk.fetch('var', '') <=> ppk.fetch('var', '')
      end
      return c unless c.zero?
    end
    (parts.size < pp.size) ? -1 : 0
  end

  # Not fit for sorting. Variable equals anything.
  def compare(p, range = nil)
    pp = p.is_a?(Array) ? p : p.parts
    if range.nil?
      range = 0...parts.size
    elsif range.is_a? Number
      range = range...(range + 1)
    end
    range.each do |k|
      return 1 if pp.size <= k # Longer comes after shorter.
      ppk = pp[k]
      next unless ppk.is_a? String
      pk = parts[k]
      next unless pk.is_a? String
      c = pk <=> ppk
      return c unless c.zero?
    end
    (parts.size < pp.size) ? -1 : 0
  end
end
