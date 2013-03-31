/********************************************************************
 SASM (Simple Assembler) for 6502 and related processors
 Copyright (C) 2013 John Eblen

 This file is part of SASM.

 SASM is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 SASM is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with SASM.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************/

import std.algorithm;
import std.c.stdlib;
import std.conv;
import std.stdio;
import std.string;
import proc6502;
import zpm;

class InvalidHexNumberException : Exception {this(string hex) {super("Invalid hex number: " ~ hex);}}

static ubyte[char] hex2val;
static char[ubyte] val2hex;

ubyte hexToByte(string hex)
{
  if (hex.length != 2) throw new InvalidHexNumberException(to!string(hex));
  char hex_char[2];
  hex_char[0] = hex[0];
  hex_char[1] = hex[1];
  return hexToByte(hex_char);
}

ubyte hexToByte(const char[2] hex)
{
  if (hex[0] !in hex2val || hex[1] !in hex2val) throw new InvalidHexNumberException(to!string(hex));
  return cast(ubyte)(16*hex2val[hex[0]] + hex2val[hex[1]]);
}

string byteToHex(ubyte b)
{
  char[2] hex;

  hex[0] = val2hex[b >> 4];
  hex[1] = val2hex[b & 0x0F];
  return to!string(hex);
}

struct code_seg
{
  ushort org;
  ubyte[] code;
  string[ushort] absAddrRef;
  string[ushort] relAddrRef;
  string[ushort] zpAddrRef;
}

