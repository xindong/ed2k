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

require 'openssl'
include Ed2k

module Ed2k
  
  # block size of bytes by eDonkey2000/eMule
  BLOCK_BYTES = 9728000
  
  # hash a given data by separating them into blocks
  def Ed2k.hash(str)
    return '' if str.length == 0
    return OpenSSL::Digest::MD4.hexdigest(str) if str.length <= BLOCK_BYTES
    digests = []; offset = 0
    while offset < str.length
      digests << OpenSSL::Digest::MD4.digest(str[offset, BLOCK_BYTES])
      offset += BLOCK_BYTES
    end
    return OpenSSL::Digest::MD4.hexdigest(digests.join)
    # hash = OpenSSL::Digest::MD4.hexdigest(digests.join)
    # if hash.length is larger than BLOCK_BYTES .......
    # in eMule, BLOCK_BYTES = 9728000, 
    # then a file larger than 2957312000000 bytes (3TB) will cause the following happens
    # if BLOCK_BYTES = 1024000, then the line will be 32768000000 (3GB)
    # while hash.length > BLOCK_BYTES
    #  hash = hash(hash)
    # end
    # hash
  end
  
  # hash a file using IO.read function
  def Ed2k.hash_file(file)
    raise ArgumentError, "#{file} does not exists" unless File.exists?(file)
    bytes = File.size(file)
    puts "File size is #{bytes}" if debuging?
    return OpenSSL::Digest::MD4.hexdigest(File.read(file)) if bytes <= BLOCK_BYTES
    digests = []; offset = 0
    while offset < bytes
      block = ''
      while block.length == 0
        block = IO.read(file, BLOCK_BYTES, offset)
      end
      digests << OpenSSL::Digest::MD4.digest(block)
      if debuging?
        md4 = OpenSSL::Digest::MD4.hexdigest(block)
        puts "Block md4: #{md4} (offset: #{offset})"
        puts "Block counts: #{digests.length}"
      end
      offset += BLOCK_BYTES
    end
    OpenSSL::Digest::MD4.hexdigest(digests.join)
  end
  
  # hash a given data to generate the AICH string in eMule
  # NOT FINISHED
  def Ed2k.aich(data)
    ''
  end
  
  # hash a file to generate the AICH string in eMule
  # NOT FINISHED
  def Ed2k.aich_file(file)
    ''
  end
  
  # generate the ed2k of the file
  def Ed2k.build_ed2k(file)
    "ed2k://|#{CGI::escape(File.basename(file))}|#{File.size(file)}|#{hash_file(file)}|/"
  end
  
end
