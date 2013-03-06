// John Eblen
// March 2, 2013
// Script to convert machine language moo program to new assembler format

import std.algorithm;
import std.conv;
import std.regex;
import std.stdio;
import std.string;
import proc6502;

void main()
{
  init6502();
  ubyte[char] hex2val =
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

  foreach(char[] line; stdin.byLine())
  {
    if (line.length < 1) {writeln(); continue;}

    char[][] parts = std.string.split(line, ";");
    string code = to!string(parts[0]).toLower();
    string comment = "";
    if (parts.length > 1) comment = to!string(';' ~ parts[1]);

    if (startsWith(code, "@\'")) code = "zbyte " ~ code[2..$];
    else if (startsWith(code, "@")) code = '.' ~ code[1..$];
    else
    {
      // TODO: Figure out why this alone doesn't work and why &' => .'
      // auto re = regex(r"[&'*|#]");
      // but if &'* is used by itself, both & and &' => .
      auto re = regex(r"&'*");
      code = replace(code, re, ".");
      re = regex(r"#");
      code = replace(code, re, ".");
      if (code.length > 1 && code[2] == ' ')
      {
        ubyte opcode = cast(ubyte)(16*hex2val[code[0]] + hex2val[code[1]]);
        try
        {
          string mnemonic = proc6502.mnemonic(opcode);
          while (mnemonic.length < 5) mnemonic = mnemonic ~ " ";
          code = mnemonic ~ code[2..$];
        }
        catch(InvalidOpcodeException e)
        {
          // TODO: Figure out how to write to stderr!
          // writefln(stderr, "Ignored invalid opcode on line: " ~ line);
        }
      }
    }
    write(code);
    writeln(comment);
  }
}
