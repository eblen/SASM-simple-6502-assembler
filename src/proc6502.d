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

enum ADDR_TYPE {ABS, IND, NONE, REL, ZP}

// Main struct for storing numerical encodings for instructions and their flags
private struct opinfo
{
  string instr;
  opcode[opflag] codemap;
}

// Main lookup tables
private opflag[char] flagmap;
private opinfo[string] infomap;
private string[opcode] opcodemap;

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
class InvalidOpcodeException : Exception {this(string s) {super(s);}}

// Return ubyte for given mnemonic
// Throws InvalidMnemonicException on bad input
public ubyte bytecode(string mnemonic)
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

  return info.codemap[flag];
}

// Return address type of the given mnemonic
public ADDR_TYPE addrtype(string mnemonic)
{
  if (mnemonic.length < 3) throw new InvalidMnemonicException("Mnemonic too short " ~ mnemonic);
  if (mnemonic.length > 5) throw new InvalidMnemonicException("Mnemonic too long " ~ mnemonic);
  string mnem = mnemonic.toLower();
  if (mnem[0] == 'b' && mnem != "bit" && mnem != "brk") return ADDR_TYPE.REL;
  if (mnem.length < 4) return ADDR_TYPE.NONE;
  switch(mnem[3])
  {
    case 'i': return ADDR_TYPE.NONE;
    case 'z': return ADDR_TYPE.ZP;
    case 'a': return ADDR_TYPE.ABS;
    case 'n': return ADDR_TYPE.IND;
    default: throw new InvalidFlagException("Invalid Flag " ~ mnem[3]);
  }
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
    case 'n':
      if (mnemonic == "jmpn") return 3;
      else return 2;
    default: throw new InvalidFlagException("Invalid Flag " ~ mnem[3]);
  }
}

// Return the mnemonic (such as "stazx") for the given opcode (such as 0x95)
public string mnemonic(opcode oc)
{
  // Todo: opcode should be printed in hex
  if (oc !in opcodemap) throw new InvalidOpcodeException("Invalid opcode " ~ to!string(oc));
  return opcodemap[oc];
}

