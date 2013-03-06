; Moo Program for Apple II
; Play a game of moo using lo-res graphics - entirely in machine language!

zbyte shapemap0
zbyte shapemap1
zbyte row_limit
zbyte column_limit
zbyte color,8
zbyte digit,4
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
jsra  58fc ; jsr FC58 
jsra  40fb ; jsr FB40 

; Set colors to 6
ldxi  07 ; ldx #7
ldai  66 ; lda #66
.init_color_value
stazx .color ; sta &'COLOR,x
dex   ; dex
bpl   .init_color_value ; bpl #INIT_COLOR_VALUE

; Random number seed
ldaz  4f ; lda 4f
staz  .random ; sta &'RANDOM

; Generate the number to guess
ldxi  03 ; ldx #3
.gen_digit
jsra  .random_digit ; jsr &RANDOM_DIGIT
stazx .digit ; sta &'DIGIT,x
dex   ; dex
bpl   .gen_digit ; bpl #GEN_DIGIT

; Set initial positions and extents for digits
ldai  11 ; lda #17
staz  .row_limit ; sta &'ROW_LIMIT
ldai  26 ; lda #38
staz  .column_limit ; sta &'COLUMN_LIMIT
ldxi  02 ; ldx #2
ldyi  01 ; ldy #1
ldai  00 ; lda 0
staz  .digit_index ; sta &'DIGIT_INDEX

; Main Loop
.enter_digit
; Read keyboard input
jsra  .save_regs
jsra  35 fd ; jsr FD35 
staz  .tmp0 ; sta &'TMP0
jsra  .restore_regs
ldaz  .tmp0 ; lda &'TMP0

; Compute entered number (0-9)
sec   ; sec
sbci  b0 ; sbc $B0

; Compute key value - need to borrow A and X
; A contains entered digit - needed later.
; Two bits per key value as follows:
; cow: 11 bull: 10 sheep: 00
jsra  .save_regs
staz  .tmp0 ; sta &'TMP0 

; If we have a cow, rotate 1 into KEY
; Otherwise, rotate 0 into KEY
ldaz  .digit_index ; lda &'DIGIT_INDEX
andi  03 ; and %00000011
tax   ; tax
ldazx .digit ; lda &'DIGIT,x
cmpz  .tmp0 ; cmp &'TMP0
clc   ; clc
bne   .no_cow ; bne #NO_COW
sec   ; sec
.no_cow
rorz  .key ; ror &'KEY

; Now look at other digits:
; if digit is found rotate a 1 into KEY
; otherwise rotate a 0 into KEY
ldxi  03 ; ldx #3
.digit_loop
ldazx .digit ; lda &'DIGIT,x
cmpz  .tmp0 ; cmp &'TMP0
beq   .not_sheep ; beq #NOT_SHEEP
dex   ; dex
bpl   .digit_loop ; bpl #DIGIT_LOOP
clc   ; clc
bne   .is_sheep ; bne #IS_SHEEP
.not_sheep
sec   ; sec
.is_sheep
rorz  .key ; ror &'KEY
incz  .digit_index ; inc &'DIGIT_INDEX
jsra  .restore_regs

; Compute correct map offset (2 * (entered number))
asl   ; asl

; Store digit maps - need to borrow x
stxz  .tmp0 ; stx &'TMP0
tax   ; tax
ldaax .digit_maps ; lda &DIGIT_MAPS,x
staz  .shapemap0 ; sta &'SHAPEMAP0
inx   ; inx
ldaax .digit_maps ; lda &DIGIT_MAPS,x
staz  .shapemap1 ; sta &'SHAPEMAP1
ldxz  .tmp0 ; ldx &'TMP0

; Now actually draw shape
txa   ; txa
jsra  .draw_shape ; jsr &DRAW_SHAPE

; increment y to next digit position
iny   ; iny
iny   ; iny
iny   ; iny
iny   ; iny

; Restart if we are still in the middle of a row
cpyz  .row_limit ; cpy &'ROW_LIMIT
bne   .enter_digit ; bne #ENTER_DIGIT

; Draw key information
; First set colors correctly - need to borrow x and y
jsra  .save_regs

; Need to tally number of cows (TMP2), bulls (TMP1), and sheep (TMP0)
; (TMP0 not actually read but is written.)
ldai  00 ; lda #0
staz  .tmp1 ; sta &'TMP1
staz  .tmp2 ; sta &'TMP2
ldyi  03 ; ldy #3
.tally_loop
ldai  00 ; lda #0
rorz  .key ; ror &'KEY
adci  00 ; adc #0
rorz  .key ; ror &'KEY
adci  00 ; adc #0
tax   ; tax
inczx .tmp0 ; inc &'TMP0,x
dey   ; dey
bpl   .tally_loop ; bpl #TALLY_LOOP

