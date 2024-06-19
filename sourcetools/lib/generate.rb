#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright © 2024 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'common'
require_relative 'loaders'
require_relative 'gen'

def executable_bits_on(mode)
  mode = mode.to_s(8).split('')
  mode.size.times do |k|
    m = mode[k].to_i(8)
    # Applies to Unix-likes. Other system, check and handle.
    m += 1 unless 3 < mode.size - k || m.zero? || m % 2 == 1
    mode[k] = m
  end
  m = 0
  mode.each do |v|
    m = 8 * m + v
  end
  m
end

class Generator
  def initialize(document_content, input_name, output_directory)
    Gen.setup(document_content, input_name, output_directory)
    Gen.loaders = Loaders.loaders
  end

  def context_binding
    binding
  end

  def load(generator_names)
    generator_names.each do |name|
      idx = Gen.loaders.index { |loader| loader.call(name) }
      return aargh("No loader could handle #{name}", 2) if idx.nil?
    end
    0
  rescue StandardError => e
    aargh(e.to_s, 2)
  end

  def generate(t)
    t.generate(context_binding)
  rescue Exception => e
    aargh(e.to_s, 4)
  end

  def output_name(t, index)
    name = t.output_name
    name = "#{index}.txt" if name.nil?
    File.join(Gen.outdir, name)
  end

  def save(name, contents, executable)
    f = File.new(name, File::WRONLY | File::CREAT | File::TRUNC)
    s = executable ? f.stat : nil
    f.write(contents)
    f.close
    return unless executable
    mode = executable_bits_on(s.mode)
    File.chmod(mode, name) unless mode == s.mode
  end

  def run
    # This allows tasks to be added while processing.
    # Not intended to be done but might prove handy.
    # Also exposes current task index in case new task is added in the middle.
    Gen.task_index = 0
    while Gen.task_index < Gen.tasks.size
      Gen.t = Gen.tasks[Gen.task_index]
      out = generate(Gen.t)
      Gen.task_index += 1
      next if Gen.t.discard # Check first to ignore result if no output.
      return out if out.is_a?(Integer)
      next if out.empty? # Allows no output but return value still checked.
      name = output_name(Gen.t, Gen.task_index - 1)
      begin
        save(name, out, Gen.t.executable)
      rescue StandardError => e
        return aargh("Error writing output file: #{name}\n#{e}", 3)
      end
    end
    0
  end
end
