;
; C64CD YOUTUBE INTRO
;

; Code and graphics by TMR
; Music by Odie


; Notes: this source is formatted for the ACME cross assembler available
; from http://sourceforge.net/projects/acme-crossass/


; Select an output filename
		!to "youtube.prg",cbm


; Pull in the binary data
		* = $1000
music		!binary "binary\4k_party_2.prg",,2

		* = $2000
		!binary "binary\zoomed_rom.chr"


; Raster split positions
raster_1_pos	= $2c
raster_2_pos	= $a2

; Label assignments
raster_num	= $50
scroll_y	= $51
scroll_pos	= $52		; two bytes used
char_mode	= $54


; Add a BASIC startline
		* = $0801
		!word code_start-2
		!byte $40,$00,$9e
		!text "2066"
		!byte $00,$00,$00


; Entry point for the code
		* = $0812

; Stop interrupts, disable the ROMS and set up NMI and IRQ interrupt pointers
code_start	sei

		lda #$35
		sta $01

		lda #<nmi_int
		sta $fffa
		lda #>nmi_int
		sta $fffb

		lda #<irq_int
		sta $fffe
		lda #>irq_int
		sta $ffff

; Set the VIC-II up for a raster IRQ interrupt
		lda #$7f
		sta $dc0d
		sta $dd0d

		lda $dc0d
		lda $dd0d

		lda #raster_1_pos
		sta $d012

		lda #$1b
		sta $d011
		lda #$01
		sta $d019
		sta $d01a

; Initialise some of our own labels
		lda #$01
		sta raster_num

; Clear the screen
		ldx #$00
screen_clear	lda #$40
		sta $0400,x
		sta $0500,x
		sta $0600,x
		sta $06e8,x
		lda #$0a
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $dae8,x
		inx
		bne screen_clear

; Reset the scroller
		jsr scroll_reset
		lda #$00
		sta scroll_y
		sta char_mode

; Set up the music driver
		ldx #$00
		txa
		tay
		jsr music+$00


; Restart the interrupts
		cli

; Infinite loop - all of the code is executing on the interrupt
		jmp *


; IRQ interrupt handler
irq_int		pha
		txa
		pha
		tya
		pha

		lda $d019
		and #$01
		sta $d019
		bne int_go
		jmp irq_exit

; An interrupt has triggered
int_go		lda raster_num
		cmp #$02
		bne *+$05
		jmp irq_rout2


; Raster split 1
irq_rout1	lda #$0a
		sta $d020
		lda #$02
		sta $d021
		lda scroll_y
		lsr
		and #$07
		eor #$17
		sta $d011
		lda #$18
		sta $d018

; Play the music
		jsr music+$03

; Set interrupt handler for split 2
		lda #$02
		sta raster_num
		lda #raster_2_pos
		sta $d012

; Exit IRQ interrupt
		jmp irq_exit


; Raster split 2
irq_rout2	ldy scroll_y
		iny
		cpy #$10
		beq *+$05
		jmp sy_xb

; Scroll the first chunk of screen RAM up
		ldx #$00
scroll_up_1	lda $0428,x
		sta $0400,x
		lda $0450,x
		sta $0428,x
		lda $0478,x
		sta $0450,x
		lda $04a0,x
		sta $0478,x

		lda $04c8,x
		sta $04a0,x
		lda $04f0,x
		sta $04c8,x
		lda $0518,x
		sta $04f0,x
		lda $0540,x
		sta $0518,x

		lda $0568,x
		sta $0540,x
		lda $0590,x
		sta $0568,x
		lda $05b8,x
		sta $0590,x
		lda $05e0,x
		sta $05b8,x
		inx
		cpx #$28
		bne scroll_up_1

; Scroll the second chunk of screen RAM up
		ldx #$00
scroll_up_2	lda $0608,x
		sta $05e0,x
		lda $0630,x
		sta $0608,x
		lda $0658,x
		sta $0630,x
		lda $0680,x
		sta $0658,x

		lda $06a8,x
		sta $0680,x
		lda $06d0,x
		sta $06a8,x
		lda $06f8,x
		sta $06d0,x
		lda $0720,x
		sta $06f8,x

		lda $0748,x
		sta $0720,x
		lda $0770,x
		sta $0748,x
		lda $0798,x
		sta $0770,x
		lda $07c0,x
		sta $0798,x
		inx
		cpx #$28
		bne scroll_up_2

; Do we need a new line or just the lower half of the previous one?
		lda char_mode
		beq scroll_new_line

