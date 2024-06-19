# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'openapi-sourcetools'
  s.version = '0.6.0'
  s.summary = 'Tools for creating source code from API specification.'
  s.description = %q(
Tools for handling API specification in OpenAPI format. Replacement of
duplicate definitions with references. Other checks. Does not validate
the document against OpenAPI format specification.
)
  s.authors = [ 'Ismo Kärkkäinen' ]
  s.email = 'ismokarkkainen@icloud.com'
  s.files = [ 'lib/common.rb', 'lib/task.rb', 'lib/generate.rb', 'lib/gen.rb', 'lib/helper.rb', 'lib/loaders.rb', 'lib/apiobjects.rb', 'LICENSE.txt' ]
  s.executables << 'openapi-addheaders'
  s.executables << 'openapi-addparameters'
  s.executables << 'openapi-addresponses'
  s.executables << 'openapi-addschemas'
  s.executables << 'openapi-checkschemas'
  s.executables << 'openapi-frequencies'
  s.executables << 'openapi-generate'
  s.executables << 'openapi-merge'
  s.executables << 'openapi-processpaths'
  s.homepage = 'https://xn--ismo-krkkinen-gfbd.fi/openapi-sourcetools/index.html'
  s.license = 'UPL-1.0'
  s.required_ruby_version = '>= 3.0.0'
  s.metadata = { 'rubygems_mfa_required' => 'true' }
end
