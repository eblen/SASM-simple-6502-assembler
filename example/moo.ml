; Moo Program for Apple II
; Play a game of moo using lo-res graphics - entirely in machine language!

@'SHAPEMAP0
@'SHAPEMAP1
@'ROW_LIMIT
@'COLUMN_LIMIT
@'COLOR,8
@'DIGIT,4
@'DIGIT_INDEX ; Indicated by bits 0 and 1 - ignore 2-7
@'KEY
@'RANDOM
; Allocate TMPs in reverse order so they will be consecutive
; This is bad, bad, bad, because we are using hidden knowledge
; about how the zero-page allocator works. It is desirable,
; though, to have a set of tmps that are both consecutive and
; that we can use directly without indexing.
@'TMP4
@'TMP3
@'TMP2
@'TMP1
@'TMP0

; Initialization
20 58FC ; jsr FC58 ; clear screen
20 40FB ; jsr FB40 ; set lo-res graphics mode

; Set colors to 6
A2 07 ; ldx #7
A9 66 ; lda #66
@INIT_COLOR_VALUE
95 &'COLOR ; sta &'COLOR,x
CA ; dex
10 #INIT_COLOR_VALUE ; bpl #INIT_COLOR_VALUE

; Random number seed
A5 4F ; lda 4f
85 &'RANDOM ; sta &'RANDOM

; Generate the number to guess
A2 03 ; ldx #3
@GEN_DIGIT
20 &RANDOM_DIGIT ; jsr &RANDOM_DIGIT
95 &'DIGIT ; sta &'DIGIT,x
CA ; dex
10 #GEN_DIGIT ; bpl #GEN_DIGIT

; Set initial positions and extents for digits
A9 11 ; lda #17
85 &'ROW_LIMIT ; sta &'ROW_LIMIT
A9 26 ; lda #38
85 &'COLUMN_LIMIT ; sta &'COLUMN_LIMIT
A2 02 ; ldx #2
A0 01 ; ldy #1
A9 00 ; lda 0
85 &'DIGIT_INDEX ; sta &'DIGIT_INDEX

; Main Loop
@ENTER_DIGIT
; Read keyboard input
20 &SAVE_REGS
20 35 FD ; jsr FD35 ; Read key input
85 &'TMP0 ; sta &'TMP0
20 &RESTORE_REGS
A5 &'TMP0 ; lda &'TMP0

; Compute entered number (0-9)
38 ; sec
E9 B0 ; sbc $B0

; Compute key value - need to borrow A and X
; A contains entered digit - needed later.
; Two bits per key value as follows:
; cow: 11 bull: 10 sheep: 00
20 &SAVE_REGS
85 &'TMP0 ; sta &'TMP0 ; TMP0 holds the entered digit

; If we have a cow, rotate 1 into KEY
; Otherwise, rotate 0 into KEY
A5 &'DIGIT_INDEX ; lda &'DIGIT_INDEX
29 03 ; and %00000011
AA ; tax
B5 &'DIGIT ; lda &'DIGIT,x
C5 &'TMP0 ; cmp &'TMP0
18 ; clc
D0 #NO_COW ; bne #NO_COW
38 ; sec
@NO_COW
66 &'KEY ; ror &'KEY

; Now look at other digits:
; if digit is found rotate a 1 into KEY
; otherwise rotate a 0 into KEY
A2 03 ; ldx #3
@DIGIT_LOOP
B5 &'DIGIT ; lda &'DIGIT,x
C5 &'TMP0 ; cmp &'TMP0
F0 #NOT_SHEEP ; beq #NOT_SHEEP
CA ; dex
10 #DIGIT_LOOP ; bpl #DIGIT_LOOP
18 ; clc
D0 #IS_SHEEP ; bne #IS_SHEEP
@NOT_SHEEP
38 ; sec
@IS_SHEEP
66 &'KEY ; ror &'KEY
E6 &'DIGIT_INDEX ; inc &'DIGIT_INDEX
20 &RESTORE_REGS

