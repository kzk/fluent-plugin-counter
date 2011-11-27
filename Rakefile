require 'rake'
require 'rake/testtask'
require 'rake/clean'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "fluent-plugin-counter"
    gemspec.summary = "Distributed counter plugin for Fluentd event collector"
    gemspec.author = "Kazuki Ohta"
    gemspec.email = "kazuki.ohta@gmail.com"
    gemspec.homepage = "https://github.com/fluent/fluent-plugin-counter"
    gemspec.has_rdoc = false
    gemspec.require_paths = ["lib"]
    gemspec.add_dependency "fluentd", "~> 0.10.0"
    gemspec.add_dependency "thrift", "~> 0.7.0"
    gemspec.test_files = Dir["test/**/*.rb"]
    gemspec.files = Dir["bin/**/*", "lib/**/*", "test/**/*.rb"] +
      %w[example.conf VERSION AUTHORS Rakefile fluent-plugin-counter.gemspec]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

task "thrift_gen" do
  system "rm -fR tmp"
  system "mkdir -p tmp"
  system "thrift --gen rb -o tmp lib/fluent/plugin/thrift/counter.thrift"
  system "mv tmp/gen-rb/* lib/fluent/plugin/thrift/"
  system "rm -fR tmp"
end

Rake::TestTask.new(:test) do |t|
  t.test_files = Dir['test/plugin/*.rb']
  t.ruby_opts = ['-rubygems'] if defined? Gem
  t.ruby_opts << '-I.'
end

#VERSION_FILE = "lib/fluent/version.rb"
#
#file VERSION_FILE => ["VERSION"] do |t|
#  version = File.read("VERSION").strip
#  File.open(VERSION_FILE, "w") {|f|
#    f.write <<EOF
#module Fluent
#
#VERSION = '#{version}'
#
#end
#EOF
#  }
#end
#
#task :default => [VERSION_FILE, :build]

task :default => [:build]
