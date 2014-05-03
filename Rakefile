require 'rubygems/package_task'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
  s.name         = 'qc.rb'
  s.version      = '0.0.3'
  s.date         = '2014-05-04'
  s.summary      = "QingCloud API Library"
  s.description  = "QingCloud API Library to handle instances, networks, internetconnections, etc. on QingCloud.com"
  s.authors      = ["Daniel Bovensiepen"]
  s.email        = 'daniel@bovensiepen.net'
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md)
  s.executables  = ['qc']
  s.require_path = 'lib'
  s.homepage     = 'https://github.com/bovi/qc.rb'
  s.license      = 'MIT'
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

task :clean => [:clobber_package]