; Compute correct map offset (2 * (entered number))
0A ; asl

; Store digit maps - need to borrow x
86 &'TMP0 ; stx &'TMP0
AA ; tax
BD &DIGIT_MAPS ; lda &DIGIT_MAPS,x
85 &'SHAPEMAP0 ; sta &'SHAPEMAP0
E8 ; inx
BD &DIGIT_MAPS ; lda &DIGIT_MAPS,x
85 &'SHAPEMAP1 ; sta &'SHAPEMAP1
A6 &'TMP0 ; ldx &'TMP0

; Now actually draw shape
8A ; txa
20 &DRAW_SHAPE ; jsr &DRAW_SHAPE

; increment y to next digit position
C8 ; iny
C8 ; iny
C8 ; iny
C8 ; iny

; Restart if we are still in the middle of a row
C4 &'ROW_LIMIT ; cpy &'ROW_LIMIT
D0 #ENTER_DIGIT ; bne #ENTER_DIGIT

; Draw key information
; First set colors correctly - need to borrow x and y
20 &SAVE_REGS

; Need to tally number of cows (TMP2), bulls (TMP1), and sheep (TMP0)
; (TMP0 not actually read but is written.)
A9 00 ; lda #0
85 &'TMP1 ; sta &'TMP1
85 &'TMP2 ; sta &'TMP2
A0 03 ; ldy #3
@TALLY_LOOP
A9 00 ; lda #0
66 &'KEY ; ror &'KEY
69 00 ; adc #0
66 &'KEY ; ror &'KEY
69 00 ; adc #0
AA ; tax
F6 &'TMP0 ; inc &'TMP0,x
88 ; dey
10 #TALLY_LOOP ; bpl #TALLY_LOOP

; Now change pixel colors
A9 0C ; lda 0C
85 &'TMP3 ; sta &'TMP3 ; TMP3 contains the shape pixel offset
A2 03 ; ldx #3
@NEXT_KEY_PIXEL
C6 &'TMP2 ; dec &'TMP2
30 #NOT_COW ; bmi #NOT_COW
A0 02 ; ldy #2
D0 #CHANGE_PIXEL ; bne #CHANGE_PIXEL
@NOT_COW
C6 &'TMP1 ; dec &'TMP1
30 #NOT_BULL ; bmi #NOT_BULL
A0 01 ; ldy #1
D0 #CHANGE_PIXEL ; bne #CHANGE_PIXEL
@NOT_BULL
A0 00 ; ldy #0
@CHANGE_PIXEL
B9 &KEY_COLORS ; lda &KEY_COLORS,y
85 30 ; sta 30
A5 &'TMP3 ; lda &'TMP3
20 &CHANGE_PIXEL_COLOR ; jsr &CHANGE_PIXEL_COLOR
38 ; sec
E9 03 ; sbc #3
85 &'TMP3 ; sta &'TMP3
CA ; dex
10 #NEXT_KEY_PIXEL ; bpl #NEXT_KEY_PIXEL
20 &RESTORE_REGS

; Next store key map
A9 12 ; lda 12
85 &'SHAPEMAP0 ; sta &'SHAPEMAP0
A9 48 ; lda 48
85 &'SHAPEMAP1 ; sta &'SHAPEMAP1

; Now actually draw key
8A ; txa
20 &DRAW_SHAPE ; jsr &DRAW_SHAPE

; Finally restore original colors
A9 66 ; lda 66
85 30 ; sta 30
A9 0C ; lda 0C
20 &CHANGE_PIXEL_COLOR ; jsr &CHANGE_PIXEL_COLOR
A9 09 ; lda 09
20 &CHANGE_PIXEL_COLOR ; jsr &CHANGE_PIXEL_COLOR
A9 06 ; lda 06
20 &CHANGE_PIXEL_COLOR ; jsr &CHANGE_PIXEL_COLOR
A9 03 ; lda 03
20 &CHANGE_PIXEL_COLOR ; jsr &CHANGE_PIXEL_COLOR
; End drawing of key information

