;********************************************************************
; SASM (Simple Assembler) for 6502 and related processors
; Copyright (C) 2013 John Eblen

; This file is part of SASM.

; SASM is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; SASM is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with SASM.  If not, see <http://www.gnu.org/licenses/>.
;*********************************************************************/

; Moo Program for Apple II
; Play a game of moo using lo-res graphics

org a00

zbyte shapemap0
zbyte shapemap1
zbyte row_limit
zbyte column_limit
zbyte color 8
zbyte digit 4
zbyte digit_index ; Indicated by bits 0 and 1 - ignore 2-7
zbyte key
zbyte random
; Allocate TMPs in reverse order so they will be consecutive
; This is bad, bad, bad, because we are using hidden knowledge
; about how the zero-page allocator works. It is desirable,
; though, to have a set of tmps that are both consecutive and
; that we can use directly without indexing.
zbyte tmp4
zbyte tmp3
zbyte tmp2
zbyte tmp1
zbyte tmp0

; Initialization
jsra  58fc
jsra  40fb

; Set colors to 6
ldxi  07
ldai  66
.init_color_value
stazx .color
dex
bpl   .init_color_value

; Random number seed
ldaz  4f
staz  .random

; Generate the number to guess
ldxi  03
.gen_digit
jsra  .random_digit
stazx .digit
dex
bpl   .gen_digit

; Set initial positions and extents for digits
ldai  11
staz  .row_limit
ldai  26
staz  .column_limit
ldxi  02
ldyi  01
ldai  00
staz  .digit_index

; Main Loop
.enter_digit
; Read keyboard input
jsra  .save_regs
jsra  35fd
staz  .tmp0
jsra  .restore_regs
ldaz  .tmp0

; Compute entered number (0-9)
sec
sbci  b0

; Compute key value - need to borrow A and X
; A contains entered digit - needed later.
; Two bits per key value as follows:
; cow: 11 bull: 10 sheep: 00
jsra  .save_regs
staz  .tmp0

; If we have a cow, rotate 1 into KEY
; Otherwise, rotate 0 into KEY
ldaz  .digit_index
andi  03
tax
ldazx .digit
cmpz  .tmp0
clc
bne   .no_cow
sec
.no_cow
rorz  .key

; Now look at other digits:
; if digit is found rotate a 1 into KEY
; otherwise rotate a 0 into KEY
ldxi  03
.digit_loop
ldazx .digit
cmpz  .tmp0
beq   .not_sheep
dex
bpl   .digit_loop
clc
bne   .is_sheep
.not_sheep
sec
.is_sheep
rorz  .key
incz  .digit_index
jsra  .restore_regs

; Compute correct map offset (2 * (entered number))
asl

; Store digit maps - need to borrow x
stxz  .tmp0
tax
ldaax .digit_maps
staz  .shapemap0
inx  
ldaax .digit_maps
staz  .shapemap1
ldxz  .tmp0

; Now actually draw shape
txa  
jsra  .draw_shape

; increment y to next digit position
iny  
iny  
iny  
iny  

; Restart if we are still in the middle of a row
cpyz  .row_limit
bne   .enter_digit

; Draw key information
; First set colors correctly - need to borrow x and y
jsra  .save_regs

; Need to tally number of cows (TMP2), bulls (TMP1), and sheep (TMP0)
; (TMP0 not actually read but is written.)
ldai  00
staz  .tmp1
staz  .tmp2
ldyi  03
.tally_loop
ldai  00
rorz  .key
adci  00
rorz  .key
adci  00
tax  
inczx .tmp0
dey  
bpl   .tally_loop

; Now change pixel colors
ldai  0c
staz  .tmp3
ldxi  03
.next_key_pixel
decz  .tmp2
bmi   .not_cow
ldyi  02
bne   .change_pixel
.not_cow
decz  .tmp1
bmi   .not_bull
ldyi  01
bne   .change_pixel
.not_bull
ldyi  00
.change_pixel
ldaay .key_colors
staz  30
ldaz  .tmp3
jsra  .change_pixel_color
sec  
sbci  03
staz  .tmp3
dex  
bpl   .next_key_pixel
jsra  .restore_regs

; Next store key map
ldai  12
staz  .shapemap0
ldai  48
staz  .shapemap1

; Now actually draw key
txa  
jsra  .draw_shape

; Finally restore original colors
ldai  66
staz  30
ldai  0c
jsra  .change_pixel_color
ldai  09
jsra  .change_pixel_color
ldai  06
jsra  .change_pixel_color
ldai  03
jsra  .change_pixel_color
; End drawing of key information

; Increment x to next column
inx  
inx  
inx  
inx  
inx  
inx  

