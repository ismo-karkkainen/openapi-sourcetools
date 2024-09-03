require_relative '../shared/unittest.rb'

assert(Dir.pwd, File.dirname(__FILE__), 'Changed to loaded file directory')
Gen.tasks.push([]) # Anything goes.
Gen.x = []