; The current line needs finishing off
		ldx #$00
scroll_make_lwr	lda $07c0,x
		ora #$80
		sta $07c0,x
		inx
		cpx #$28
		bne scroll_make_lwr

		lda #$00
		sta char_mode

		jmp sy_xb-$02

; The previous line is done, pull in a new one
scroll_new_line	ldx #$00
		ldy #$00
scroll_mread	lda (scroll_pos),y
		bne scroll_okay
		jsr scroll_reset
		jmp scroll_mread

scroll_okay	asl
		sta $07c0,x
		clc
		adc #$01
		sta $07c1,x
		inx
		inx
		iny
		cpy #$14
		bne scroll_mread

; Nudge the scroller onto the next line
		lda scroll_pos+$00
		clc
		adc #$14
		bcc *+$04
		inc scroll_pos+$01
		sta scroll_pos+$00

		lda #$01
		sta char_mode

; No scrolling needed
		ldy #$00
sy_xb		sty scroll_y

; Set interrupt handler for split 1
		lda #$01
		sta raster_num
		lda #raster_1_pos
		sta $d012


; Restore registers and exit IRQ interrupt
irq_exit	pla
		tay
		pla
		tax
		pla
nmi_int		rti


; Subroutine to reset the scrolling message
scroll_reset	lda #<scroll_text
		sta scroll_pos+$00
		lda #>scroll_text
		sta scroll_pos+$01
		rts


; The all-important scrolling message - arranged in 20 byte chunks
		* = $2800
scroll_text	!scr "                    "
		!scr "                    "
		!scr "hello dear reader!  "
		!scr "                    "
		!scr "                    "

		!scr "welcome to the c64cd"
		!scr "channel at youtube  "
		!scr "which supports the  "
		!scr "c64 crap debunk blog"
		!scr "                    "
		!scr "                    "

		!scr "this video is actual"
		!scr "c64 code as well,   "
		!scr "written by c64cd's  "
		!scr "correspondent t.m.r "
		!scr "with music provided "
		!scr "by odie.            "
		!scr "                    "

		!scr "the source code for "
		!scr "it is available from"
		!scr "github - linkage in "
		!scr "the description.    "
		!scr "                    "
		!scr "                    "

		!scr "greetings to all    "
		!scr "8-bit fans from the "
		!scr "past, present and   "
		!scr "indeed future, along"
		!scr "with anyone daft    "
		!scr "enough to read the  "
		!scr "c64cd blog or this  "
		!scr "scroller...!        "
		!scr "                    "
		!scr "                    "

		!scr "thanks for watching!"
		!scr "                    "
		!scr "                    "
		!scr "                    "
		!scr "                    "
		!scr "                    "
		!scr "                    "

		!scr "c64 crap debunk  c64"
		!scr "64 crap debunk  c64 "
		!scr "4 crap debunk  c64 c"
		!scr " crap debunk  c64 cr"
		!scr "crap debunk  c64 cra"
		!scr "rap debunk  c64 crap"
		!scr "ap debunk  c64 crap "
		!scr "p debunk  c64 crap d"
		!scr " debunk  c64 crap de"
		!scr "debunk  c64 crap deb"
		!scr "ebunk  c64 crap debu"
		!scr "bunk  c64 crap debun"
		!scr "unk  c64 crap debunk"
		!scr "nk  c64 crap debunk "
		!scr "k  c64 crap debunk  "
		!scr "  c64 crap debunk  c"
		!scr " c64 crap debunk  c6"
		!scr "c64 crap debunk  c64"
		!scr "64 crap debunk  c64 "
		!scr "4 crap debunk  c64 c"
		!scr " crap debunk  c64 cr"
		!scr "crap debunk  c64 cra"
		!scr "rap debunk  c64 crap"
		!scr "ap debunk  c64 crap "
		!scr "p debunk  c64 crap d"
		!scr " debunk  c64 crap de"
		!scr "debunk  c64 crap deb"
		!scr "ebunk  c64 crap debu"
		!scr "bunk  c64 crap debun"
		!scr "unk  c64 crap debunk"
		!scr "nk  c64 crap debunk "
		!scr "k  c64 crap debunk  "
		!scr "  c64 crap debunk  c"
		!scr " c64 crap debunk  c6"
		!scr "c64 crap debunk  c64"

		!scr "                    "
		!scr "                    "
		!scr "                    "
		!scr "                    "


		!byte $00