# Copyright 2008 xdanger@gmail.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'openssl'

module Ed2k
  
  # block size of bytes by eDonkey2000/eMule
  BLOCK_BYTES = 9728000
  
  # hash a given data by separating them into blocks
  def Ed2k::hash(str)
    return '' if str.length == 0
    return OpenSSL::Digest::MD4.hexdigest(str) if str.length <= Ed2k::BLOCK_BYTES
    digests = []; offset = 0
    while offset < str.length
      digests << OpenSSL::Digest::MD4.digest(str[offset, Ed2k::BLOCK_BYTES])
      offset += Ed2k::BLOCK_BYTES
    end
    return OpenSSL::Digest::MD4.hexdigest(digests.join)
    # hash = OpenSSL::Digest::MD4.hexdigest(digests.join)
    # if hash.length is larger than Ed2k::BLOCK_BYTES .......
    # in eMule, BLOCK_BYTES = 9728000, 
    # then a file larger than 2957312000000 bytes (3TB) will cause the following happens
    # if BLOCK_BYTES = 1024000, then the line will be 32768000000 (3GB)
    # while hash.length > Ed2k::BLOCK_BYTES
    #  hash = Ed2k::hash(hash)
    # end
    # hash
  end
  
  # hash a file using IO.read function
  def Ed2k::hash_file(file)
    raise ArgumentError, "#{file} does not exists" unless File.exists?(file)
    bytes = File.size(file)
    puts "File size is #{bytes}" if debuging?
    return OpenSSL::Digest::MD4.hexdigest(File.read(file)) if bytes <= Ed2k::BLOCK_BYTES
    digests = []; offset = 0
    while offset < bytes
      block = ''
      while block.length == 0
        block = IO.read(file, Ed2k::BLOCK_BYTES, offset)
      end
      digests << OpenSSL::Digest::MD4.digest(block)
      if debuging?
        md4 = OpenSSL::Digest::MD4.hexdigest(block)
        puts "Block md4: #{md4} (offset: #{offset})"
        puts "Block counts: #{digests.length}"
      end
      offset += Ed2k::BLOCK_BYTES
    end
    OpenSSL::Digest::MD4.hexdigest(digests.join)
  end
  
  # hash a given data to generate the AICH string in eMule
  # NOT FINISHED
  def Ed2k::aich(data)
    ''
  end
  
  # hash a file to generate the AICH string in eMule
  # NOT FINISHED
  def Ed2k::aich_file(file)
    ''
  end
  
  # generate the ed2k of the file
  def Ed2k::build_ed2k(file)
    "ed2k://|#{CGI::escape(File.basename(file))}|#{File.size(file)}|#{Ed2k::hash_file(file)}|/"
  end
  
end