; Increment x to next column
E8 ; inx
E8 ; inx
E8 ; inx
E8 ; inx
E8 ; inx
E8 ; inx

; Goto next column if we are at the bottom of the screen
E4 &'COLUMN_LIMIT ; cpx &'COLUMN_LIMIT
F0 #FINISH_COLUMN ; beq #FINISH_COLUMN

; Otherwise, reset y and restart
98 ; tya
38 ; sec
E9 10 ; sbc #16
A8 ; tay
4C &ENTER_DIGIT ; jmp @ENTER_DIGIT

@FINISH_COLUMN
; Return if this is the second column
C0 26 ; cpy #38
D0 #NEXT_COLUMN ; bne #NEXT_COLUMN
60 ; rts

; Reset x and y for second column
@NEXT_COLUMN
8A ; txa
38 ; sec
E9 24 ; sbc #36
AA ; tax
98 ; tya
18 ; clc
69 05 ; adc #5
A8 ; tay
; Also adjust horizontal extent
A9 26 ; lda #38
85 &'ROW_LIMIT ; sta &'ROW_LIMIT

; Always restart
4C &ENTER_DIGIT ; jmp @ENTER_DIGIT

; Subroutine to draw a 3x5 shape in lo-res graphics
; Input: A,Y - column and row of top-left corner of graphic
; Input: SHAPEMAP0, SHAPEMAP1 - shape description (zero page addresses)
; Input: COLOR[0-7] - color of each pixel (2 colors per byte)
; Note: By poking the correct addresses for the two adc instructions,
; and a few other minor adjustments, this routine could be made to work
; for any sized graphic.
@DRAW_SHAPE

20 &SAVE_REGS

; Store column in x
AA ; tax

; Store row + 5 in TMP0
18 ; clc
69 05 ; adc #5
85 &'TMP0 ; sta @TMP0

; Store column + 3 in TMP1
98 ; tya
69 03 ; adc #3
85 &'TMP1 ; sta @TMP1

; Store color index in TMP2
A9 00 ; lda #0
85 &'TMP2 ; sta &'TMP2

; Main Loop
@DRAW_ROW
; Plot if bit 15 in map is set
06 &'SHAPEMAP0 ; asl @SHAPEMAP0
90 #NO_PLOT ; bcc @NO_PLOT

; Set color value - need to borrow x
86 &'TMP3 ; stx &'TMP3

; Load correct color byte
A5 &'TMP2 ; lda &'TMP2
4A ; lsr
AA ; tax
B5 &'COLOR ; lda &'COLOR,x

; Create correct color value in A - borrow TMP4
85 &'TMP4 ; sta &'TMP4
B0 #TAKE_LEFT ; bcs #TAKE_LEFT

; Color value is in right nibble - duplicate on left
06 &'TMP4 ; asl &'TMP4
06 &'TMP4 ; asl &'TMP4
06 &'TMP4 ; asl &'TMP4
06 &'TMP4 ; asl &'TMP4
29 0F ; and 0F
05 &'TMP4 ; ora &'TMP4

; Color value is in left nibble - duplicate on right
@TAKE_LEFT
46 &'TMP4 ; lsr &'TMP4
46 &'TMP4 ; lsr &'TMP4
46 &'TMP4 ; lsr &'TMP4
46 &'TMP4 ; lsr &'TMP4
29 F0 ; and F0
05 &'TMP4 ; ora &'TMP4

; Store color value and restore x
85 30 ; sta 30
A6 &'TMP3 ; ldx &'TMP3 

8A ; txa
20 &SAVE_REGS2
20 00F8 ; jsr plot routine
20 &RESTORE_REGS2
@NO_PLOT
E6 &'TMP2 ; inc &'TMP2

; Finish double byte shift
06 &'SHAPEMAP1 ; asl @SHAPEMAP1
90 #NO_CARRY ; bcc @NO_CARRY
E6 &'SHAPEMAP0 ; inc @SHAPEMAP0
@NO_CARRY