// Initialize 6502 data. This function must be called before calling other functions in this module.
public void init6502()
{
  initopinfo();
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

  opcodemap = 
  [
    0x69:"adci",
    0x65:"adcz",
    0x75:"adczx",
    0x6D:"adca",
    0x7D:"adcax",
    0x79:"adcay",
    0x61:"adcnx",
    0x71:"adcny",
    0x29:"andi",
    0x25:"andz",
    0x35:"andzx",
    0x2D:"anda",
    0x3D:"andax",
    0x39:"anday",
    0x21:"andnx",
    0x31:"andny",
    0x0A:"asl",
    0x06:"aslz",
    0x16:"aslzx",
    0x0E:"asla",
    0x1E:"aslax",
    0x24:"bitz",
    0x2C:"bita",
    0x10:"bpl",
    0x30:"bmi",
    0x50:"bvc",
    0x70:"bvs",
    0x90:"bcc",
    0xB0:"bcs",
    0xD0:"bne",
    0xF0:"beq",
    0xC9:"cmpi",
    0xC5:"cmpz",
    0xD5:"cmpzx",
    0xCD:"cmpa",
    0xDD:"cmpax",
    0xD9:"cmpay",
    0xC1:"cmpnx",
    0xD1:"cmpny",
    0xE0:"cpxi",
    0xE4:"cpxz",
    0xEC:"cpxa",
    0xC0:"cpyi",
    0xC4:"cpyz",
    0xCC:"cpya",
    0xC6:"decz",
    0xD6:"deczx",
    0xCE:"deca",
    0xDE:"decax",
    0x49:"eori",
    0x45:"eorz",
    0x55:"eorzx",
    0x4D:"eora",
    0x5D:"eorax",
    0x59:"eoray",
    0x41:"eornx",
    0x51:"eorny",
    0x18:"clc",
    0x38:"sec",
    0x58:"cli",
    0x78:"sei",
    0xB8:"clv",
    0xD8:"cld",
    0xF8:"sed",
    0xE6:"incz",
    0xF6:"inczx",
    0xEE:"inca",
    0xFE:"incax",
    0x4C:"jmpa",
    0x6C:"jmpn",
    0x20:"jsra",
    0xA9:"ldai",
    0xA5:"ldaz",
    0xB5:"ldazx",
    0xAD:"ldaa",
    0xBD:"ldaax",
    0xB9:"ldaay",
    0xA1:"ldanx",
    0xB1:"ldany",
    0xA2:"ldxi",
    0xA6:"ldxz",
    0xB6:"ldxzy",
    0xAE:"ldxa",
    0xBE:"ldxay",
    0xA0:"ldyi",
    0xA4:"ldyz",
    0xB4:"ldyzx",
    0xAC:"ldya",
    0xBC:"ldyax",
    0x4A:"lsr",
    0x46:"lsrz",
    0x56:"lsrzx",
    0x4E:"lsra",
    0x5E:"lsrax",
    0x09:"orai",
    0x05:"oraz",
    0x15:"orazx",
    0x0D:"oraa",
    0x1D:"oraax",
    0x19:"oraay",
    0x01:"oranx",
    0x11:"orany",
    0xAA:"tax",
    0x8A:"txa",
    0xCA:"dex",
    0xE8:"inx",
    0xA8:"tay",
    0x98:"tya",
    0x88:"dey",
    0xC8:"iny",
    0x2A:"rol",
    0x26:"rolz",
    0x36:"rolzx",
    0x2E:"rola",
    0x3E:"rolax",
    0x6A:"ror",
    0x66:"rorz",
    0x76:"rorzx",
    0x6E:"rora",
    0x7E:"rorax",
    0xE9:"sbci",
    0xE5:"sbcz",
    0xF5:"sbczx",
    0xED:"sbca",
    0xFD:"sbcax",
    0xF9:"sbcay",
    0xE1:"sbcnx",
    0xF1:"sbcny",
    0x85:"staz",
    0x95:"stazx",
    0x8D:"staa",
    0x9D:"staax",
    0x99:"staay",
    0x81:"stanx",
    0x91:"stany",
    0x9A:"txs",
    0xBA:"tsx",
    0x48:"pha",
    0x68:"pla",
    0x08:"php",
    0x28:"plp",
    0x86:"stxz",
    0x96:"stxzy",
    0x8E:"stxa",
    0x84:"styz",
    0x94:"styzx",
    0x8C:"stya",
    0x40:"rti",
    0x60:"rts"
  ];

  adcinfo = opinfo(
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

  andinfo = opinfo(
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

  aslinfo = opinfo(
  "asl",
  [
    NOFLAGS:0x0A,
    ZEROPAGE:0x06,
    ZEROPAGE | XREG:0x16,
    ABSOLUTE:0x0E,
    ABSOLUTE | XREG:0x1E,
  ]);

  bitinfo = opinfo(
  "bit",
  [
    ZEROPAGE:0x24,
    ABSOLUTE:0x2C,
  ]);

  bplinfo = opinfo(
  "bpl",
  [
    NOFLAGS:0x10,
  ]);

  bmiinfo = opinfo(
  "bmi",
  [
    NOFLAGS:0x30,
  ]);

  bvcinfo = opinfo(
  "bvc",
  [
    NOFLAGS:0x50,
  ]);

  bvsinfo = opinfo(
  "bvs",
  [
    NOFLAGS:0x70,
  ]);

  bccinfo = opinfo(
  "bcc",
  [
    NOFLAGS:0x90,
  ]);

  bcsinfo = opinfo(
  "bcs",
  [
    NOFLAGS:0xB0,
  ]);

  bneinfo = opinfo(
  "bne",
  [
    NOFLAGS:0xD0,
  ]);

  beqinfo = opinfo(
  "beq",
  [
    NOFLAGS:0xF0,
  ]);

  brkinfo = opinfo(
  "brk",
  [
    NOFLAGS:0x00,
  ]);

  cmpinfo = opinfo(
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

  cpxinfo = opinfo(
  "cpx",
  [
    IMMEDIATE:0xE0,
    ZEROPAGE:0xE4,
    ABSOLUTE:0xEC,
  ]);

  cpyinfo = opinfo(
  "cpy",
  [
    IMMEDIATE:0xC0,
    ZEROPAGE:0xC4,
    ABSOLUTE:0xCC,
  ]);

  decinfo = opinfo(
  "dec",
  [
    ZEROPAGE:0xC6,
    ZEROPAGE | XREG:0xD6,
    ABSOLUTE:0xCE,
    ABSOLUTE | XREG:0xDE,
  ]);

  eorinfo = opinfo(
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

  clcinfo = opinfo(
  "clc",
  [
    NOFLAGS:0x18,
  ]);

  secinfo = opinfo(
  "sec",
  [
    NOFLAGS:0x38,
  ]);

  cliinfo = opinfo(
  "cli",
  [
    NOFLAGS:0x58,
  ]);

  seiinfo = opinfo(
  "sei",
  [
    NOFLAGS:0x78,
  ]);

  clvinfo = opinfo(
  "clv",
  [
    NOFLAGS:0xB8,
  ]);

  cldinfo = opinfo(
  "cld",
  [
    NOFLAGS:0xD8,
  ]);

  sedinfo = opinfo(
  "sed",
  [
    NOFLAGS:0xF8,
  ]);

  incinfo = opinfo(
  "inc",
  [
    ZEROPAGE:0xE6,
    ZEROPAGE | XREG:0xF6,
    ABSOLUTE:0xEE,
    ABSOLUTE | XREG:0xFE,
  ]);

  jmpinfo = opinfo(
  "jmp",
  [
    ABSOLUTE:0x4C,
    INDIRECT:0x6C,
  ]);

  jsrinfo = opinfo(
  "jsr",
  [
    ABSOLUTE:0x20,
  ]);

  ldainfo = opinfo(
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

  ldxinfo = opinfo(
  "ldx",
  [
    IMMEDIATE:0xA2,
    ZEROPAGE:0xA6,
    ZEROPAGE | YREG:0xB6,
    ABSOLUTE:0xAE,
    ABSOLUTE | YREG:0xBE,
  ]);

  ldyinfo = opinfo(
  "ldy",
  [
    IMMEDIATE:0xA0,
    ZEROPAGE:0xA4,
    ZEROPAGE | XREG:0xB4,
    ABSOLUTE:0xAC,
    ABSOLUTE | XREG:0xBC,
  ]);

  lsrinfo = opinfo(
  "lsr",
  [
    NOFLAGS:0x4A,
    ZEROPAGE:0x46,
    ZEROPAGE | XREG:0x56,
    ABSOLUTE:0x4E,
    ABSOLUTE | XREG:0x5E,
  ]);

  nopinfo = opinfo(
  "nop",
  [
    NOFLAGS:0xEA,
  ]);

  orainfo = opinfo(
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

  taxinfo = opinfo(
  "tax",
  [
    NOFLAGS:0xAA,
  ]);

  txainfo = opinfo(
  "txa",
  [
    NOFLAGS:0x8A,
  ]);

  dexinfo = opinfo(
  "dex",
  [
    NOFLAGS:0xCA,
  ]);

  inxinfo = opinfo(
  "inx",
  [
    NOFLAGS:0xE8,
  ]);

  tayinfo = opinfo(
  "tay",
  [
    NOFLAGS:0xA8,
  ]);

  tyainfo = opinfo(
  "tya",
  [
    NOFLAGS:0x98,
  ]);

  deyinfo = opinfo(
  "dey",
  [
    NOFLAGS:0x88,
  ]);

  inyinfo = opinfo(
  "iny",
  [
    NOFLAGS:0xC8,
  ]);

  rolinfo = opinfo(
  "rol",
  [
    NOFLAGS:0x2A,
    ZEROPAGE:0x26,
    ZEROPAGE | XREG:0x36,
    ABSOLUTE:0x2E,
    ABSOLUTE | XREG:0x3E,
  ]);

  rorinfo = opinfo(
  "ror",
  [
    NOFLAGS:0x6A,
    ZEROPAGE:0x66,
    ZEROPAGE | XREG:0x76,
    ABSOLUTE:0x6E,
    ABSOLUTE | XREG:0x7E,
  ]);

  rtiinfo = opinfo(
  "rti",
  [
    NOFLAGS:0x40,
  ]);

  rtsinfo = opinfo(
  "rts",
  [
    NOFLAGS:0x60,
  ]);

  sbcinfo = opinfo(
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

  stainfo = opinfo(
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

  txsinfo = opinfo(
  "txs",
  [
    NOFLAGS:0x9A,
  ]);

  tsxinfo = opinfo(
  "tsx",
  [
    NOFLAGS:0xBA,
  ]);

  phainfo = opinfo(
  "pha",
  [
    NOFLAGS:0x48,
  ]);

  plainfo = opinfo(
  "pla",
  [
    NOFLAGS:0x68,
  ]);

  phpinfo = opinfo(
  "php",
  [
    NOFLAGS:0x08,
  ]);

  plpinfo = opinfo(
  "plp",
  [
    NOFLAGS:0x28,
  ]);

  stxinfo = opinfo(
  "stx",
  [
    ZEROPAGE:0x86,
    ZEROPAGE | YREG:0x96,
    ABSOLUTE:0x8E,
  ]);

  styinfo = opinfo(
  "sty",
  [
    ZEROPAGE:0x84,
    ZEROPAGE | XREG:0x94,
    ABSOLUTE:0x8C,
  ]);

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
}
