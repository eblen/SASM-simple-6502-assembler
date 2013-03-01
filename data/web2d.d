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
