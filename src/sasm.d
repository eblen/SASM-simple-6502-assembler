import std.c.stdlib;
import std.conv;
import std.stdio;
import std.string;
import proc6502;
import zpm;

class InvalidHexNumberException : Exception {this(string hex) {super("Invalid hex number: " ~ hex);}}

static ubyte[char] hex2val;

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
  ushort org = 2560;
  ubyte[] machine_code;
  ushort[string] labelToAddr;
  string[ushort] absAddrRef;
  string[ushort] relAddrRef;
  string[ushort] zpAddrRef;
  auto zpm = new SimpleAppleIIZeroPageManager();

  init6502();
  foreach(char[] line; stdin.byLine())
  {
    scope(exit) line_num++;

    // Remove comments
    auto cbegin = indexOf(line, ';');
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

    // Raw data
    if (mnemonic == "data")
    {
      if (op1.length % 2 == 1)
      {
        writefln("Invalid data at line %s", line_num);
        exit(1);
      }
      for (int i=0; i<op1.length; i += 2)
      {
        machine_code ~= hexToByte(op1[i..i+2]);
      }
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

    // Label
    else if (mnemonic[0] == '.') labelToAddr[mnemonic[1..$]] = cast(ushort)(org + machine_code.length);

    // Instruction
    else
    {
      machine_code ~= proc6502.hexcode(mnemonic);

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
          machine_code ~= hexToByte(op1[i..i+2]);
        }
      }

      // op1 is a label
      // TODO: Handle indirect offsets
      else
      {
        ushort codeIndex = cast(ushort)(machine_code.length);
        string label = op1[1..$];
        final switch(proc6502.addrtype(mnemonic))
        {
          case ADDR_TYPE.ABS:
            absAddrRef[codeIndex] = label;
            machine_code ~= 0;
            machine_code ~= 0;
            break;
          case ADDR_TYPE.IND:
            writefln("Error - indirect addressing mode not yet supported at line %s", line_num);
            exit(1);
            break;
          case ADDR_TYPE.NONE:
            writefln("Error - label not applicable for instruction at line %s", line_num);
            exit(1);
            break;
          case ADDR_TYPE.REL:
            relAddrRef[codeIndex] = label;
            machine_code ~= 0;
            break;
          case ADDR_TYPE.ZP:
            zpAddrRef[codeIndex] = label;
            machine_code ~= 0;
            break;
        }
      }
    }
  }

  // Insert address values

  // Absolute addresses
  foreach (codeIndex, label; absAddrRef)
  {
    if (label !in labelToAddr)
    {
      writefln("Undefined absolute address label: %s", label);
      exit(1);
    }
    ushort addr = labelToAddr[label];
    machine_code[codeIndex] = cast(ubyte)(addr >> 8);
    machine_code[codeIndex+1] = cast(ubyte)(addr & 0x00FF);
  }

  // Relative branch offsets
  foreach (codeIndex, label; relAddrRef)
  {
    if (label !in labelToAddr)
    {
      writefln("Undefined branching label: %s", label);
      exit(1);
    }
    ushort addr = labelToAddr[label];
    int offset = addr - (org + codeIndex);
    assert((offset >= -128) && (offset <= 127));
    machine_code[codeIndex] = cast(ubyte)offset;
  }

  // Zero page addresses
  foreach (codeIndex, label; zpAddrRef)
  {
    if (label !in labelToAddr)
    {
      writefln("Undefined zero page address label: %s", label);
      exit(1);
    }
    ushort addr = labelToAddr[label];
    assert(addr < 256);
    machine_code[codeIndex] = cast(ubyte)addr;
  }
  writeln(machine_code);
}
