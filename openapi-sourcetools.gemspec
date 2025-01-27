# frozen_string_literal: true

require_relative 'lib/openapi/sourcetools/version'
require 'simpleidn'
require 'rake'

Gem::Specification.new do |s|
  s.name = OpenAPISourceTools::NAME
  s.version = OpenAPISourceTools::VERSION
  s.summary = 'Tools for creating source code from API specification.'
  s.description = 'Tools for handling API specification in OpenAPI format.
Programs to replace of duplicate definitions with references. Other checks.

Does not validate the document against OpenAPI format specification.'
  s.authors = [ 'Ismo Kärkkäinen' ]
  s.email = 'ismokarkkainen@icloud.com'
  s.files = FileList[ 'lib/openapi/sourcetools.rb', 'lib/openapi/sourcetools/*.rb', 'LICENSE.txt' ].to_a
  s.executables << 'openapi-addheaders'
  s.executables << 'openapi-addparameters'
  s.executables << 'openapi-addresponses'
  s.executables << 'openapi-addschemas'
  s.executables << 'openapi-checkschemas'
  s.executables << 'openapi-frequencies'
  s.executables << 'openapi-generate'
  s.executables << 'openapi-merge'
  s.executables << 'openapi-modifypaths'
  s.executables << 'openapi-processpaths'
  s.homepage = "https://#{SimpleIDN.to_ascii('ismo-kärkkäinen.fi')}/#{OpenAPISourceTools::NAME}/index.html"
  s.license = 'UPL-1.0'
  s.required_ruby_version = '>= 3.2.5'
  s.add_dependency 'deep_merge', '~> 1.2', '>= 1.2.2'
  s.metadata = { 'rubygems_mfa_required' => 'true' }
end