; Goto next column if we are at the bottom of the screen
cpxz  .column_limit
beq   .finish_column

; Otherwise, reset y and restart
tya  
sec  
sbci  10
tay  
jmpa  .enter_digit

.finish_column
; Return if this is the second column
cpyi  26
bne   .next_column
rts  

; Reset x and y for second column
.next_column
txa  
sec  
sbci  24
tax  
tya  
clc  
adci  05
tay  
; Also adjust horizontal extent
ldai  26
staz  .row_limit

; Always restart
jmpa  .enter_digit

; Subroutine to draw a 3x5 shape in lo-res graphics
; Input: A,Y - column and row of top-left corner of graphic
; Input: SHAPEMAP0, SHAPEMAP1 - shape description (zero page addresses)
; Input: COLOR[0-7] - color of each pixel (2 colors per byte)
; Note: By poking the correct addresses for the two adc instructions,
; and a few other minor adjustments, this routine could be made to work
; for any sized graphic.
.draw_shape

jsra  .save_regs

; Store column in x
tax  

; Store row + 5 in TMP0
clc  
adci  05
staz  .tmp0

; Store column + 3 in TMP1
tya  
adci  03
staz  .tmp1

; Store color index in TMP2
ldai  00
staz  .tmp2

; Main Loop
.draw_row
; Plot if bit 15 in map is set
aslz  .shapemap0
bcc   .no_plot

; Set color value - need to borrow x
stxz  .tmp3

; Load correct color byte
ldaz  .tmp2
lsr  
tax  
ldazx .color

; Create correct color value in A - borrow TMP4
staz  .tmp4
bcs   .take_left

; Color value is in right nibble - duplicate on left
aslz  .tmp4
aslz  .tmp4
aslz  .tmp4
aslz  .tmp4
andi  0f
oraz  .tmp4

; Color value is in left nibble - duplicate on right
.take_left
lsrz  .tmp4
lsrz  .tmp4
lsrz  .tmp4
lsrz  .tmp4
andi  f0
oraz  .tmp4

; Store color value and restore x
staz  30
ldxz  .tmp3

txa  
jsra  .save_regs2
jsra  00f8
jsra  .restore_regs2
.no_plot
incz  .tmp2

; Finish double byte shift
aslz  .shapemap1
bcc   .no_carry
incz  .shapemap0
.no_carry

; Resume if we are in the middle of a row
iny  
cpyz  .tmp1
bne   .draw_row

; Check if we have finished. If so, go ahead and return
inx  
cpxz  .tmp0
bne   .not_done

jsra  .restore_regs
rts  

; Reset y for the next row
.not_done
dey  
dey  
dey  
jmpa  .draw_row

.change_pixel_color
; Input: A - pixel index
; Input: $0030 - color value
; Changes global COLOR array
jsra  .save_regs2 ; 2 because caller also saves regs - yes, this is poor design!
lsr  
tax  
ldazx .color
bcs   .keep_right_color
andi  f0
stazx .color
ldaz  30
andi  0f
orazx .color
stazx .color
jmpa  .end_change_pixel_color
.keep_right_color
andi  0f
stazx .color
ldaz  30
andi  f0
orazx .color
stazx .color
.end_change_pixel_color
jsra  .restore_regs2
rts  

; Linear Congruential Random Number Generator
; Formula is x = (3x+13) mod 256
; Output - A holds random digit from 0-9
;          &'RANDOM is random byte used by RNG
; Only A is altered
.random_digit
; RNG Algorithm
ldaz  .random
clc  
adcz  .random
clc  
adcz  .random
clc  
adci  0d
staz  .random

; Use random number to get a digit 0-9
cmpi  fa
bcs   .random_digit
.sub_10
cmpi  0a
bcc   .random_digit_end
sec  
sbci  0a
bne   .sub_10
.random_digit_end
rts  

; Digit shape maps
.digit_maps
data  f6df
data  2492
data  e7cf
data  e79f
data  b792
data  f39f
data  93df
data  e492
data  f7df
data  f79f

.key_colors
data  55 ; number not in solution (sheep)
data  bb ; number correct but in wrong plage (bull)
data  11 ; number correct and in right place (cow)

zbyte areg
zbyte xreg
zbyte yreg

.save_regs
staz  .areg
stxz  .xreg
styz  .yreg
rts

.restore_regs
ldaz  .areg
ldxz  .xreg
ldyz  .yreg
rts

zbyte areg2
zbyte xreg2
zbyte yreg2

.save_regs2
staz  .areg2
stxz  .xreg2
styz  .yreg2
rts

.restore_regs2
ldaz  .areg2
ldxz  .xreg2
ldyz  .yreg2
rts
