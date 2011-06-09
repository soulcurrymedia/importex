require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

pattern = "spec/**/*_spec.rb"

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = pattern
  t.rspec_opts = ["-c"]
end

task :default => :spec
