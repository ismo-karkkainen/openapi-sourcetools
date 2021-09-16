# frozen_string_literal: true

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
task :test do
  sh './test.sh'
end