void main()
{
  hex2val =
  [
    '0':0,
    '1':1,
    '2':2,
    '3':3,
    '4':4,
    '5':5,
    '6':6,
    '7':7,
    '8':8,
    '9':9,
    'a':10,
    'b':11,
    'c':12,
    'd':13,
    'e':14,
    'f':15,
  ];

  val2hex =
  [
    0:'0',
    1:'1',
    2:'2',
    3:'3',
    4:'4',
    5:'5',
    6:'6',
    7:'7',
    8:'8',
    9:'9',
    10:'a',
    11:'b',
    12:'c',
    13:'d',
    14:'e',
    15:'f',
  ];

  code_seg[] code_blocks;
  ushort[string] labelToAddr;
  auto zpm = new SimpleAppleIIZeroPageManager();

  init6502();
  code_seg* cs = null;
  int line_num = 1;
  foreach(char[] line; stdin.byLine())
  {
    scope(exit) line_num++;

    // Remove comments
    auto cbegin = std.string.indexOf(line, ';');
    if (cbegin > -1) line = line[0..cbegin];

    // Create tokens: mnemonic op1 op2
    char[][] parts = std.string.split(line);
    if (parts.length == 0) continue;
    string mnemonic = to!string(toLower(parts[0]));
    string op1 = "";
    if (parts.length > 1) op1 = to!string(toLower(parts[1]));
    string op2 = "";
    if (parts.length > 2) op2 = to!string(toLower(parts[2]));

    // Start processing line

    // org - specify address where program will be loaded
    if (mnemonic == "org")
    {
      if (op1.length < 1 || op1.length > 4)
      {
        writefln("Invalid org address at line %s", line_num);
        exit(1);
      }
      while (op1.length < 4) op1 = "0" ~ op1;

      // Create new code segment
      ++code_blocks.length;
      cs = &code_blocks[$-1];
      cs.org = 256*hexToByte(op1[0..2]) + hexToByte(op1[2..$]);
    }

    // Request for zbyte
    else if (mnemonic == "zbyte")
    {
      ubyte alloc_size = 1;
      if (op1 == "")
      {
        writefln("Error - zbyte without arguments at line %s", line_num);
        exit(1);
      }
      if (op2 != "") alloc_size = to!ubyte(op2);
      labelToAddr[op1] = zpm.alloc(alloc_size);
    }

    // Enforce that an "org" occurs before all other commands except "zbyte".
    else if (code_blocks.length == 0)
    {
      writeln("Error - org required before all other commands except zbyte");
      exit(1);
    }

    // Raw data
    else if (mnemonic == "data")
    {
      if (op1.length % 2 == 1)
      {
        writefln("Invalid data at line %s", line_num);
        exit(1);
      }
      for (int i=0; i<op1.length; i += 2)
      {
        cs.code ~= hexToByte(op1[i..i+2]);
      }
    }

    // Label
    else if (mnemonic[0] == '.') labelToAddr[mnemonic[1..$]] = cast(ushort)(cs.org + cs.code.length);

    // Instruction
    else
    {
      cs.code ~= proc6502.bytecode(mnemonic);

      // op1 is either absent or not a label
      if (op1 == "" || op1[0] != '.')
      {
        if (op1.length != 2*(proc6502.numbytes(mnemonic)-1))
        {
          writefln("Error - wrong instruction length at line %s", line_num);
          exit(1);
        }
        for (int i=0; i<op1.length; i += 2)
        {
          cs.code ~= hexToByte(op1[i..i+2]);
        }
      }

      // op1 is a label
      else
      {
        ushort codeIndex = cast(ushort)(cs.code.length);
        string label = op1[1..$];
        final switch(proc6502.addrtype(mnemonic))
        {
          case ADDR_TYPE.ABS:
            cs.absAddrRef[codeIndex] = label;
            cs.code ~= 0;
            cs.code ~= 0;
            break;
          case ADDR_TYPE.IND:
            if (mnemonic == "jmpn")
            {
              cs.absAddrRef[codeIndex] = label;
              cs.code ~= 0;
              cs.code ~= 0;
            }
            else
            {
              cs.zpAddrRef[codeIndex] = label;
              cs.code ~= 0;
            }
            break;
          case ADDR_TYPE.NONE:
            writefln("Error - label not applicable for instruction at line %s", line_num);
            exit(1);
            break;
          case ADDR_TYPE.REL:
            cs.relAddrRef[codeIndex] = label;
            cs.code ~= 0;
            break;
          case ADDR_TYPE.ZP:
            cs.zpAddrRef[codeIndex] = label;
            cs.code ~= 0;
            break;
        }
      }
    }
  }

  // Insert address values
  foreach (code_seg cb; code_blocks)
  {
    // Absolute addresses
    foreach (codeIndex, label; cb.absAddrRef)
    {
      if (label !in labelToAddr)
      {
        writefln("Undefined absolute address label: %s", label);
        exit(1);
      }
      ushort addr = labelToAddr[label];
      // Little endian architecture
      cb.code[codeIndex] = cast(ubyte)(addr & 0x00FF);
      cb.code[codeIndex+1] = cast(ubyte)(addr >> 8);
    }

    // Relative branch offsets
    foreach (codeIndex, label; cb.relAddrRef)
    {
      if (label !in labelToAddr)
      {
        writefln("Undefined branching label: %s", label);
        exit(1);
      }
      ushort addr = labelToAddr[label];
      int offset = addr - 1 - (cb.org + codeIndex);
      assert((offset >= -128) && (offset <= 127));
      cb.code[codeIndex] = cast(ubyte)offset;
    }

    // Zero page addresses
    foreach (codeIndex, label; cb.zpAddrRef)
    {
      if (label !in labelToAddr)
      {
        writefln("Undefined zero page address label: %s", label);
        exit(1);
      }
      ushort addr = labelToAddr[label];
      assert(addr < 256);
      cb.code[codeIndex] = cast(ubyte)addr;
    }
  }
  sort!("a.org < b.org")(code_blocks);
  outputAppleIISystemMonitorInput(code_blocks);
}

void outputAppleIISystemMonitorInput(in code_seg[] code_blocks)
{
  foreach (const code_seg cs; code_blocks)
  {
    int byteNum = 0;
    string loadAddrHex;
    ushort loadAddr = cs.org;
    foreach (ubyte b; cs.code)
    {
      if (byteNum % 83 == 0)
      {
        loadAddrHex = byteToHex(cast(ubyte)(loadAddr >> 8)) ~ byteToHex(cast(ubyte)(loadAddr & 0x00FF));
        while ((loadAddrHex.length > 1) && (loadAddrHex[0] == '0')) loadAddrHex = loadAddrHex[1..$];
        if (byteNum > 0) writeln();
        writef("%s:", loadAddrHex);
        loadAddr += 83;
      }
      writef("%s ", byteToHex(b));
      byteNum++;
    }
    writeln();
  }
}
