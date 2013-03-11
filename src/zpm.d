// Zero Page Manager Classes
// Responsible for allocating zero page bytes

import proc6502;

interface ZeroPageManager
{
  final ubyte alloc() {return alloc(1);}
  ubyte alloc(ubyte size);
}

// TODO: Add error checking for bad size value and for memory exhaustion.

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
    next_free_byte -= size;
    return cast(ubyte)(next_free_byte + 1);
  }

  private:
  ubyte next_free_byte;
}
