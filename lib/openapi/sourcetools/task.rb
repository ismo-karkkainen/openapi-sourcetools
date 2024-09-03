# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require_relative 'common'
require 'erb'


module OpenAPISourceTools

  # Required interface for tasks, with default implementation for some methods.
  module TaskInterface
    def generate(context_binding)
      raise NotImplementedError
    end

    def output_name
      raise NotImplementedError
    end

    def discard
      false
    end

    def executable
      false
    end

    def system
      false
    end
  end

  # Loads template or takes it as argument. Renders template using ERB.
  class Task
    include TaskInterface

    attr_reader :src, :template, :template_name
    attr_accessor :name, :executable, :discard, :x

    def initialize(src, template, template_name)
      @src = src
      @template = template
      @template_name = template_name
      if @template.nil?
        raise ArgumentError, 'template_name or template must be given' if @template_name.nil?
        begin
          @template = File.read(@template_name)
        rescue Errno::ENOENT
          raise StandardError, "Could not load #{@template_name}"
        rescue StandardError => e
          raise StandardError, "#{e}\nFailed to read #{@template_name}"
        end
      end
      @name = nil
      @executable = false
      @discard = false
      @x = nil
    end

    # If this is overridden to perform some processing but not to produce output,
    # set @discard = true and return value will be ignored. No other methods are
    # called in that case.
    def internal_generate(context_binding)
      ERB.new(@template).result(context_binding)
    end

    # You can override this instead of internal_generate if you do not need the
    # exception handling.
    def generate(context_binding)
      n = @template_name.nil? ? '' : "#{@template_name} "
      internal_generate(context_binding)
    rescue SyntaxError => e
      OpenAPISourceTools::Common.aargh("Template #{n}syntax error: #{e.full_message}", 5)
    rescue Exception => e # Some unexpected error.
      OpenAPISourceTools::Common.aargh("Template #{n}error: #{e.full_message}", 6)
    end

    # This is only called when generate produced output that is not discarded.
    def output_name
      return @name unless @name.nil?
      # Using template name may show where name assignment is missing.
      # Name assignment may also be missing in the task creation stage.
      return File.basename(@template_name) unless @template_name.nil?
      nil
    end
  end

  # A task that provides contents to be written to a named file.
  # Optionaly the file may be made executable.
  class WriteTask
    include TaskInterface

    attr_reader :name, :contents, :executable

    def initialize(name, contents, executable = false)
      raise ArgumentError, 'name and contents must be given' if name.nil? || contents.nil?
      @name = name
      @contents = contents
      @executable = executable
    end

    def generate(_context_binding)
      @contents
    end

    def output_name
      @name
    end
  end

  # Sets Gen.x to empty hash. Inserted after gem tasks.
  class RestoreProcessorStorage
    include TaskInterface

    attr_accessor :x # Allows setting the current value when setup code finishes.

    # Sets initial default value.
    def initialize(x = {})
      @x = x
      Gen.x = @x
    end

    def generate(_context_binding)
      Gen.x = @x # Restore whatever was current when setup code finished.
    end

    def discard
      true
    end

    def system
      true
    end
  end
end
