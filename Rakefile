# frozen_string_literal: true

require 'rubocop/rake_task'

def run_in_subdirs(cmd)
  %w[sourcetools documentation].each do |d|
    sh "cd #{d} && #{cmd}"
  end
end

task default: [:test, :gems]

desc 'Clean.'
task :clean do
  sh 'rm -f *.gem'
  run_in_subdirs('rake clean')
end

desc 'Build gems.'
task gems: [:clean] do
  run_in_subdirs('rake gem && mv *.gem ..')
end

desc 'Test.'
task :test do
  run_in_subdirs('rake test')
end
