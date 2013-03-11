import std.c.stdlib;
import std.conv;
import std.stdio;
import std.string;
import proc6502;

class InvalidHexNumberException : Exception {this(string hex) {super("Invalid hex number: " ~ hex);}}

static ubyte[char] hex2val;

ubyte hexToByte(const char[2] hex)
{
  if (hex[0] !in hex2val || hex[1] !in hex2val) throw new InvalidHexNumberException(to!string(hex));
  return cast(ubyte)(16*hex2val[hex[0]] + hex2val[hex[1]]);
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

  int line_num = 1;
  ubyte[] machine_code;

  init6502();
  foreach(char[] line; stdin.byLine())
  {
    scope(exit) line_num++;

    // Remove comments
    auto cbegin = indexOf(line, ';');
    if (cbegin > -1) line = line[0..cbegin];

    // Split into tokens
    char[][] parts = std.string.split(line);
    if (parts.length == 0) continue;
    if (parts.length == 1)
    {
      writefln("Error at line %s: Single token not allowed", line_num);
      exit(1);
    }

    string mnemonic = to!string(toLower(parts[0]));
    string ops = to!string(toLower(parts[1]));
    switch(mnemonic)
    {
      case "data":
        if (ops.length / 2 == 1)
        {
          writefln("Invalid data at line %s", line_num);
          exit(1);
        }
        for (int i=0; i<ops.length; i += 2)
        {
          char[2] hex;
          hex[0] = ops[i];
          hex[1] = ops[i+1];
          machine_code ~= hexToByte(hex);
        }
    }
  }

  writeln(machine_code);
}
