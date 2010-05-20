require 'rake'
require 'rake/testtask'

task :default => :test

task :shell do
  Dir.chdir("lib") do
    sh("irb -rcerealizer")
  end
end

Rake::TestTask.new("test"){|t|
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
  t.warning = true
}
