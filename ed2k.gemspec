require File.dirname(__FILE__) + '/spec/version.rb'

Gem::Specification.new do |s|
  s.name = 'ed2k'
  s.author = 'xdanger'
  s.email = 'xdanger@gmail.com'
  s.version = Ed2k::VERSION
  s.platform = 'ruby'
  s.summary = 'Hash files and generate metadata to build their ed2ks'
  s.require_paths = ['bin', 'lib', 'spec']
  s.files = Dir['bin/*'] + Dir['lib/**/*.rb'] + Dir['spec/*.rb']
  s.files << Dir['[A-Z]*'] + Dir['test/**/*']
  s.files.reject! { |fn| fn.include? ".git" }
#  s.add_dependency('openssl')
  
  s.bindir = 'bin'
  s.executables = ['ed2k-hash', 'ed2k-hashfile']
  s.extra_rdoc_files = ["README.rdoc", "LICENSE", "THANKS"]
#  s.autorequire = 'rake'
  s.has_rdoc = true
  s.homepage = 'http://www.verycd.com/'
  s.date = Time.now
end