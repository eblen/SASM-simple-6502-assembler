#!/usr/bin/ruby

#********************************************************************
# SASM (Simple Assembler) for 6502 and related processors
# Copyright (C) 2013 John Eblen

# This file is part of SASM.

# SASM is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# SASM is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with SASM.  If not, see <http://www.gnu.org/licenses/>.
#********************************************************************/

# Original ruby script used to convert machine language (.ml)
# programs to system monitor format:
# ./ml2sm.rb < ./moo.ml
# Created prior to SASM.

class ZeroPageManager
  def initialize()
    @nextAddress = ('ff'.to_i 16) + 1;
  end
  def getAddress(size=1)
    @nextAddress = @nextAddress - size
    @nextAddress
  end
end

def ExtendMC(code, hex)
  for i in 0..(hex.length / 2 - 1)
    code.push(hex.slice(i*2,2))
  end
end

def ByteToHex(byte)
  if byte >= 0
    byte.to_s 16
  else
    (256 + byte).to_s 16
  end
end

org = 'A00'.to_i 16
byteIndex = 0
machineCode = []
codeOffsets = {}
addressMap = {}
zpm = ZeroPageManager.new()

ARGF.each_line do |line|
  line.slice!(/;.*/)
  tokens = line.split(" ")
  for t in tokens
    if t.match(/^@'/)
      t.slice!(/^@'/)
      parts = t.split(/,/)
      if (parts.length > 1)
        size = parts[1]
      else
        size = 1
      end
      addressMap[parts[0]] = zpm.getAddress(size.to_i)
    elsif t.match(/^@/)
      t.slice!(/^@/)
      addressMap[t] = byteIndex + org
    elsif t.match(/^#/)
      t.slice!(/^#/)
      codeOffsets[t] ||= []
      codeOffsets[t] << byteIndex
      ExtendMC(machineCode, "rr")
      byteIndex += 1
    elsif t.match(/^&'/)
      t.slice!(/^&'/)
      codeOffsets[t] ||= []
      codeOffsets[t] << byteIndex
      ExtendMC(machineCode, "zz")
      byteIndex += 1
    elsif t.match(/^&/)
      t.slice!(/^&/)
      codeOffsets[t] ||= []
      codeOffsets[t] << byteIndex
      ExtendMC(machineCode, "mmmm")
      byteIndex += 2
    else
      ExtendMC(machineCode, t)
      byteIndex += t.length / 2
    end
  end
end

codeOffsets.each_key do |addrName|
  # puts "Address name is #{addrName}"
  codeOffsets[addrName].each do |byteIndex|
    # puts "MC Index is #{byteIndex}"
    addr = addressMap[addrName]
    # puts "Address is #{addr}"
    if (addr == nil)
      abort("Undefined address #{addrName}")
    end
    addrHex = (addr.to_s 16)
    while addrHex.length < 4
      addrHex = '0' + addrHex
    end
    if (machineCode[byteIndex] == 'rr')
      byteValue = addr - (byteIndex + org) - 1
      # puts "Jump to #{addrName} of #{byteValue} bytes"
      if byteValue > 127 || byteValue < -127
        abort("Relative jump to #{addrName} is too far: #{byteValue} bytes")
      end
      hexDiffString = ByteToHex(byteValue)
      while hexDiffString.length < 2
        hexDiffString = '0' + hexDiffString
      end
      hexDiff = hexDiffString.split("")
      machineCode[byteIndex] = hexDiff
    elsif (machineCode[byteIndex] == 'zz')
      machineCode[byteIndex] = addrHex.slice(2,2)
    elsif (machineCode[byteIndex] == 'mm')
      machineCode[byteIndex+1] = addrHex.slice(0,2)
      machineCode[byteIndex] = addrHex.slice(2,2)
    else
      puts machineCode
      abort("Internal error - invalid address byte number")
    end
  end
end

byteIndex = 0
orgHex = org.to_s 16
print "#{orgHex}:"
machineCode.each do |c|
  print c
  print " "
  byteIndex += 1
  if byteIndex % 83 == 0
    print "\n"
    org += 83
    orgHex = org.to_s 16
    print "#{orgHex}:"
  end
end
