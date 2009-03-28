#!/usr/bin/env ruby

$root_dir = File.expand_path(File.dirname(__FILE__) + '/..')
$: << $root_dir + '/lib'

module Ed2k
  UNITTEST_DEST = YAML::load_file $root_dir + '/test/dest.yml'
  def Ed2k.debuging?
    return false
  end
end

$options = { :debug => false }

require 'pp'
require 'ed2k'

def colorize(text, color_code); "#{color_code}#{text}\e[0m"; end
def red_text(text)    ; colorize(text, "\e[31m"); end
def green_text(text)  ; colorize(text, "\e[32m"); end
def yellow_text(text) ; colorize(text, "\e[33m"); end
def blue_text(text)   ; colorize(text, "\e[34m"); end
def magenta_text(text); colorize(text, "\e[35m"); end
def cyan_text(text)   ; colorize(text, "\e[36m"); end
def red_bg(text)    ; colorize(text, "\e[41m"); end
def green_bg(text)  ; colorize(text, "\e[42m"); end
def yellow_bg(text) ; colorize(text, "\e[43m"); end
def blue_bg(text)   ; colorize(text, "\e[44m"); end
def magenta_bg(text); colorize(text, "\e[45m"); end
def cyan_bg(text)   ; colorize(text, "\e[46m"); end

passed, failed = [0, 0]
Ed2k::UNITTEST_DEST.each do |file|
  bytes, md5s, hash, aich = file['size'].to_s, file['md5s'], file['hash'], file['aich']
  _md5s = Ed2k.md5s_file("#{$root_dir}/test/data/#{bytes}-bytes", { :debug => false, :upcase => true })
  _md5s = _md5s.upcase.strip
  if md5s != _md5s
    failed += 1
    $stderr.puts "MD5S file\t#{yellow_text(bytes + '-bytes' )}\t\t[ #{red_text('Failed')} ]"
    $stderr.puts "\tDeserved: #{cyan_text(md5s)}"
    $stderr.puts "\tReturned: #{magenta_text(_md5s)}"
  else
    passed += 1
    $stderr.puts "MD5S file\t#{yellow_text(bytes + '-bytes' )}\t\t[   #{green_text('OK')}   ]"
  end
#  _hash = `#{$root_dir}/bin/ed2k -a hash -uf #{$root_dir}/test/data/#{bytes}-bytes`
  _hash = Ed2k.hash_file("#{$root_dir}/test/data/#{bytes}-bytes", { :debug => false, :upcase => true })
  _hash = _hash.upcase.strip
  if hash != _hash
    failed += 1
    $stderr.puts "Hash file\t#{yellow_text(bytes + '-bytes' )}\t\t[ #{red_text('Failed')} ]"
    $stderr.puts "\tDeserved: #{cyan_text(hash)}"
    $stderr.puts "\tReturned: #{magenta_text(_hash)}"
  else
    passed += 1
    $stderr.puts "Hash file\t#{yellow_text(bytes + '-bytes' )}\t\t[   #{green_text('OK')}   ]"
  end
#  _aich = `#{$root_dir}/bin/ed2k -a aich -uf #{$root_dir}/test/data/#{bytes}-bytes`
  _aich = Ed2k.aich_file("#{$root_dir}/test/data/#{bytes}-bytes", { :debug => false, :upcase => true })
  _aich = _aich.upcase.strip
  if aich != _aich
    failed += 1
    $stderr.puts "AICH file\t#{yellow_text(bytes + '-bytes' )}\t\t[ #{red_text('Failed')} ]"
    $stderr.puts "\tDeserved:\t#{cyan_text(aich)}"
    $stderr.puts "\tReturned:\t#{magenta_text(_aich)}"
  else
    passed += 1
    $stderr.puts "Hash file\t#{yellow_text(bytes + '-bytes' )}\t\t[   #{green_text('OK')}   ]"
  end
  $stderr.puts ""
end

if failed == 0
  puts "Test OK"
  exit 0
else
  puts "Test Failed - #{failed}/#{passed + failed} Failed (See above information)"
  exit 1
end