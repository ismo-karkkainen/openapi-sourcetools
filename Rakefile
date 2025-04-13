# frozen_string_literal: true

# Copyright 2021-2025 Ismo Kärkkäinen
# Licensed under Universal Permissive License. See LICENSE.txt.

require 'rubocop/rake_task'

task default: [:test]

desc 'Clean.'
task :clean do
  sh 'rm -f openapi-sourcetools-*.gem'
end

desc 'Build gem.'
task gem: [:clean] do
  sh 'gem build openapi-sourcetools.gemspec'
end

desc 'Build and install gem.'
task install: [:gem] do
  sh 'gem install openapi-sourcetools-*.gem'
end

desc 'Uninstall gem.'
task :uninstall do
  sh 'gem uninstall --executables openapi-sourcetools'
end

desc 'Test.'
task test: %i[testpatterntests testaddsecurityschemes testgeneratecheckconfig testmodifypaths testmerge testprocesspaths testfrequencies testaddschemas testaddresponses testaddheaders testaddparameters testcheckschemas testgenerate testoftypes testcommon]

desc 'Test modifypaths.'
task :testmodifypaths do
  sh './test.sh modifypaths'
end

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

desc 'Test addresponses.'
task :testaddresponses do
  sh './test.sh addresponses'
end

desc 'Test addheaders.'
task :testaddheaders do
  sh './test.sh addheaders'
end

desc 'Test addparameters.'
task :testaddparameters do
  sh './test.sh addparameters'
end

desc 'Test checkschemas.'
task :testcheckschemas do
  sh './test.sh checkschemas'
end

desc 'Test generate.'
task :testgenerate do
  sh './test.sh generate'
end

desc 'Test generate-checkconfig.'
task :testgeneratecheckconfig do
  sh './test.sh checkconfig'
end

desc 'Test common.'
task :testcommon do
  sh './test.sh common'
end

desc 'Test oftypes.'
task :testoftypes do
  sh './test.sh oftypes'
end

desc 'Test addsecurityschemes.'
task :testaddsecurityschemes do
  sh './test.sh addsecurityschemes'
end

desc 'Test patterntests.'
task :testpatterntests do
  sh './test.sh patterntests'
end

desc 'Lint using Rubocop'
RuboCop::RakeTask.new(:lint) do |t|
  t.patterns = [ 'bin', 'lib', 'openapi-sourcetools.gemspec' ]
end
