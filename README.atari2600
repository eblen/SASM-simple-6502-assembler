SASM supports creating and running Atari 2600 programs using the Stella emulator:

http://stella.sourceforge.net/

Stella expects as input binary files of a certain size that represent the game ROM. The "-s atari2600" command-line argument tells SASM to output code in this format. It also changes how zero-page memory is allocated. See the "zpm.d" source file for details.

In the "example" directory, there is a simple Atari 2600 kernel that displays scrolling color bars. It can serve as a skeleton for your own Atari 2600 project. Here is how to run it using Stella:

1) Install Stella so that you can run it from the command line, say as "stella".
2) Compile the SASM assembler in the "src" directory using the dmd D compiler: "dmd sasm.d p6502.d zpm.d"
3) Assemble the kernel: ./sasm -s atari2600 < ../example/atari2600_sample_kernel.asm > atari2600_sample_kernel.bin
4) Run it with stella: "stella atari2600_sample_kernel.bin"

Congratulations! You now have a simple tool chain for creating and running your very own Atari 2600 game. Consult the many resources on the Internet to learn more.

TIPS
1) The binary file sizes must be exact for Stella. For binary output, SASM will fill in areas between code sections (separated by "org" commands) with "filler bytes" (currently 0xff) but does not add additional bytes otherwise. Thus, use "org" to force exact binary sizes. For example, to force SASM to fill to the end of memory (0xffff), place the following at the end of the program:

org ffff
data ff
