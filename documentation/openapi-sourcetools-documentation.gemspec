# frozen_string_literal: true

require 'rake'
require_relative 'lib/tasks'

Gem::Specification.new do |s|
  s.name        = OpenAPISourceToolsDocumentation::NAME
  s.version     = OpenAPISourceToolsDocumentation::VERSION
  s.summary     = 'Produce documents out of OpenAPI format API specification.'
  s.description = %q(This is a processor gem for use with openapi-generate from gem
openapi-sourcetools.

Produces a markdown file, diagrammatron diagram files, and a shell script to
run diagrammatron tools to make a few different diagrams.

To run the script, you need to have diagrammatron gem installed.
)
  s.authors     = [ 'Ismo Kärkkäinen' ]
  s.email       = 'ismokarkkainen@icloud.com'
  s.files       = FileList[ 'lib/tasks.rb', 'template/*.erb', 'template/*.yaml', 'LICENSE.txt' ]
  s.homepage    = 'https://xn--ismo-krkkinen-gfbd.fi/openapi-sourcetools/index.html'
  s.license     = 'UPL-1.0'
  s.required_ruby_version = '>= 3.0.0'
  s.metadata = { 'rubygems_mfa_required' => 'true' }
  s.add_development_dependency 'diagrammatron', '~> 0.6', '>= 0.6.1'
end