; Now change pixel colors
ldai  0c ; lda 0C
staz  .tmp3 ; sta &'TMP3 
ldxi  03 ; ldx #3
.next_key_pixel
decz  .tmp2 ; dec &'TMP2
bmi   .not_cow ; bmi #NOT_COW
ldyi  02 ; ldy #2
bne   .change_pixel ; bne #CHANGE_PIXEL
.not_cow
decz  .tmp1 ; dec &'TMP1
bmi   .not_bull ; bmi #NOT_BULL
ldyi  01 ; ldy #1
bne   .change_pixel ; bne #CHANGE_PIXEL
.not_bull
ldyi  00 ; ldy #0
.change_pixel
ldaay .key_colors ; lda &KEY_COLORS,y
staz  30 ; sta 30
ldaz  .tmp3 ; lda &'TMP3
jsra  .change_pixel_color ; jsr &CHANGE_PIXEL_COLOR
sec   ; sec
sbci  03 ; sbc #3
staz  .tmp3 ; sta &'TMP3
dex   ; dex
bpl   .next_key_pixel ; bpl #NEXT_KEY_PIXEL
jsra  .restore_regs

; Next store key map
ldai  12 ; lda 12
staz  .shapemap0 ; sta &'SHAPEMAP0
ldai  48 ; lda 48
staz  .shapemap1 ; sta &'SHAPEMAP1

; Now actually draw key
txa   ; txa
jsra  .draw_shape ; jsr &DRAW_SHAPE

; Finally restore original colors
ldai  66 ; lda 66
staz  30 ; sta 30
ldai  0c ; lda 0C
jsra  .change_pixel_color ; jsr &CHANGE_PIXEL_COLOR
ldai  09 ; lda 09
jsra  .change_pixel_color ; jsr &CHANGE_PIXEL_COLOR
ldai  06 ; lda 06
jsra  .change_pixel_color ; jsr &CHANGE_PIXEL_COLOR
ldai  03 ; lda 03
jsra  .change_pixel_color ; jsr &CHANGE_PIXEL_COLOR
; End drawing of key information

; Increment x to next column
inx   ; inx
inx   ; inx
inx   ; inx
inx   ; inx
inx   ; inx
inx   ; inx

; Goto next column if we are at the bottom of the screen
cpxz  .column_limit ; cpx &'COLUMN_LIMIT
beq   .finish_column ; beq #FINISH_COLUMN

; Otherwise, reset y and restart
tya   ; tya
sec   ; sec
sbci  10 ; sbc #16
tay   ; tay
jmpa  .enter_digit ; jmp @ENTER_DIGIT

.finish_column
; Return if this is the second column
cpyi  26 ; cpy #38
bne   .next_column ; bne #NEXT_COLUMN
rts   ; rts

; Reset x and y for second column
.next_column
txa   ; txa
sec   ; sec
sbci  24 ; sbc #36
tax   ; tax
tya   ; tya
clc   ; clc
adci  05 ; adc #5
tay   ; tay
; Also adjust horizontal extent
ldai  26 ; lda #38
staz  .row_limit ; sta &'ROW_LIMIT

; Always restart
jmpa  .enter_digit ; jmp @ENTER_DIGIT

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
tax   ; tax

; Store row + 5 in TMP0
clc   ; clc
adci  05 ; adc #5
staz  .tmp0 ; sta @TMP0

; Store column + 3 in TMP1
tya   ; tya
adci  03 ; adc #3
staz  .tmp1 ; sta @TMP1

; Store color index in TMP2
ldai  00 ; lda #0
staz  .tmp2 ; sta &'TMP2

; Main Loop
.draw_row
; Plot if bit 15 in map is set
aslz  .shapemap0 ; asl @SHAPEMAP0
bcc   .no_plot ; bcc @NO_PLOT

; Set color value - need to borrow x
stxz  .tmp3 ; stx &'TMP3

; Load correct color byte
ldaz  .tmp2 ; lda &'TMP2
lsr   ; lsr
tax   ; tax
ldazx .color ; lda &'COLOR,x

; Create correct color value in A - borrow TMP4
staz  .tmp4 ; sta &'TMP4
bcs   .take_left ; bcs #TAKE_LEFT

