# frozen_string_literal: true

require 'rubocop/rake_task'

task default: [:install]

desc 'Clean.'
task :clean do
  `rm -f openapi-sourcetools-*.gem`
end

desc 'Build gem.'
task gem: [:clean] do
  `gem build openapi-sourcetools.gemspec`
end

desc 'Build and install gem.'
task install: [:gem] do
  `gem install openapi-sourcetools-*.gem`
end

desc 'Test.'
task test: %i[testmerge testprocesspaths testfrequencies testaddschemas testgeneratecode]

desc 'Test merge.'
task :testmerge do
  sh './test.sh merge'
end

desc 'Test processpaths.'
task :testprocesspaths do
  sh './test.sh processpaths'
end

desc 'Test frequencies.'
task :testfrequencies do
  sh './test.sh frequencies'
end

desc 'Test addschemas.'
task :testaddschemas do
  sh './test.sh addschemas'
end

desc 'Test generatecode.'
task :testgeneratecode do
  sh './test.sh generatecode'
end

desc 'Lint using Rubocop'
RuboCop::RakeTask.new(:lint) do |t|
  t.patterns = [ 'bin', 'lib', 'openapi-sourcetools.gemspec' ]
end
