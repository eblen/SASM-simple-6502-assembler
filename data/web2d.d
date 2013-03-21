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

#!/usr/local/dmd/bin/rdmd

import std.conv;
import std.regex;
import std.stdio;
import std.string;

void main()
{
  string opcode;
  foreach (line; stdin.byLine())
  {
    // New opcode found
    if (match(line, r"^[A-Z][A-Z][A-Z]\s+\("))
    {
      // End previous opcode
      if (opcode != "")
      {
        writeln("  ]);");
        writeln();
      }

      // Begin new opcode
      opcode = to!string(line[0..3]).toLower();
      writeln("  opinfo " ~ opcode ~ "info = opinfo(");
      writeln("  \"" ~ opcode ~ "\",");
      writeln("  [");

      // Opcodes without modifiers
      string[] parts = std.string.split(to!string(line));
      if (match(parts[$-1], r"^\$"))
      {
        string hexcode = "0x" ~ parts[$-1][1..$];
        writeln("    NOFLAGS:" ~ hexcode ~ ",");
      }
      if (match(parts[$-2], r"^\$"))
      {
        string hexcode = "0x" ~ parts[$-2][1..$];
        writeln("    NOFLAGS:" ~ hexcode ~ ",");
      }
    }

    else
    {
      string[] parts = std.string.split(to!string(line));
      if (parts.length < 6) continue;
      
      string hexcode = "0x" ~ parts[3][1..$];
      // Special handling of "Zero Page", which has a space in it
      if (parts[0] == "Zero")
      {
        parts[0] = parts[0] ~ parts[1];
        hexcode = "0x" ~ parts[4][1..$];
      }
      switch(parts[0])
      {
        case "Accumulator":
          writeln("    NOFLAGS:" ~ hexcode ~ ",");
          break;
        case "Immediate":
          writeln("    IMMEDIATE:" ~ hexcode ~ ",");
          break;
        case "ZeroPage":
          writeln("    ZEROPAGE:" ~ hexcode ~ ",");
          break;
        case "ZeroPage,X":
          writeln("    ZEROPAGE | XREG:" ~ hexcode ~ ",");
          break;
        case "ZeroPage,Y":
          writeln("    ZEROPAGE | YREG:" ~ hexcode ~ ",");
          break;
        case "Absolute":
          writeln("    ABSOLUTE:" ~ hexcode ~ ",");
          break;
        case "Absolute,X":
          writeln("    ABSOLUTE | XREG:" ~ hexcode ~ ",");
          break;
        case "Absolute,Y":
          writeln("    ABSOLUTE | YREG:" ~ hexcode ~ ",");
          break;
        case "Indirect":
          writeln("    INDIRECT:" ~ hexcode ~ ",");
          break;
        case "Indirect,X":
          writeln("    INDIRECT | XREG:" ~ hexcode ~ ",");
          break;
        case "Indirect,Y":
          writeln("    INDIRECT | YREG:" ~ hexcode ~ ",");
          break;
        default:
      }
    }
  }

  // End last opcode
  writeln("  ]);");
  writeln();
}
