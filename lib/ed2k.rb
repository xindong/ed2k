# The MIT License
# 
# Copyright (c) 2008 xdanger@gmail.com
# 
# http://www.opensource.org/licenses/mit-license.php
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'pp'
require 'digest'
require 'openssl'
require 'cgi'

module Ed2k
  
  # block size of bytes by eDonkey2000/eMule
  PART_BLOCK_BYTES = 9728000
  
  # each part is divided into 180 KB blocks
  # resulting in 53 blocks per part
  # and for each block a hash value is calculated using the SHA1 hash algorithm
  AICH_BLOCK_BYTES = 184320
  
  # hash a file using IO.read function
  def Ed2k.hash_file(*args)
    file = args[0]
    raise ArgumentError, "File does not exists" unless File.exists?(file)
    bytes = File.size(file)
    puts "File size is #{bytes}" if Ed2k.debuging?
    hash = ''
    if File.size(file) < Ed2k::PART_BLOCK_BYTES
      hash = OpenSSL::Digest::MD4.hexdigest(File.read(file))
    else
      hash_sets = []
      Ed2k.walk_file(file, Ed2k::PART_BLOCK_BYTES) do |block|
        hash_sets << OpenSSL::Digest::MD4.digest(block)
        puts "#{hash_sets.length}:\t#{OpenSSL::Digest::MD4.hexdigest(block)}" if Ed2k.debuging?
      end
      hash = OpenSSL::Digest::MD4.hexdigest(hash_sets.join)
    end
    return hash.upcase if args[1].has_key? :upcase and args[1][:upcase]
    return hash
  end
  
  # generate the AICH string of a file in eMule
  def Ed2k.aich_file(*args)
    file = args[0]
    raise ArgumentError, 'File does not exists' unless File.exists?(file)
    bytes = File.size(file)
    puts "File has #{(bytes.to_f / Ed2k::AICH_BLOCK_BYTES).ceil} aich block(s)" if Ed2k.debuging?
    hash_sets = []
    Ed2k.walk_file(file, Ed2k::PART_BLOCK_BYTES) do |block|
      row = Ed2k.aich_part(block)
      hash_sets << row if row
      puts "hash_sets has #{hash_sets.length} part(s)" if Ed2k.debuging?
    end
    aich = Ed2k.base32_encode Ed2k.aich_hashsets(hash_sets)
    return aich.upcase if args[1].has_key? :upcase and args[1][:upcase]
    return aich
  end
  
  # generate the ed2k of the file
  def Ed2k.build_ed2k(*args)
    file = args[0]
    hash = Ed2k.hash_file(args[0], :upcase => args[1][:upcase])
#    aich = Ed2k.aich_file(args[0], :upcase => args[1][:upcase])
    "ed2k://|#{CGI::escape(File.basename(file))}|#{File.size(file)}|#{hash}|/"
  end
  
  private
  
  def Ed2k.aich_leaf(leaf)
    if leaf.length > Ed2k::AICH_BLOCK_BYTES
      raise SystemCallError, "Ed2k.aich_leaf with error data larger than Ed2k::AICH_BLOCK_BYTES"
    end
    return Digest::SHA1::digest(leaf)
  end
  
  #
  def Ed2k.aich_hashsets(hash_sets)
    raise SystemCallError, "hash_sets.length = 0" if hash_sets.length == 0
    return hash_sets[0] if hash_sets.length == 1
    new_sets = []
    last_leaf = nil
    hash_sets.each do |l|
      ( last_leaf = l; next ) unless last_leaf
      new_sets << Ed2k.aich_leaf(last_leaf + l)
      last_leaf = nil
    end
    new_sets << last_leaf if last_leaf
    return Ed2k.aich_hashsets(new_sets)
  end
  
  #
  def Ed2k.aich_part(data)
    if data.length > Ed2k::PART_BLOCK_BYTES
      raise SystemCallError, 'Ed2k.one_part with data is larger than Ed2k::PART_BLOCK_BYTES'
    end
    offset = 0; last_aich = nil; hash_sets = []
    Ed2k.walk_string(data, Ed2k::AICH_BLOCK_BYTES) do |aich_data|
      if last_aich
        leaf1_sha1 = Ed2k.aich_leaf(last_aich)
        leaf2_sha1 = Ed2k.aich_leaf(aich_data)
        hash_sets << Ed2k.aich_leaf(leaf1_sha1 + leaf2_sha1)
        last_aich = nil
      else
        last_aich = aich_data
      end
    end
    hash_sets << Ed2k.aich_leaf(last_aich) if last_aich
    return Ed2k.aich_leaf('') if hash_sets.length == 0
    return Ed2k.aich_hashsets(hash_sets)
  end
  
  #
  BASE32_ALPHABET = 'abcdefghijklmnopqrstuvwxyz234567'
  def Ed2k.base32_encode(input)
    # input.unpack('a2' * (input.size / 2)).collect {|i| i.hex.chr }.join unless input.is_binary_data?
    output = ''
    posistion = 0
    stored_data = 0
    stored_bit_count = 0
    index = 0
    while index < input.length
      stored_data <<= 8
      stored_data += input[index]
      stored_bit_count += 8
      index += 1
      while stored_bit_count >= 5
        stored_bit_count -= 5
        output << BASE32_ALPHABET[stored_data >> stored_bit_count]
        stored_data &= ((1 << stored_bit_count) - 1)
      end
    end
    if stored_bit_count > 0
      stored_data << (5 - stored_bit_count)
      output << BASE32_ALPHABET[stored_data]
    end
    output
  end
  
  #
  def Ed2k.walk_string(string, step, &block)
    offset = 0
    while offset < string.length
      yield string[offset, step]
      offset += step
    end
  end
  
  #
  def Ed2k.walk_file(file, step, &block)
    offset = 0
    while offset < File.size(file)
      block = ''
      block = IO.read(file, step, offset)
      yield block
      offset += step
    end
    yield '' if offset == File.size(file)
  end
  
end
