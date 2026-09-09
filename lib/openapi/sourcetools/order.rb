# frozen_string_literal: true

# Copyright © 2026 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

# Top-level module.
module OpenAPISourceTools
  # Ordering methods and classes for openapi-order.
  module Ordering
    # Used as replacement for '*'.
    ANY = Regexp.new('^.*$')

    def self.array_item_compare(a, b)
      a[:values].size.times do |k|
        av = a[:values][k]
        bv = b[:values][k]
        if av.nil?
          return 1 unless bv.nil?
        else
          return -1 if bv.nil?
          r = av <=> bv
          return r unless r.nil? || r.zero?
        end
      end
      0
    end

    # Allowed keys starting from root, with pattern, any or multiple any key.
    # Initialized with the path to the order array.
    class KeyPath
      include Comparable

      attr_reader :items, :multiple, :first_multiple

      # the parent_keys is processed to an array of regular expressions and :multi.
      # A '*' is eventually replaced with regular expression that accepts anything.
      # A '**' is replaced by :multi that matches at least one key during match.
      # A string starting with regexp_prefix is changed to a regular expression.
      # Other string is turned to anchored regular expression that matches only the string.
      # The order of '*' and '**' can be modified to minimize occurrences of :multi.
      def initialize(parent_keys, regexp_prefix)
        @multiple = false
        @items = []
        parent_keys.each do |key|
          if key == '*'
            if @items.last == :multi
              # :multi, :one is same as :one, :multi as at least 2 arbitrary items.
              @items.pop
              @items.push(:one, :multi)
            else
              @items.push(:one)
            end
          elsif key == '**'
            @multiple = true
            if @items.last == :multi
              # :multi, :multi is same as :one, :multi as at least 2 arbitrary items.
              @items.pop
              @items.push(:one, :multi)
            else
              @items.push(:multi)
            end
          elsif key.start_with?(regexp_prefix)
            @items.push(Regexp.new(key[regexp_prefix.size..]))
          else
            @items.push(Regexp.new("^#{Regexp.escape(key)}$"))
          end
        end
        @items.each_with_index do |item, idx|
          @items[idx] = ANY if item == :one
        end
        @first_multiple = @items.index(:multi) || @items.size
      end

      # Finds indexes of regular expressions that match key, skipping given number.
      def matching_item_indexes(key, skip_non_multis)
        indexes = []
        ([skip_non_multis, @first_multiple].min...@items.size).each do |idx|
          item = @items[idx]
          indexes.push(idx) if item == :multi || item.match?(key)
        end
        indexes
      end

      # Given possible matches, uses position_index to check for matches relevant
      # to the current situation and checks recursively if a solution ending to
      # the desired point can be found.
      def search(index_arrays, array_index, position_index)
        if array_index == index_arrays.size
          # Last key is known to match last item, so if that were tested, it would pass.
          return position_index == @items.size - 1
        end
        if @items[position_index] == :multi
          # Multi absorbs current key and releases to next position.
          return true if search(index_arrays, array_index + 1, position_index + 1)
          # Multi absorbs current key and stays for more.
          search(index_arrays, array_index + 1, position_index)
        else
          # Only current item to match with.
          return false if index_arrays[array_index].index(position_index).nil?
          search(index_arrays, array_index + 1, position_index + 1)
        end
      end

      # Performs base checks whether match is possible and if so, obtains indexes
      # od matching patterns and starts search using those.
      def match?(key_path)
        return true if @items.empty? && key_path.empty?
        slack = key_path.size - @items.size
        return false if slack.negative? # Path too short.
        return false if slack.positive? && !@multiple # Path too long.
        # Last key must match last item.
        return false unless @items.last == :multi || @items.last.match?(key_path.last)
        # First key must match first item.
        return false unless @items.first == :multi || @items.first.match?(key_path.first)
        return true if key_path.size <= 2 # Tested both already.
        # Form arrays of possible match indexes for search. Omit first and last.
        index_arrays = []
        (1...(key_path.size - 1)).each do |idx|
          key = key_path[idx]
          idxs = matching_item_indexes(key, idx)
          return false if idxs.empty?
          index_arrays.push(idxs)
        end
        search(index_arrays, 0, @items.first == :multi ? 0 : 1)
      end

      def <=>(other)
        # The purpose is to place longest "exact" items to the end.
        # Hence items.size, and the more multiple, the earlier.
        d = @items.size <=> other.items.size
        return d unless d.zero?
        -@items.count(:multi) <=> -other.items.count(:multi)
      end
    end

    # Book-keeping class for pattern and its location.
    class KeyPattern
      attr_reader :pattern, :index, :priority

      def initialize(pattern, index, priority)
        @pattern = pattern
        @index = index
        @priority = priority
      end

      def match?(string)
        @pattern.match?(string)
      end

      def any?
        @index != @priority
      end
    end

    # Handles ordering keys or an array using the given key order.
    class Order
      def self.orderable?(item)
        return true if item.is_a?(Hash)
        return true if item.is_a?(Array)
        false
      end

      attr_reader :patterns

      def initialize(keys, regexp_prefix)
        @patterns = []
        has_asterisk = false
        keys.each_with_index do |string, idx|
          if string.start_with?(regexp_prefix)
            @patterns.push(KeyPattern.new(Regexp.new(string[regexp_prefix.size..]), idx, idx))
          elsif string == '*'
            @patterns.push(KeyPattern.new(Regexp.new('^.*$'), idx, keys.size)) unless has_asterisk # First used.
            has_asterisk = true
          else
            @patterns.push(KeyPattern.new(Regexp.new("^#{Regexp.escape(string)}$"), idx, idx))
          end
        end
        @patterns.push(KeyPattern.new(Regexp.new('^.*$'), @patterns.size, keys.size + 1)) unless has_asterisk
      end

      def apply_array(array)
        return true if array.size < 2
        values = []
        array.each do |item|
          amended = {
            item: item,
            values: []
          }
          unless item.is_a?(Hash)
            amended[:values] = Array.new(@patterns.size, nil)
            values.push(amended)
            next
          end
          @patterns.each do |kp|
            if kp.any?
              amended[:values].push(nil)
              next
            end
            # Find first matching key.
            v = nil
            item.each_key do |item_key|
              next unless kp.match?(item_key)
              v = item[item_key]
              break
            end
            amended[:values].push((v.is_a?(Array) || v.is_a?(Hash)) ? nil : v)
          end
          values.push(amended)
        end
        values.sort! { |a, b| OpenAPISourceTools::Ordering.array_item_compare(a, b) }
        values.each_with_index { |amended, i| array[i] = amended[:item] }
        true
      end

      def apply_hash(hash)
        return true if hash.size < 2
        groups = @patterns.map do |kp|
          {
            kp: kp,
            keys: []
          }
        end
        s2orig = {}
        hash.each_key do |key|
          skey = key.is_a?(String) ? key : key.to_s
          s2orig[skey] = key
          best_priority = groups.size + 1
          best_idx = nil
          groups.each do |group|
            kp = group[:kp]
            next if best_priority <= kp.priority
            next unless kp.match?(skey)
            best_priority = kp.priority
            best_idx = kp.index
          end
          groups[best_idx][:keys].push(skey) unless best_idx.nil?
        end
        ordered = {}
        groups.each do |group|
          group[:keys].sort!
          group[:keys].each { |k| ordered[s2orig[k]] = hash[s2orig[k]] }
        end
        hash.clear
        hash.merge!(ordered)
        true
      end

      def apply(item)
        return apply_array(item) if item.is_a?(Array)
        return apply_hash(item) if item.is_a?(Hash)
        false
      end
    end

    # Holds KeyPath and the order that was specified.
    class KeyPathOrder
      include Comparable

      attr_reader :path, :order

      def initialize(key_path, order)
        @path = key_path
        @order = order
      end

      def <=>(other)
        @path <=> other.path
      end
    end
  end
end
