require 'optparse'
require 'pp'
require File.dirname(__FILE__) + '/../spec/version.rb'
require File.dirname(__FILE__) + '/ed2k/debug.rb'

# inputed invalid args, puts msg and halt
def invalid_args(msg)
  puts "#{msg}\n\n"
  puts $opts
  exit
end

$options = { :action => nil, :file => nil, :upcase => false, :debug => false }

$opts = OptionParser.new do |o|
  o.banner  = "ed2k version #{Ed2k::VERSION}\n"
  o.banner += "Copyright MIT license by <xdanger@gmail.com>\n\n"
  o.banner += "Usage: #{$0} [options] (hash|aich|link) FILENAME [FILENAME...]\n\n"
  o.separator "Action options:"
  o.separator "\thash - Hash file(s)"
  o.separator "\tlink - Get the ed2k link of the file(s)\n"
  o.separator "Common options:"
  o.on('-u', '--upcase', 'Return value is upcased') { $options[:upcase] = true }
  o.on('-d', '--debug', 'Turn on debug mode') { $options[:debug] = true }
  o.on('-h', '--help', "Display detailed help and exit") { puts o; exit }
  o.on('-v', '--version', "Show version") { puts Ed2k::VERSION; exit }  
end

def invalid_args
  $stderr.puts "Invalid Arguments"
  $stderr.puts ""
  puts $opts
  exit
end

begin
  $opts.parse!(ARGV)
rescue OptionParser::InvalidOption
  invalid_args
end

$action = ARGV.shift
invalid_args unless $action and ['hash', 'link'].include? $action
$files = ARGV
