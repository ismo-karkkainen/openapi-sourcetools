# frozen_string_literal: true

def aargh(message, exit_code = nil)
  $stderr.puts message
  exit exit_code unless exit_code.nil?
end

def env(var, value = nil)
  k = var.to_s.upcase
  ENV[k] = { false => '0', true => '1' }.fetch(value, value) unless value.nil?
  v = ENV.fetch(k, nil)
  case v
  when '0' then false
  when '1' then true
  else
    v
  end
end

def default_env(var, value)
  v = env(var)
  env(var, value) if v.nil?
end

def split_path(p, spec = false)
  parts = []
  unless spec
    q = p.index('?')
    p.slice!(0...q) unless q.nil?
  end
  p.split('/').each do |s|
    next if s.empty?
    s = { var: s } if spec && s.include?('{')
    parts.push(s)
  end
end

ServerPath = Struct.new(:parts) do
  def <=>(p)
    pp = p.is_a?(Array) ? p : p.parts
    parts.each_index do |k|
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