; Resume if we are in the middle of a row
C8 ; iny
C4 &'TMP1 ; cpy @TMP1
D0 #DRAW_ROW ; bne @DRAW_ROW

; Check if we have finished. If so, go ahead and return
E8 ; inx
E4 &'TMP0 ; cpx @TMP0
D0 #NOT_DONE ; bne @NOT_DONE

20 &RESTORE_REGS
60 ; rts

; Reset y for the next row
@NOT_DONE
88 ; dey
88 ; dey
88 ; dey
4C &DRAW_ROW ; jmp @DRAW_ROW

@CHANGE_PIXEL_COLOR
; Input: A - pixel index
; Input: $0030 - color value
; Changes global COLOR array
20 &SAVE_REGS2 ; 2 because caller also saves regs - yes, this is poor design!
4A ; lsr
AA ; tax
B5 &'COLOR ; lda &'COLOR,x
B0 #KEEP_RIGHT_COLOR ; bcs #KEEP_RIGHT_COLOR
29 F0 ; and F0
95 &'COLOR ; sta &'COLOR,x
A5 30 ; lda 30
29 0F ; and 0F
15 &'COLOR ; ora &'COLOR,x
95 &'COLOR ; sta &'COLOR,x
4C &END_CHANGE_PIXEL_COLOR ; jmp &END_CHANGE_PIXEL_COLOR
@KEEP_RIGHT_COLOR
29 0F ; and 0F
95 &'COLOR ; sta &'COLOR,x
A5 30 ; lda 30
29 F0 ; and F0
15 &'COLOR ; ora &'COLOR,x
95 &'COLOR ; sta &'COLOR,x
@END_CHANGE_PIXEL_COLOR
20 &RESTORE_REGS2
60 ; rts

; Linear Congruential Random Number Generator
; Formula is x = (3x+13) mod 256
; Output - A holds random digit from 0-9
;          &'RANDOM is random byte used by RNG
; Only A is altered
@RANDOM_DIGIT
; RNG Algorithm
A5 &'RANDOM ; lda &'RANDOM
18 ; clc
65 &'RANDOM ; adc &'RANDOM
18 ; clc
65 &'RANDOM ; adc &'RANDOM
18 ; clc
69 0D ; adc #13
85 &'RANDOM ; sta &'RANDOM

; Use random number to get a digit 0-9
C9 FA ; cmp 250 ; ensures that all digits are equally likely (0-249 only)
B0 #RANDOM_DIGIT ; bcs #RANDOM_DIGIT
@SUB_10
C9 0A ; cmp 10
90 #RANDOM_DIGIT_END ; bcc #RANDOM_DIGIT_END
38 ; sec
E9 0A ; sbc 10
D0 #SUB_10 ; bne #SUB_10 ; always branch
@RANDOM_DIGIT_END
60 ; rts

; Digit shape maps
@DIGIT_MAPS
data  F6DF
data  2492
data  E7CF
data  E79F
data  B792
data  F39F
data  93DF
data  E492
data  F7DF
data  F79F

@KEY_COLORS
data  55 ; number not in solution (sheep)
data  BB ; number correct but in wrong plage (bull)
data  11 ; number correct and in right place (cow)

@'AREG
@'XREG
@'YREG

@SAVE_REGS
85 &'AREG ; sta &'AREG
86 &'XREG ; stx &'XREG
84 &'YREG ; sty &'YREG
60 ; rts

@RESTORE_REGS
A5 &'AREG ; lda &'AREG
A6 &'XREG ; ldx &'XREG
A4 &'YREG ; ldy &'YREG
60 ; rts

@'AREG2
@'XREG2
@'YREG2

@SAVE_REGS2
85 &'AREG2 ; sta &'AREG2
86 &'XREG2 ; stx &'XREG2
84 &'YREG2 ; sty &'YREG2
60 ; rts

@RESTORE_REGS2
A5 &'AREG2 ; lda &'AREG2
A6 &'XREG2 ; ldx &'XREG2
A4 &'YREG2 ; ldy &'YREG2
60 ; rts
