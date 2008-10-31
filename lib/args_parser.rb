require 'optparse'
require File.expand_path(File.dirname(__FILE__)) + '/../spec/version.rb'

$options = { :debug => false }

opts = OptionParser.new do |o|
  o.banner = "Usage: ed2k-hash < xxx.avi\n"
  o.separator ''
  o.separator 'Common options:'
  o.on('-f', '--file [FILE]', 'File to process') do |f|
    $options[:file] = f
  end
  o.separator 'Specific options:'
  o.on('-d', '--debug', 'Turn on debug mode') do |d|
    $options[:debug] = true
  end
  o.on_tail('-h', '--help', "Display detailed help and exit") do
    puts o
    exit
  end
  o.on_tail('-v', '--version', "Show version") do
    puts $version
    exit
  end
  
end

begin
  opts.parse!(ARGV)
rescue OptionParser::InvalidOption
  puts "INVALID ARGS"
  puts ""
  puts opts
  exit
end

def debuging?
  $options[:debug]
end