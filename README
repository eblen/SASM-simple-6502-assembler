SASM Simple Assembler for 6502 Programs

This assembler supports a simple syntax and basic functionality for creating 6502 programs. It is designed as a "lower-level" assembler that strives to stay as close to machine language (ML) as possible, removing only those aspects of ML that make it impractical to use. This includes:

1) Entering opcodes: It is impractical to memorize or lookup hex codes for all of the opcodes and their different flavors. SASM uses mnemonics that map one-to-one with 6502 opcodes. So the programmer knows exactly what ML instruction is being used but without memorizing hex values. SASM uses the common three-letter abbreviations of other assemblers and appends modifiers. Thus, the programmer can take advantage of current knowledge and use 0-2 modifier flags to indicate a specific flavor of an instruction. For example, "stazx" indicates the familiar store instruction, "sta", on a zero page address and using the X register as an offset.

Additionally, using these mnemonics allows the remaining arguments to be pure numerical values, leading to a streamlined, fixed format that avoids the extra line noise of other assemblers.

2) Computing addresses: It is also impractical to expect the programmer to compute and constantly adjust addresses while writing and editing ML programs. Thus, SASM supports labels like other assemblers. To support labels, SASM uses a period to distinguish them from mnemonics or numerical data.

3) Zero page addresses. This is perhaps unique to the 6502. It is essential that the programmer be able to specify and use zero page addresses for heavily used memory. It is architecture-specific, though, which zero page addresses are available and how they should be allocated for use. Thus, SASM offers a special syntax to allocate zero-page bytes and leaves it up to the assembler to properly allocate them.

See the following READMEs for more information:
README.appleII: Instructions for running SASM programs on OpenEmulator
README.atari2600: Instructions for running SASM programs on Stella
README.moo: Instructions for playing the example game program
README.sasm: Instructions for using the SASM assembly language
