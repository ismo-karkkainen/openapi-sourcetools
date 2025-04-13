# frozen_string_literal: true

# Copyright © 2024-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.


module OpenAPISourceTools
  # Output configuration settings for easy storage.
  # You can have it in configuration and pass hash to initialize.
  class OutputConfiguration
    attr_reader :indent_character, :indent_step
    attr_reader :tab, :tab_replaces_count

    def initialize(cfg = {})
      @indent_character = cfg['indent_character'] || ' '
      @indent_step = cfg['indent_step'] || 4
      @tab = cfg['tab'] || "\t"
      @tab_replaces_count = cfg['tab_replaces_count'] || 0
    end
  end

  # Output indentation helper class.
  # Exposed as Gen.output for use from templates.
  class Output
    attr_reader :config
    attr_accessor :last_indent

    def initialize(cfg = OutputConfiguration.new)
      @config = cfg
      @last_indent = 0
    end

    def config=(cfg)
      cfg = OutputConfiguration.new(cfg) if cfg.is_a?(Hash)
      raise ArgumentError, "Expected OutputConfiguration or Hash, got #{cfg.class}" unless cfg.is_a?(OutputConfiguration)
      @config = cfg
      @last_indent = 0
    end

    # Takes an array of code blocks/lines or integers/booleans and produces
    # indented output using the separator character.
    # Set class attributes to obtain desired outcome.
    def join(blocks, separator = "\n")
      indented = []
      blocks.flatten!
      indent = 0
      blocks.each do |block|
        if block.nil?
          next
        elsif block.is_a?(Integer)
          indent += block
          indent = 0 if indent.negative?
        elsif block.is_a?(TrueClass)
          indent += @config.indent_step
        elsif block.is_a?(FalseClass)
          indent -= @config.indent_step
          indent = 0 if indent.negative?
        else
          block = block.to_s unless block.is_a?(String)
          if block.empty?
            indented.push('')
            next
          end
          if indent.zero?
            indented.push(block)
            next
          end
          if @config.tab_replaces_count.positive?
            tabs = @config.tab * (indent / @config.tab_replaces_count)
            chars = @config.indent_character * (indent % @config.tab_replaces_count)
          else
            tabs = ''
            chars = @config.indent_character * indent
          end
          lines = block.lines(chomp: true)
          lines.each do |line|
            indented.push("#{tabs}#{chars}#{line}")
          end
        end
      end
      @last_indent = indent
      indented.join(separator)
    end
  end
end
