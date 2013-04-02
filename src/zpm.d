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

// Zero Page Manager Classes
// Responsible for allocating zero page bytes

import proc6502;

class ZeroPageAllocationException : Exception {this(string s) {super(s);}}

interface ZeroPageManager
{
  final ubyte alloc() {return alloc(1);}
  ubyte alloc(ubyte size);
}

// Apple II system-level programs, like the monitor and DOS, use the lower addresses first and leave the higher addresses for user
// programs. Thus, this simple manager usually works fine. It allocates bytes in order from high to low memory.
// A program that uses lots of zero-page bytes will need a more sophisticated manager. It also will have to consider the
// specific Apple II model being used.
class SimpleAppleIIZeroPageManager : ZeroPageManager
{
  this()
  {
    next_free_byte = 255;
  }

  override ubyte alloc(ubyte size)
  {
    assert(size > 0);
    if (size > next_free_byte)
    {
      throw new ZeroPageAllocationException("Zero page memory exhausted.");
    }
    next_free_byte -= size;
    return cast(ubyte)(next_free_byte + 1);
  }

  private:
  ubyte next_free_byte;
}

// The upper half of zero page (0x80 - 0xff) is the ONLY memory, zero-page or otherwise, that Atari 2600 programmers have available.
// Furthermore, the stack is mapped to zero page as well! The stack normally starts at ff and grows down, which means that the
// lower addresses should be preferred. Accordingly, this manager allocates memory in order from 0x80 to 0xff
class Atari2600ZeroPageManager : ZeroPageManager
{
  this()
  {
    next_free_byte = 0x80;
  }

  override ubyte alloc(ubyte size)
  {
    assert(size > 0);
    if (next_free_byte + size > 0x100)
    {
      throw new ZeroPageAllocationException("Zero page memory exhausted.");
    }
    ubyte ret_byte = cast(ubyte)(next_free_byte);
    next_free_byte += size;
    return ret_byte;
  }

  private:
  int next_free_byte;
}
