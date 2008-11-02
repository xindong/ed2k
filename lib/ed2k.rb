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
include Ed2k

module Ed2k
  
  # block size of bytes by eDonkey2000/eMule
  PART_BLOCK_BYTES = 9728000
  
  # each part is divided into 180 KB blocks
  # resulting in 53 blocks per part
  # and for each block a hash value is calculated using the SHA1 hash algorithm
  AICH_BLOCK_BYTES = 184320
  
  # hash a given data by separating them into blocks
  def Ed2k.hash(*args)
    str = args[0]
    return '' if str.length == 0
    return OpenSSL::Digest::MD4.hexdigest(str) if str.length <= PART_BLOCK_BYTES
    hash_sets = []; offset = 0
    while offset < str.length
      hash_sets << OpenSSL::Digest::MD4.digest(str[offset, PART_BLOCK_BYTES])
      offset += PART_BLOCK_BYTES
    end
    hash = OpenSSL::Digest::MD4.hexdigest(hash_sets.join)
    return hash.upcase if args[1].has_key? :upcase and args[:upcase]
    return hash
  end
  
  # hash a file using IO.read function
  def Ed2k.hash_file(*args)
    file = args[0]
    raise ArgumentError, "file does not exists" unless File.exists?(file)
    bytes = File.size(file)
    puts "File size is #{bytes}" if debuging?
    if bytes <= PART_BLOCK_BYTES
      hash = OpenSSL::Digest::MD4.hexdigest(File.read(file))
      return hash.upcase if args[1].has_key? :upcase and args[1][:upcase]
      return hash
    end
    hash_sets = []; offset = 0
    while offset < bytes
      block = ''
      block = IO.read(file, PART_BLOCK_BYTES, offset) while block.length == 0
      hash_sets << OpenSSL::Digest::MD4.digest(block)
      if debuging?
        md4 = OpenSSL::Digest::MD4.hexdigest(block)
        print "Block md4: #{md4} (offset: #{offset})"
        puts "Block counts: #{hash_sets.length}"
      end
      offset += PART_BLOCK_BYTES
    end
    hash = OpenSSL::Digest::MD4.hexdigest(hash_sets.join)
    return hash.upcase if args[1].has_key? :upcase and args[1][:upcase]
    return hash
  end
  
  # hash a given data to generate the AICH string in eMule
  # NOT FINISHED
  def Ed2k.aich(*args)
    ''
  end
  
  # hash a file to generate the AICH string in eMule
  def Ed2k.aich_file(*args)
    file = args[0]
    raise ArgumentError, "file does not exists" unless File.exists?(file)
    bytes = File.size(file)
    puts "file has #{(bytes.to_f / AICH_BLOCK_BYTES).ceil} aich block(s)" if debuging?
    offset = 0; hash_list = []
    while offset < bytes
      block = ''
      block = IO.read(file, PART_BLOCK_BYTES, offset) while block.length == 0
      hash_list << aich_one_part(block)
      puts "hash_list has #{hash_list.length} part(s)" if debuging?
      offset += PART_BLOCK_BYTES
    end
    aich = base32_encode aich_hash_tree(hash_list)
    return aich.upcase if args[1].has_key? :upcase and args[1][:upcase]
    return aich
  end
  
  # generate the ed2k of the file
  def Ed2k.build_ed2k(*args)
    file = args[0]
    hash = hash_file(file)
    hash = hash.upcase if args[1].include? :upcase and args[1][:upcase]
    aich = aich_file(file)
    aich = aich.upcase if args[1].include? :upcase and args[1][:upcase]
    "ed2k://|#{CGI::escape(File.basename(file))}|#{File.size(file)}|#{hash}|h=#{aich}|/"
  end
  
  private
  
  def Ed2k.aich_one_leaf(leaf)
    if leaf.length > AICH_BLOCK_BYTES
      raise SystemCallError, "aich_one_leaf with error data larger than AICH_BLOCK_BYTES"
    end
    return Digest::SHA1::digest(leaf)
  end
  
  #
  def Ed2k.aich_two_leaf(leaf1, leaf2)
    leaf1_sha1 = aich_one_leaf(leaf1)
    leaf2_sha1 = aich_one_leaf(leaf2)
    return aich_one_leaf(leaf1_sha1 + leaf2_sha1)
  end
  
  #
  def Ed2k.aich_hash_tree(hash_list)
    return hash_list[0] if hash_list.length == 1
    new_list = []
    last_leaf = nil
    hash_list.each do |l|
      ( last_leaf = l; next ) unless last_leaf
      new_list << aich_one_leaf(last_leaf + l)
      last_leaf = nil
    end
    new_list << last_leaf if last_leaf
    return aich_hash_tree(new_list)
  end
  
  #
  def Ed2k.aich_one_part(data)
    if data.length > PART_BLOCK_BYTES
      raise SystemCallError, 'aich one_part with data is larger than PART_BLOCK_BYTES'
    end
    offset = 0; last_aich = nil; hash_list = []
    while offset < data.length
      aich_data = data[offset, AICH_BLOCK_BYTES]
      if last_aich
        hash_list << aich_two_leaf(last_aich, aich_data)
        last_aich = nil
      else
        last_aich = aich_data
      end
      offset += AICH_BLOCK_BYTES
    end
    hash_list << aich_one_leaf(last_aich) if last_aich
    return aich_hash_tree(hash_list)
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
  
end
