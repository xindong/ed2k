require File.dirname(__FILE__).'/spec/version.rb'

Gem::Specification.new do |s|
  s.name = 'ed2khash'
  s.version = $version
  s.platform = Gem::Platform::Ruby
  s.summary = 'Hash files and generate metadata to build their ed2ks'
  s.requirepath = ['lib']
  s.files = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.files << Dir['[A-Z]*'] + Dir['test/**/*']
  s.files.reject! { |fn| fn.include? ".git" }
  s.add_dependency('openssl')
  
  s.bindir = 'bin'
  s.executables = ['ed2k-hash', 'ed2k-hashfile']
  spec.extra_rdoc_files = ["README.rdoc", "LICENSE", "THANKS"]
#  s.autorequire = 'rake'
  spec.has_rdoc = true
  spec.hompage = 'http://www.verycd.com/'
  s.date = Time.now
end