; Demo skeleton kernel for Atari 2600

; ---------- Standard Atari 2600 memory labels ----------
; TODO: Place in an include file once SASM supports that feature

; TIA Write Addresses
label vsync 00
label vblank 01
label wsync 02
label rsync 03
label nusiz0 04
label nusiz1 05
label colup0 06
label colup1 07
label colupf 08
label colubk 09
label ctrlpf 0a
label refp0 0b
label refp1 0c
label pf0 0d
label pf1 0e
label pf2 0f
label resp0 10
label resp1 11
label resm0 12
label resm1 13
label resbl 14
label audc0 15
label audc1 16
label audf0 17
label audf1 18
label audv0 19
label audv1 1a
label grp0 1b
label grp1 1c
label enam0 1d
label enam1 1e
label enabl 1f
label hmp0 20
label hmp1 21
label hmm0 22
label hmm1 23
label hmbl 24
label vdelp0 25
label vdelp1 26
label vdelbl 27
label resmp0 28
label resmp1 29
label hmove 2a
label hmclr 2b
label cxclr 2c

; TIA Read Addresses
label cxm0p 00
label cxm1p 01
label cxp0fb 02
label cxp1fb 03
label cxm0fb 04
label cxm1fb 05
label cxblpf 06
label cxppmm 07
label inpt0 08
label inpt1 09
label inpt2 0a
label inpt3 0b
label inpt4 0c
label inpt5 0d

; RIOT Chip
label swcha 280
label swacnt 281
label swchb 282
label swbcnt 283
label intim 284
label timint 285
label tim1t 294
label tim8t 295
label tim64t 296
label t1024t 297

; Increment each frame to produce effect of rolling color bars
zbyte start_color;

; Start of ROM code
org   f000

; Initialize variables
ldai  00
staz  .start_color

.mainloop
; Vertical Blanking
ldai  02
staz  .vsync
staz  .wsync
staz  .wsync
staz  .wsync
ldai  00
staz  .vsync
ldai  2b
staa  .tim64t ; clock expires just before end of 37th vertical blank line
              ; At that point, do one more "sta WSYNC" and then start processing.
  
; Sync to end of vertical blank period
.vbwait
ldaa  .intim
bne   .vbwait
staz  .wsync
staz  .vblank

; Draw screen
ldxi  b4
ldyz  .start_color
; 128 colors (odd values are duplicates)
incz  .start_color
incz  .start_color
.drawline
styz  .colubk
iny
iny
dex
staz  .wsync
bne   .drawline

; Set timer for overscan period
ldai  02
staz  .vblank
ldai  23
staa  .tim64t ; clock expires just before end of overscan.
              ; At that point, do one more "sta WSYNC" and then start new frame

; Overscan period
.oswait
ldaa  .intim
bne   .oswait

; Start new frame
staz  .wsync
jmpa  .mainloop

; Interrupt vectors
org   fffa
data  .mainloop ; NMI
data  .mainloop ; Reset
data  .mainloop ; IRQ
