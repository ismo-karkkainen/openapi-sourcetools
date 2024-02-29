# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'openapi-sourcetools'
  s.version     = '0.5.0'
  s.summary     = 'Tools for creating source code from API specification.'
  s.description = %q(
Tools for generating source code from API specification in OpenAPI format.
)
  s.authors     = [ 'Ismo Kärkkäinen' ]
  s.email       = 'ismokarkkainen@icloud.com'
  s.files       = [ 'lib/common.rb', 'LICENSE.txt' ]
  s.executables << 'openapi-addschemes'
  s.executables << 'openapi-frequencies'
  s.executables << 'openapi-merge'
  s.executables << 'openapi-processpaths'
  s.homepage    = 'https://xn--ismo-krkkinen-gfbd.fi/openapi-sourcetools/index.html'
  s.license     = 'UPL-1.0'
  s.required_ruby_version = '>= 3.0.0'
  s.metadata = { 'rubygems_mfa_required' => 'true' }
end
