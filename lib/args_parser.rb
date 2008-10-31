require 'optparse'
require File.expand_path(File.dirname(__FILE__)) + '/../spec/version.rb'

module Ed2k
  
  # is debuging model?
  def debuging?
    $options[:debug]
  end
    
end

# inputed invalid args, puts msg and halt
def invalid_args(msg)
  puts "#{msg}\n\n"
  puts $opts
  exit
end

$options = { :action => nil, :file => nil, :debug => false }

$opts = OptionParser.new do |o|
  o.banner  = "ed2k version #{Ed2k::VERSION}\n"
  o.banner += "Copyright MIT license by <xdanger@gmail.com>\n\n"
  o.banner += "Usage: ed2k -a hash -f FILENAME\n"
  o.banner += "  or   ed2k -a aich -f FILENAME (currently no available -_-)\n"
  o.banner += "  or   ed2k -a link -f FILENAME\n"
  o.separator "\nCommon options:"
  o.on('-a', '--action [ACTION]', [:hash, :aich, :link],
       'Set action (hash, aich, link)') { |a| $options[:action] = a }
  o.on('-f', '--file [FILE]', 'File to process') { |f| $options[:file] = f }
  o.separator "\nSpecific options:"
  o.on_tail('-d', '--debug', 'Turn on debug mode') { $options[:debug] = true }
  o.on_tail('-h', '--help', "Display detailed help and exit") { puts o; exit }
  o.on_tail('-v', '--version', "Show version") { puts Ed2k::VERSION; exit }
end

begin
  $opts.parse!(ARGV)
rescue OptionParser::InvalidOption
  puts "INVALID ARGS"
  puts ""
  puts $opts
  exit
end

invalid_args '-a --action is required' unless $options[:action]
invalid_args '-f --file is required'   unless $options[:file]
