import std.stdio;
import std.string;

// Basic data structures

// Encodings for instructions and their modifiers (flags)
alias ubyte opcode;
alias ubyte opflag;
const opflag NOFLAGS   = 0b00000000;
const opflag IMMEDIATE = 0b00010000;
const opflag ZEROPAGE  = 0b00100000;
const opflag ABSOLUTE  = 0b01000000;
const opflag INDIRECT  = 0b10000000;
const opflag XREG      = 0b00000001;
const opflag YREG      = 0b00000010;

// Main struct for storing numerical encodings for instructions and their flags
private struct opinfo
{
  string instr;
  opcode[opflag] codemap;
}

// Main lookup tables
private opflag[char] flagmap;
private opinfo[string] infomap;

// Declaration of info struct for each 6502 instruction
private opinfo adcinfo;
private opinfo andinfo;
private opinfo aslinfo;
private opinfo bccinfo;
private opinfo bcsinfo;
private opinfo beqinfo;
private opinfo bitinfo;
private opinfo bmiinfo;
private opinfo bneinfo;
private opinfo bplinfo;
private opinfo brkinfo;
private opinfo bvcinfo;
private opinfo bvsinfo;
private opinfo clcinfo;
private opinfo cldinfo;
private opinfo cliinfo;
private opinfo clvinfo;
private opinfo cmpinfo;
private opinfo cpxinfo;
private opinfo cpyinfo;
private opinfo decinfo;
private opinfo dexinfo;
private opinfo deyinfo;
private opinfo eorinfo;
private opinfo incinfo;
private opinfo inxinfo;
private opinfo inyinfo;
private opinfo jmpinfo;
private opinfo jsrinfo;
private opinfo ldainfo;
private opinfo ldxinfo;
private opinfo ldyinfo;
private opinfo lsrinfo;
private opinfo nopinfo;
private opinfo orainfo;
private opinfo phainfo;
private opinfo phpinfo;
private opinfo plainfo;
private opinfo plpinfo;
private opinfo rolinfo;
private opinfo rorinfo;
private opinfo rtiinfo;
private opinfo rtsinfo;
private opinfo sbcinfo;
private opinfo secinfo;
private opinfo sedinfo;
private opinfo seiinfo;
private opinfo stainfo;
private opinfo stxinfo;
private opinfo styinfo;
private opinfo taxinfo;
private opinfo tayinfo;
private opinfo tsxinfo;
private opinfo txainfo;
private opinfo txsinfo;
private opinfo tyainfo;

// Exception classes

// The term "mnemonic" refers to the entire opcode string, such as "ldazx"
// The term "instr" refers to the first three characters, such as "lda"
// The term "flag" refers to the remaining characters, from 0-2, such as "zx",
// that serve as "flags" or modifiers to the instruction.
// Finally, "opflag" and "opcode" refer to the ubyte numerical encoding for
// "flag" and "instr", respectively.
class InvalidMnemonicException : Exception {this(string s) {super(s);}}
class InvalidFlagException : InvalidMnemonicException {this(string s) {super(s);}}
class InvalidInstrException : InvalidMnemonicException {this(string s) {super(s);}}

// Return hex code as 2-character string for given mnemonic
// Throws InvalidMnemonicException on bad input
public string hexcode(string mnemonic)
{
  if (mnemonic.length < 3) throw new InvalidMnemonicException("Mnemonic too short " ~ mnemonic);
  if (mnemonic.length > 5) throw new InvalidMnemonicException("Mnemonic too long " ~ mnemonic);
  string mnem = mnemonic.toLower();

  // Build opflag from mnemonic
  opflag flag;
  foreach(c; mnem[3..$])
  {
    if (c in flagmap) flag |= flagmap[c];
    else throw new InvalidFlagException("Invalid Flag " ~ c);
  }

  // Lookup and return hex code
  string instr = mnem[0..3];
  if (instr !in infomap) throw new InvalidInstrException("Invalid mnemonic " ~ instr);
  opinfo info = infomap[instr];
  if (flag !in info.codemap)
  {
    if (mnemonic.length > 3)
        throw new InvalidMnemonicException("Invalid mnemonic - instruction " ~ instr ~ " does not except flags " ~ mnem[3..$]);
    else
        throw new InvalidMnemonicException("Invalid mnemonic - instruction " ~ instr ~ " requires flags");
  }

  string retVal;
  writefln(retVal, "%2X", info.codemap[flag]);
  return retVal;
}

