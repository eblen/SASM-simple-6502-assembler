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
      opcode = to!string(line[0..3]).toLower();
      writeln("   \"" ~ opcode ~ "\":" ~ opcode ~ "info");
    }
  }
}
