#!/usr/local/dmd/bin/rdmd

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
      opcode = to!string(line[0..3]).toLower();
      writeln("   \"" ~ opcode ~ "\":" ~ opcode ~ "info");
    }
  }
}