// Return size of encoding for given mnemonic
// For the 6502, only the first flag is needed to figure out the size
public int numbytes(string mnemonic)
{
  if (mnemonic.length < 3) throw new InvalidMnemonicException("Mnemonic too short " ~ mnemonic);
  if (mnemonic.length > 5) throw new InvalidMnemonicException("Mnemonic too long " ~ mnemonic);
  string mnem = mnemonic.toLower();
  if (mnem.length == 3) return 1;
  switch(mnem[3])
  {
    case 'i': return 2;
    case 'z': return 2;
    case 'a': return 3;
    case 'n': return 2;
    default: throw new InvalidFlagException("Invalid Flag " ~ mnem[3]);
  }
}

// This function initializes all of the declared variables, including the entire instruction set, so it is very long...
private void initopinfo()
{
  flagmap =
  [
    'i':IMMEDIATE,
    'z':ZEROPAGE,
    'a':ABSOLUTE,
    'n':INDIRECT,
    'x':XREG,
    'y':YREG
  ];

  infomap =
  [
   "adc":adcinfo,
   "and":andinfo,
   "asl":aslinfo,
   "bit":bitinfo,
   "bpl":bplinfo,
   "bmi":bmiinfo,
   "bvc":bvcinfo,
   "bvs":bvsinfo,
   "bcc":bccinfo,
   "bcs":bcsinfo,
   "bne":bneinfo,
   "beq":beqinfo,
   "brk":brkinfo,
   "cmp":cmpinfo,
   "cpx":cpxinfo,
   "cpy":cpyinfo,
   "dec":decinfo,
   "eor":eorinfo,
   "clc":clcinfo,
   "sec":secinfo,
   "cli":cliinfo,
   "sei":seiinfo,
   "clv":clvinfo,
   "cld":cldinfo,
   "sed":sedinfo,
   "inc":incinfo,
   "jmp":jmpinfo,
   "jsr":jsrinfo,
   "lda":ldainfo,
   "ldx":ldxinfo,
   "ldy":ldyinfo,
   "lsr":lsrinfo,
   "nop":nopinfo,
   "ora":orainfo,
   "tax":taxinfo,
   "txa":txainfo,
   "dex":dexinfo,
   "inx":inxinfo,
   "tay":tayinfo,
   "tya":tyainfo,
   "dey":deyinfo,
   "iny":inyinfo,
   "rol":rolinfo,
   "ror":rorinfo,
   "rti":rtiinfo,
   "rts":rtsinfo,
   "sbc":sbcinfo,
   "sta":stainfo,
   "txs":txsinfo,
   "tsx":tsxinfo,
   "pha":phainfo,
   "pla":plainfo,
   "php":phpinfo,
   "plp":plpinfo,
   "stx":stxinfo,
   "sty":styinfo
  ];

  opinfo adcinfo = opinfo(
  "adc",
  [
    IMMEDIATE:0x69,
    ZEROPAGE:0x65,
    ZEROPAGE | XREG:0x75,
    ABSOLUTE:0x6D,
    ABSOLUTE | XREG:0x7D,
    ABSOLUTE | YREG:0x79,
    INDIRECT | XREG:0x61,
    INDIRECT | YREG:0x71,
  ]);

  opinfo andinfo = opinfo(
  "and",
  [
    IMMEDIATE:0x29,
    ZEROPAGE:0x25,
    ZEROPAGE | XREG:0x35,
    ABSOLUTE:0x2D,
    ABSOLUTE | XREG:0x3D,
    ABSOLUTE | YREG:0x39,
    INDIRECT | XREG:0x21,
    INDIRECT | YREG:0x31,
  ]);

  opinfo aslinfo = opinfo(
  "asl",
  [
    NOFLAGS:0x0A,
    ZEROPAGE:0x06,
    ZEROPAGE | XREG:0x16,
    ABSOLUTE:0x0E,
    ABSOLUTE | XREG:0x1E,
  ]);

  opinfo bitinfo = opinfo(
  "bit",
  [
    ZEROPAGE:0x24,
    ABSOLUTE:0x2C,
  ]);

  opinfo bplinfo = opinfo(
  "bpl",
  [
    NOFLAGS:0x10,
  ]);

  opinfo bmiinfo = opinfo(
  "bmi",
  [
    NOFLAGS:0x30,
  ]);

  opinfo bvcinfo = opinfo(
  "bvc",
  [
    NOFLAGS:0x50,
  ]);

  opinfo bvsinfo = opinfo(
  "bvs",
  [
    NOFLAGS:0x70,
  ]);

  opinfo bccinfo = opinfo(
  "bcc",
  [
    NOFLAGS:0x90,
  ]);

  opinfo bcsinfo = opinfo(
  "bcs",
  [
    NOFLAGS:0xB0,
  ]);

  opinfo bneinfo = opinfo(
  "bne",
  [
    NOFLAGS:0xD0,
  ]);

  opinfo beqinfo = opinfo(
  "beq",
  [
    NOFLAGS:0xF0,
  ]);

  opinfo brkinfo = opinfo(
  "brk",
  [
    NOFLAGS:0x00,
  ]);

  opinfo cmpinfo = opinfo(
  "cmp",
  [
    IMMEDIATE:0xC9,
    ZEROPAGE:0xC5,
    ZEROPAGE | XREG:0xD5,
    ABSOLUTE:0xCD,
    ABSOLUTE | XREG:0xDD,
    ABSOLUTE | YREG:0xD9,
    INDIRECT | XREG:0xC1,
    INDIRECT | YREG:0xD1,
  ]);

  opinfo cpxinfo = opinfo(
  "cpx",
  [
    IMMEDIATE:0xE0,
    ZEROPAGE:0xE4,
    ABSOLUTE:0xEC,
  ]);

  opinfo cpyinfo = opinfo(
  "cpy",
  [
    IMMEDIATE:0xC0,
    ZEROPAGE:0xC4,
    ABSOLUTE:0xCC,
  ]);

  opinfo decinfo = opinfo(
  "dec",
  [
    ZEROPAGE:0xC6,
    ZEROPAGE | XREG:0xD6,
    ABSOLUTE:0xCE,
    ABSOLUTE | XREG:0xDE,
  ]);

  opinfo eorinfo = opinfo(
  "eor",
  [
    IMMEDIATE:0x49,
    ZEROPAGE:0x45,
    ZEROPAGE | XREG:0x55,
    ABSOLUTE:0x4D,
    ABSOLUTE | XREG:0x5D,
    ABSOLUTE | YREG:0x59,
    INDIRECT | XREG:0x41,
    INDIRECT | YREG:0x51,
  ]);

  opinfo clcinfo = opinfo(
  "clc",
  [
    NOFLAGS:0x18,
  ]);

  opinfo secinfo = opinfo(
  "sec",
  [
    NOFLAGS:0x38,
  ]);

  opinfo cliinfo = opinfo(
  "cli",
  [
    NOFLAGS:0x58,
  ]);

  opinfo seiinfo = opinfo(
  "sei",
  [
    NOFLAGS:0x78,
  ]);

  opinfo clvinfo = opinfo(
  "clv",
  [
    NOFLAGS:0xB8,
  ]);

  opinfo cldinfo = opinfo(
  "cld",
  [
    NOFLAGS:0xD8,
  ]);

  opinfo sedinfo = opinfo(
  "sed",
  [
    NOFLAGS:0xF8,
  ]);

  opinfo incinfo = opinfo(
  "inc",
  [
    ZEROPAGE:0xE6,
    ZEROPAGE | XREG:0xF6,
    ABSOLUTE:0xEE,
    ABSOLUTE | XREG:0xFE,
  ]);

  opinfo jmpinfo = opinfo(
  "jmp",
  [
    ABSOLUTE:0x4C,
    INDIRECT:0x6C,
  ]);

  opinfo jsrinfo = opinfo(
  "jsr",
  [
    ABSOLUTE:0x20,
  ]);

  opinfo ldainfo = opinfo(
  "lda",
  [
    IMMEDIATE:0xA9,
    ZEROPAGE:0xA5,
    ZEROPAGE | XREG:0xB5,
    ABSOLUTE:0xAD,
    ABSOLUTE | XREG:0xBD,
    ABSOLUTE | YREG:0xB9,
    INDIRECT | XREG:0xA1,
    INDIRECT | YREG:0xB1,
  ]);

  opinfo ldxinfo = opinfo(
  "ldx",
  [
    IMMEDIATE:0xA2,
    ZEROPAGE:0xA6,
    ZEROPAGE | YREG:0xB6,
    ABSOLUTE:0xAE,
    ABSOLUTE | YREG:0xBE,
  ]);

  opinfo ldyinfo = opinfo(
  "ldy",
  [
    IMMEDIATE:0xA0,
    ZEROPAGE:0xA4,
    ZEROPAGE | XREG:0xB4,
    ABSOLUTE:0xAC,
    ABSOLUTE | XREG:0xBC,
  ]);

  opinfo lsrinfo = opinfo(
  "lsr",
  [
    NOFLAGS:0x4A,
    ZEROPAGE:0x46,
    ZEROPAGE | XREG:0x56,
    ABSOLUTE:0x4E,
    ABSOLUTE | XREG:0x5E,
  ]);

  opinfo nopinfo = opinfo(
  "nop",
  [
    NOFLAGS:0xEA,
  ]);

  opinfo orainfo = opinfo(
  "ora",
  [
    IMMEDIATE:0x09,
    ZEROPAGE:0x05,
    ZEROPAGE | XREG:0x15,
    ABSOLUTE:0x0D,
    ABSOLUTE | XREG:0x1D,
    ABSOLUTE | YREG:0x19,
    INDIRECT | XREG:0x01,
    INDIRECT | YREG:0x11,
  ]);

  opinfo taxinfo = opinfo(
  "tax",
  [
    NOFLAGS:0xAA,
  ]);

  opinfo txainfo = opinfo(
  "txa",
  [
    NOFLAGS:0x8A,
  ]);

  opinfo dexinfo = opinfo(
  "dex",
  [
    NOFLAGS:0xCA,
  ]);

  opinfo inxinfo = opinfo(
  "inx",
  [
    NOFLAGS:0xE8,
  ]);

  opinfo tayinfo = opinfo(
  "tay",
  [
    NOFLAGS:0xA8,
  ]);

  opinfo tyainfo = opinfo(
  "tya",
  [
    NOFLAGS:0x98,
  ]);

  opinfo deyinfo = opinfo(
  "dey",
  [
    NOFLAGS:0x88,
  ]);

  opinfo inyinfo = opinfo(
  "iny",
  [
    NOFLAGS:0xC8,
  ]);

  opinfo rolinfo = opinfo(
  "rol",
  [
    NOFLAGS:0x2A,
    ZEROPAGE:0x26,
    ZEROPAGE | XREG:0x36,
    ABSOLUTE:0x2E,
    ABSOLUTE | XREG:0x3E,
  ]);

  opinfo rorinfo = opinfo(
  "ror",
  [
    NOFLAGS:0x6A,
    ZEROPAGE:0x66,
    ZEROPAGE | XREG:0x76,
    ABSOLUTE:0x6E,
    ABSOLUTE | XREG:0x7E,
  ]);

  opinfo rtiinfo = opinfo(
  "rti",
  [
    NOFLAGS:0x40,
  ]);

  opinfo rtsinfo = opinfo(
  "rts",
  [
    NOFLAGS:0x60,
  ]);

  opinfo sbcinfo = opinfo(
  "sbc",
  [
    IMMEDIATE:0xE9,
    ZEROPAGE:0xE5,
    ZEROPAGE | XREG:0xF5,
    ABSOLUTE:0xED,
    ABSOLUTE | XREG:0xFD,
    ABSOLUTE | YREG:0xF9,
    INDIRECT | XREG:0xE1,
    INDIRECT | YREG:0xF1,
  ]);

  opinfo stainfo = opinfo(
  "sta",
  [
    ZEROPAGE:0x85,
    ZEROPAGE | XREG:0x95,
    ABSOLUTE:0x8D,
    ABSOLUTE | XREG:0x9D,
    ABSOLUTE | YREG:0x99,
    INDIRECT | XREG:0x81,
    INDIRECT | YREG:0x91,
  ]);

  opinfo txsinfo = opinfo(
  "txs",
  [
    NOFLAGS:0x9A,
  ]);

  opinfo tsxinfo = opinfo(
  "tsx",
  [
    NOFLAGS:0xBA,
  ]);

  opinfo phainfo = opinfo(
  "pha",
  [
    NOFLAGS:0x48,
  ]);

  opinfo plainfo = opinfo(
  "pla",
  [
    NOFLAGS:0x68,
  ]);

  opinfo phpinfo = opinfo(
  "php",
  [
    NOFLAGS:0x08,
  ]);

  opinfo plpinfo = opinfo(
  "plp",
  [
    NOFLAGS:0x28,
  ]);

  opinfo stxinfo = opinfo(
  "stx",
  [
    ZEROPAGE:0x86,
    ZEROPAGE | YREG:0x96,
    ABSOLUTE:0x8E,
  ]);

  opinfo styinfo = opinfo(
  "sty",
  [
    ZEROPAGE:0x84,
    ZEROPAGE | XREG:0x94,
    ABSOLUTE:0x8C,
  ]);
}