; Color value is in right nibble - duplicate on left
aslz  .tmp4 ; asl &'TMP4
aslz  .tmp4 ; asl &'TMP4
aslz  .tmp4 ; asl &'TMP4
aslz  .tmp4 ; asl &'TMP4
andi  0f ; and 0F
oraz  .tmp4 ; ora &'TMP4

; Color value is in left nibble - duplicate on right
.take_left
lsrz  .tmp4 ; lsr &'TMP4
lsrz  .tmp4 ; lsr &'TMP4
lsrz  .tmp4 ; lsr &'TMP4
lsrz  .tmp4 ; lsr &'TMP4
andi  f0 ; and F0
oraz  .tmp4 ; ora &'TMP4

; Store color value and restore x
staz  30 ; sta 30
ldxz  .tmp3 ; ldx &'TMP3 

txa   ; txa
jsra  .save_regs2
jsra  00f8 ; jsr plot routine
jsra  .restore_regs2
.no_plot
incz  .tmp2 ; inc &'TMP2

; Finish double byte shift
aslz  .shapemap1 ; asl @SHAPEMAP1
bcc   .no_carry ; bcc @NO_CARRY
incz  .shapemap0 ; inc @SHAPEMAP0
.no_carry

; Resume if we are in the middle of a row
iny   ; iny
cpyz  .tmp1 ; cpy @TMP1
bne   .draw_row ; bne @DRAW_ROW

; Check if we have finished. If so, go ahead and return
inx   ; inx
cpxz  .tmp0 ; cpx @TMP0
bne   .not_done ; bne @NOT_DONE

jsra  .restore_regs
rts   ; rts

; Reset y for the next row
.not_done
dey   ; dey
dey   ; dey
dey   ; dey
jmpa  .draw_row ; jmp @DRAW_ROW

.change_pixel_color
; Input: A - pixel index
; Input: $0030 - color value
; Changes global COLOR array
jsra  .save_regs2 ; 2 because caller also saves regs - yes, this is poor design!
lsr   ; lsr
tax   ; tax
ldazx .color ; lda &'COLOR,x
bcs   .keep_right_color ; bcs #KEEP_RIGHT_COLOR
andi  f0 ; and F0
stazx .color ; sta &'COLOR,x
ldaz  30 ; lda 30
andi  0f ; and 0F
orazx .color ; ora &'COLOR,x
stazx .color ; sta &'COLOR,x
jmpa  .end_change_pixel_color ; jmp &END_CHANGE_PIXEL_COLOR
.keep_right_color
andi  0f ; and 0F
stazx .color ; sta &'COLOR,x
ldaz  30 ; lda 30
andi  f0 ; and F0
orazx .color ; ora &'COLOR,x
stazx .color ; sta &'COLOR,x
.end_change_pixel_color
jsra  .restore_regs2
rts   ; rts

; Linear Congruential Random Number Generator
; Formula is x = (3x+13) mod 256
; Output - A holds random digit from 0-9
;          &'RANDOM is random byte used by RNG
; Only A is altered
.random_digit
; RNG Algorithm
ldaz  .random ; lda &'RANDOM
clc   ; clc
adcz  .random ; adc &'RANDOM
clc   ; clc
adcz  .random ; adc &'RANDOM
clc   ; clc
adci  0d ; adc #13
staz  .random ; sta &'RANDOM

; Use random number to get a digit 0-9
cmpi  fa ; cmp 250 
bcs   .random_digit ; bcs #RANDOM_DIGIT
.sub_10
cmpi  0a ; cmp 10
bcc   .random_digit_end ; bcc #RANDOM_DIGIT_END
sec   ; sec
sbci  0a ; sbc 10
bne   .sub_10 ; bne #SUB_10 
.random_digit_end
rts   ; rts

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
staz  .areg ; sta &'AREG
stxz  .xreg ; stx &'XREG
styz  .yreg ; sty &'YREG
rts   ; rts

.restore_regs
ldaz  .areg ; lda &'AREG
ldxz  .xreg ; ldx &'XREG
ldyz  .yreg ; ldy &'YREG
rts   ; rts

zbyte areg2
zbyte xreg2
zbyte yreg2

.save_regs2
staz  .areg2 ; sta &'AREG2
stxz  .xreg2 ; stx &'XREG2
styz  .yreg2 ; sty &'YREG2
rts   ; rts

.restore_regs2
ldaz  .areg2 ; lda &'AREG2
ldxz  .xreg2 ; ldx &'XREG2
ldyz  .yreg2 ; ldy &'YREG2
rts   ; rts
