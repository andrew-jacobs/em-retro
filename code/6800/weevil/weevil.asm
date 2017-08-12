;===============================================================================
; __	    __		    _ _
; \ \	   / /__  _____	  _(_) |
;  \ \ /\ / / _ \/ _ \ \ / / | |
;   \ V	 V /  __/  __/\ V /| | |
;    \_/\_/ \___|\___| \_/ |_|_|
;
; A New 6800 Monitor
;-------------------------------------------------------------------------------
; Copyright (C)2014-2017 HandCoded Software Ltd.
; All rights reserved.
;
; This work is made available under the terms of the Creative Commons
; Attribution-NonCommercial 2.0 license. Open the following URL to see the
; details.
;
; http://creativecommons.org/licenses/by-nc/2.0/
;-------------------------------------------------------------------------------
;
; Notes:
;
; Weevil is a new boot monitor for the 6800 that follows in the steps of HUMBUG
; by combining MIKBUG/SWTBUG compatibility with a new memory layout and command
; set.
;
; Weevil has been designed to work on the EM-RETRO 6800 emulator
;
;===============================================================================
; Revision History:
;
; 2015-01-02 AJ Initial version
;-------------------------------------------------------------------------------

		.include "../em-6800.inc"

;===============================================================================
; Constants
;===============================================================================

; ASCII Control Codes

EOT		.equ	$04
LF		.equ	$0a
CR		.equ	$0d

; Opcode Indexes

OP_ERR		.equ	0
OP_ABA		.equ	3
OP_ADC		.equ	6
OP_ADD		.equ	9
OP_AND		.equ	12
OP_ASL		.equ	15
OP_ASR		.equ	18
OP_BCC		.equ	21
OP_BCS		.equ	24
OP_BEQ		.equ	27
OP_BGE		.equ	30
OP_BGT		.equ	33
OP_BIT		.equ	36
OP_BHI		.equ	39
OP_BLE		.equ	42
OP_BLS		.equ	45
OP_BLT		.equ	48
OP_BMI		.equ	51
OP_BNE		.equ	54
OP_BPL		.equ	57
OP_BRA		.equ	60
OP_BSR		.equ	63
OP_BVC		.equ	66
OP_BVS		.equ	69
OP_CBA		.equ	72
OP_CLC		.equ	75
OP_CLI		.equ	78
OP_CLR		.equ	81
OP_CLV		.equ	84
OP_CMP		.equ	87
OP_COM		.equ	90
OP_CPX		.equ	93
OP_DAA		.equ	96
OP_DEC		.equ	99
OP_DES		.equ	102
OP_DEX		.equ	105
OP_EOR		.equ	108
OP_INC		.equ	111
OP_INS		.equ	114
OP_INX		.equ	117
OP_JMP		.equ	120
OP_JSR		.equ	123
OP_LDA		.equ	126
OP_LDS		.equ	129
OP_LDX		.equ	132
OP_LSR		.equ	135
OP_NEG		.equ	138
OP_NOP		.equ	141
OP_ORA		.equ	144
OP_PSH		.equ	147
OP_PUL		.equ	150
OP_ROL		.equ	153
OP_ROR		.equ	156
OP_RTI		.equ	159
OP_RTS		.equ	162
OP_SBA		.equ	165
OP_SBC		.equ	168
OP_SEC		.equ	171
OP_SEI		.equ	174
OP_SEV		.equ	177
OP_STA		.equ	180
OP_STS		.equ	183
OP_STX		.equ	186
OP_SUB		.equ	189
OP_SWI		.equ	192
OP_TAB		.equ	195
OP_TAP		.equ	198
OP_TBA		.equ	201
OP_TPA		.equ	204
OP_TST		.equ	207
OP_TSX		.equ	210
OP_TXS		.equ	213
OP_WAI		.equ	216
OP_SYS		.equ	219

AM_A		.equ	$40
AM_B		.equ	$80

AM_INH		.equ	$00
AM_DPG		.equ	$01
AM_IDX		.equ	$11
AM_REL		.equ	$21
AM_IMB		.equ	$31
AM_IMW		.equ	$02
AM_EXT		.equ	$12

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

		.bss
		.org	$a000

IRQV:		.space	2
NMIV:		.space	2
SWIV:		.space	2

SP:		.space	2
MPTR:		.space	2
OPCODE:		.space	1
MODE:		.space	1
TEMP:		.space	2

		.space	32
STACK:

;===============================================================================
; Interrupt Handlers
;-------------------------------------------------------------------------------

		.code
		.org	$e000

IRQ:
		ldx	IRQV		; Indirect through vector
		jmp	0,x

NMI:
		ldx	NMIV		; Indirect through vector
		jmp	0,x

SWI:
		ldx	SWIV		; Indirect through vector
		jmp	0,x

;-------------------------------------------------------------------------------

		.org	$e067		; MikBug OUTHL
OutHexHi:
		lsr a
		lsr a
		lsr a
		lsr a

		.org	$e06b		; MikBug OUTHR
OutHexLo:
		and a	#$0f
		ora a	#'0'
		cmp a	#'9'
		bls	OutChar
		add a	#7

		.org	$e075		; MikBug OUTCH & INCH
OutChar		jmp	UartTx
InChar		jmp	UartRx


		.org	$e07b		; MikBug PDATA1
OutStrLoop:
		bsr	OutChar
		inx
OutStr:
		lda a	0,x
		cmp a	#EOT
		bne	OutStrLoop
		rts

;===============================================================================
; Power On Reset
;-------------------------------------------------------------------------------

		.org	$e400
RESET:
		sei			; Ensure interrupts are disabled
		lds	#STACK
		ldx	#DummyHandler
		stx	NMIV
		stx	IRQV
		ldx	#DebugHandler
		stx	SWIV

		ldx	#SPLASH
		jsr	OutStr

.Loop		swi			; Enter the debugger
		bra	.Loop

DummyHandler:
		rti

;===============================================================================
; Output Utilities
;-------------------------------------------------------------------------------

; Fetch the PC from the stack and display it in hex. Save its value in the
; memory pointer to allow subsequent byte and opcode display.

ShowPC:
		ldx	SP		; Handle the PC MSB
		lda a	6,x
		sta a 	MPTR+0
		bsr	OutHex2	
		lda a	7,x		; .. the the PC LSB
		sta a 	MPTR+1
		bra	OutHex2

; Fetch the status register from the stack and then display its value as
; individual bits.

ShowP:
		ldx	#P_STR
		jsr	OutStr
		ldx	SP
		lda b	1,x
		lda a	#'1'
		bsr	ShowBit
		lda a	#'1'
		bsr	ShowBit
		lda a	#'H'
		bsr	ShowBit
		lda a	#'I'
		bsr	ShowBit
		lda a	#'N'
		bsr	ShowBit
		lda a	#'Z'
		bsr	ShowBit
		lda a	#'V'
		bsr	ShowBit
		lda a	#'C'

; Rotate a bit out of the status register in B. If it is clear the change the
; flag character to a full stop.

ShowBit:
		rol b
		bcs	.Skip
		lda a	#'.'
.Skip		jmp	UartTx

ShowA:
		ldx	#A_STR
		jsr	OutStr
		ldx	SP
		lda a	3,x
		bra	OutHex2

ShowB:
		ldx	#B_STR
		jsr	OutStr
		ldx	SP
		lda a	2,x
		bra	OutHex2

ShowX:
		ldx	#X_STR
		jsr	OutStr
		ldx	SP
		lda a	4,x
		bsr	OutHex2
		lda a 	5,x
		bra	OutHex2

ShowSP:
		ldx	#SP_STR
		jsr	OutStr
		lda a	SP+0
		bsr	OutHex2
		lda a	SP+1
		bra	OutHex2

OutHex2:
		psh a
		jsr	OutHexHi
		pul a
		jmp	OutHexLo

FetchOpcode:
		ldx	MPTR		; Fetch the target opcode
		lda b	#>OPCODES	; And calculate description address
		lda a 	0,x
		asl a
		bcc	.Skip
		inc b
.Skip		sta b	TEMP+0		; Load into X
		sta a	TEMP+1
		ldx	TEMP
		lda a	0,x		; And fetch the description
		sta a	OPCODE
		lda a	1,x
		sta a	MODE
		rts

ShowBytes:
		ldx	MPTR
		lda b	MODE
		and b	#$03
		bsr	Space
		lda a	0,x
		bsr	OutHex2
		dec b
		bmi	.Blank2
		bsr	Space
		lda a	1,x
		bsr	OutHex2
		dec b
		bmi	.Blank1
		bsr	Space
		lda a	2,x
		bra	OutHex2
		
.Blank2:	bsr	.Blank1
.Blank1:	bsr	Space
		bsr	Space

Space:
		lda a	#' '
		jmp	UartTx

ShowOpcode:
		lda b	#>MNEMONICS	; Work out mnemonic address
		lda a	#<MNEMONICS
		add a	OPCODE
		sta b	TEMP+0		; And transfer to X
		sta a	TEMP+1
		ldx	TEMP
		bsr	Space		; Output initial space
		lda a	0,x		; Then the opcode
		jsr 	UartTx
		lda a	1,x
		jsr	UartTx
		lda a	2,x
		jsr	UartTx
		bsr	Space		; Another space
		lda a	#' '
		lda b 	MODE		; Display accumulator (if any)
		bit b	#AM_A
		beq	.SkipA
		lda a	#'A'
.SkipA		bit b	#AM_B
		beq	.SkipB
		lda a	#'B'
.SkipB		jsr	UartTx
		
		
		
		rts


;===============================================================================
; Software Interrupt
;-------------------------------------------------------------------------------

P_STR		.byte	" P=",EOT
A_STR:		.byte	" A=",EOT
B_STR		.byte	" B=",EOT
X_STR		.byte	" X=",EOT
SP_STR		.byte	" SP=",EOT

; SP => | +0 | <next slot>
;       | +1 | CCR
;       | +2 | ACCB
;       | +3 | ACCA
;       | +4 | XH
;       | +5 | XL
;       | +6 | PCH
;       | +7 | PCL

DebugHandler:
		sts	SP		; Save users SP
		tsx
		tst	6,x		; Decrement PC
		bne	.Skip
		dec	5,x
.Skip		dec	6,x

ShowRegisters:
		jsr	ShowPC
		jsr	FetchOpcode
		jsr	ShowBytes
		jsr	ShowOpcode
		jsr	ShowA
		jsr	ShowB
		jsr	ShowX
		jsr	ShowP
		jsr	ShowSP
		
		bra	$

;===============================================================================
; I/O Routines
;-------------------------------------------------------------------------------

UartTx:
		psh a
.Wait		SYS_A	CMD_IFR
		and a	#INT_UART_TX
		beq	.Wait
		pul a
		SYS_A	CMD_TXD
		rts

UartRx:
		SYS_A	CMD_IFR
		and a	#INT_UART_RX
		bne	UartRx
		SYS_A	CMD_RXD
		rts

;===============================================================================
;-------------------------------------------------------------------------------

		.org	$fd00
OPCODES:
		.byte	OP_ERR,	    AM_INH	; 00 -
		.byte	OP_NOP,	    AM_INH	; 01 - NOP
		.byte	OP_ERR,	    AM_INH	; 02 -
		.byte	OP_ERR,	    AM_INH	; 03 -
		.byte	OP_ERR,	    AM_INH	; 04 -
		.byte	OP_ERR,	    AM_INH	; 05 -
		.byte	OP_TAP,	    AM_INH	; 06 - TAP
		.byte	OP_TPA,	    AM_INH	; 07 - TPA
		.byte	OP_INX,	    AM_INH	; 08 - INX
		.byte	OP_DEX,	    AM_INH	; 09 - DEX
		.byte	OP_CLV,	    AM_INH	; 0a - CLV
		.byte	OP_SEV,	    AM_INH	; 0b - SEV
		.byte	OP_CLC,	    AM_INH	; 0c - CLC
		.byte	OP_SEC,	    AM_INH	; 0d - SEC
		.byte	OP_CLI,	    AM_INH	; 0e - CLI
		.byte	OP_SEI,	    AM_INH	; 0f - SEI

		.byte	OP_SBA,	    AM_INH	; 10 - SBA
		.byte	OP_CBA,	    AM_INH	; 11 - CBA
		.byte	OP_ERR,	    AM_INH	; 12 -
		.byte	OP_ERR,	    AM_INH	; 13 -
		.byte	OP_ERR,	    AM_INH	; 14 -
		.byte	OP_ERR,	    AM_INH	; 15 -
		.byte	OP_TAB,	    AM_INH	; 16 - TAB
		.byte	OP_TBA,	    AM_INH	; 17 - TBA
		.byte	OP_ERR,	    AM_INH	; 18 -
		.byte	OP_DAA,	    AM_INH	; 19 - DAA
		.byte	OP_ERR,	    AM_INH	; 1a -
		.byte	OP_ABA,	    AM_INH	; 1b - ABA
		.byte	OP_ERR,	    AM_INH	; 1c -
		.byte	OP_ERR,	    AM_INH	; 1d -
		.byte	OP_ERR,	    AM_INH	; 1e -
		.byte	OP_ERR,	    AM_INH	; 1f -

		.byte	OP_BRA,	    AM_REL	; 20 - BRA rel
		.byte	OP_ERR,	    AM_INH	; 21 -
		.byte	OP_BHI,	    AM_REL	; 22 - BHI rel
		.byte	OP_BLS,	    AM_REL	; 23 - BLS rel
		.byte	OP_BCC,	    AM_REL	; 24 - BCC rel
		.byte	OP_BCS,	    AM_REL	; 25 - BCS rel
		.byte	OP_BNE,	    AM_REL	; 26 - BNE rel
		.byte	OP_BEQ,	    AM_REL	; 27 - BEQ rel
		.byte	OP_BVC,	    AM_REL	; 28 - BVC rel
		.byte	OP_BVS,	    AM_REL	; 29 - BVS rel
		.byte	OP_BPL,	    AM_REL	; 2a - BPL rel
		.byte	OP_BMI,	    AM_REL	; 2b - BMI rel
		.byte	OP_BGE,	    AM_REL	; 2c - BGE rel
		.byte	OP_BLT,	    AM_REL	; 2d - BLT rel
		.byte	OP_BGT,	    AM_REL	; 2e - BGT rel
		.byte	OP_BLE,	    AM_REL	; 2f - BLE rel

		.byte	OP_TSX,	    AM_INH	; 30 - TSX
		.byte	OP_INS,	    AM_INH	; 31 - INS
		.byte	OP_PUL,AM_A|AM_INH	; 32 - PUL A
		.byte	OP_PUL,AM_B|AM_INH	; 33 - PUL B
		.byte	OP_DES,	    AM_INH	; 34 - DES
		.byte	OP_TXS,	    AM_INH	; 35 - TXS
		.byte	OP_PSH,AM_A|AM_INH	; 36 - PSH A
		.byte	OP_PSH,AM_B|AM_INH	; 37 - PSH B
		.byte	OP_ERR,	    AM_INH	; 38 -
		.byte	OP_RTS,	    AM_INH	; 39 - RTS
		.byte	OP_ERR,	    AM_INH	; 3a -
		.byte	OP_RTI,	    AM_INH	; 3b - RTI
		.byte	OP_ERR,	    AM_INH	; 3c -
		.byte	OP_ERR,	    AM_INH	; 3d -
		.byte	OP_WAI,	    AM_INH	; 3e - WAI
		.byte	OP_SWI,	    AM_INH	; 3f - SWI

		.byte	OP_NEG,AM_A|AM_INH	; 40 - NEG A
		.byte	OP_ERR,	    AM_INH	; 41 -
		.byte	OP_ERR,	    AM_INH	; 42 -
		.byte	OP_COM,AM_A|AM_INH	; 43 - COM A
		.byte	OP_LSR,AM_A|AM_INH	; 44 - LSR A
		.byte	OP_ERR,	    AM_INH	; 45 -
		.byte	OP_ROR,AM_A|AM_INH	; 46 - ROR A
		.byte	OP_ASR,AM_A|AM_INH	; 47 - ASR A
		.byte	OP_ASL,AM_A|AM_INH	; 48 - ASL A
		.byte	OP_ROL,AM_A|AM_INH	; 49 - ROL A
		.byte	OP_DEC,AM_A|AM_INH	; 4a - DEC A
		.byte	OP_ERR,	    AM_INH	; 4b -
		.byte	OP_INC,AM_A|AM_INH	; 4c - INC A
		.byte	OP_TST,AM_A|AM_INH	; 4d - TST A
		.byte	OP_ERR,	    AM_INH	; 4e -
		.byte	OP_CLR,AM_A|AM_INH	; 4f - CLR A

		.byte	OP_NEG,AM_B|AM_INH	; 50 - NEG B
		.byte	OP_ERR,	    AM_INH	; 51 -
		.byte	OP_ERR,	    AM_INH	; 52 -
		.byte	OP_COM,AM_B|AM_INH	; 53 - COM B
		.byte	OP_LSR,AM_B|AM_INH	; 54 - LSR B
		.byte	OP_ERR,	    AM_INH	; 55 -
		.byte	OP_ROR,AM_B|AM_INH	; 56 - ROR B
		.byte	OP_ASR,AM_B|AM_INH	; 57 - ASR B
		.byte	OP_ASL,AM_B|AM_INH	; 58 - ASL B
		.byte	OP_ROL,AM_B|AM_INH	; 59 - ROL B
		.byte	OP_DEC,AM_B|AM_INH	; 5a - DEC B
		.byte	OP_ERR,	    AM_INH	; 5b -
		.byte	OP_INC,AM_B|AM_INH	; 5c - INC B
		.byte	OP_TST,AM_B|AM_INH	; 5d - TST B
		.byte	OP_ERR,	    AM_INH	; 5e -
		.byte	OP_CLR,AM_B|AM_INH	; 5f - CLR B

		.byte	OP_NEG,	    AM_IDX	; 60 - NEG idx,X
		.byte	OP_ERR,	    AM_INH	; 61 -
		.byte	OP_ERR,	    AM_INH	; 62 -
		.byte	OP_COM,	    AM_IDX	; 63 - COM idx,X
		.byte	OP_LSR,	    AM_IDX	; 64 - LSR idx,X
		.byte	OP_ERR,	    AM_INH	; 65 -
		.byte	OP_ROR,	    AM_IDX	; 66 - ROR idx,X
		.byte	OP_ASR,	    AM_IDX	; 67 - ASR idx,X
		.byte	OP_ASL,	    AM_IDX	; 68 - ASL idx,X
		.byte	OP_ROL,	    AM_IDX	; 69 - ROL idx,X
		.byte	OP_DEC,	    AM_IDX	; 6a - DEC idx,X
		.byte	OP_ERR,	    AM_INH	; 6b -
		.byte	OP_INC,	    AM_IDX	; 6c - INC idx,X
		.byte	OP_TST,	    AM_IDX	; 6d - TST idx,X
		.byte	OP_JMP,	    AM_IDX	; 6e - JMP idx,X
		.byte	OP_CLR,	    AM_IDX	; 6f - CLR idx,X

		.byte	OP_NEG,	    AM_EXT	; 70 - NEG ext
		.byte	OP_ERR,	    AM_INH	; 71 -
		.byte	OP_ERR,	    AM_INH	; 72 -
		.byte	OP_COM,	    AM_EXT	; 73 - COM ext
		.byte	OP_LSR,	    AM_EXT	; 74 - LSR ext
		.byte	OP_ERR,	    AM_INH	; 75 -
		.byte	OP_ROR,	    AM_EXT	; 76 - ROR ext
		.byte	OP_ASR,	    AM_EXT	; 77 - ASR ext
		.byte	OP_ASL,	    AM_EXT	; 78 - ASL ext
		.byte	OP_ROL,	    AM_EXT	; 79 - ROL ext
		.byte	OP_DEC,	    AM_EXT	; 7a - DEC ext
		.byte	OP_ERR,	    AM_INH	; 7b -
		.byte	OP_INC,	    AM_EXT	; 7c - INC ext
		.byte	OP_TST,	    AM_EXT	; 7d - TST ext
		.byte	OP_JMP,	    AM_EXT	; 7e - JMP ext
		.byte	OP_CLR,	    AM_EXT	; 7f - CLR ext

		.byte	OP_SUB,AM_A|AM_IMB	; 80 - SUB A #imm
		.byte	OP_CMP,AM_A|AM_IMB	; 81 - CMP A #imm
		.byte	OP_SBC,AM_A|AM_IMB	; 82 - SBC A #imm
		.byte	OP_ERR,	    AM_INH	; 83 -
		.byte	OP_AND,AM_A|AM_IMB	; 84 - AND A #imm
		.byte	OP_BIT,AM_A|AM_IMB	; 85 - BIT A #imm
		.byte	OP_LDA,AM_A|AM_IMB	; 86 - LDA A #imm
		.byte	OP_ERR,	    AM_INH	; 87 -
		.byte	OP_EOR,AM_A|AM_IMB	; 88 - EOR A #imm
		.byte	OP_ADC,AM_A|AM_IMB	; 89 - ADC A #imm
		.byte	OP_ORA,AM_A|AM_IMB	; 8a - ORA A #imm
		.byte	OP_ADD,AM_A|AM_IMB	; 8b - ADD A #imm
		.byte	OP_CPX,	    AM_IMW	; 8c - CPX #imm
		.byte	OP_BSR,	    AM_REL	; 8d - BSR rel
		.byte	OP_LDS,	    AM_IMW	; 8e - LDS #imm
		.byte	OP_SYS,AM_A|AM_IMB	; 8f - *SYS A #imm

		.byte	OP_SUB,AM_A|AM_DPG	; 90 - SUB A dir
		.byte	OP_CMP,AM_A|AM_DPG	; 91 - CMP A dir
		.byte	OP_SBC,AM_A|AM_DPG	; 92 - SBC A dir
		.byte	OP_ERR,	    AM_INH	; 93 -
		.byte	OP_AND,AM_A|AM_DPG	; 94 - AND A dir
		.byte	OP_BIT,AM_A|AM_DPG	; 95 - BIT A dir
		.byte	OP_LDA,AM_A|AM_DPG	; 96 - LDA A dir
		.byte	OP_STA,AM_A|AM_DPG	; 97 - STA A dir
		.byte	OP_EOR,AM_A|AM_DPG	; 98 - EOR A dir
		.byte	OP_ADC,AM_A|AM_DPG	; 99 - ADC A dir
		.byte	OP_ORA,AM_A|AM_DPG	; 9a - ORA A dir
		.byte	OP_ADD,AM_A|AM_DPG	; 9b - ADD A dir
		.byte	OP_CPX,	    AM_DPG	; 9c - CPX dir
		.byte	OP_ERR,	    AM_INH	; 9d -
		.byte	OP_LDS,	    AM_DPG	; 9e - LDS dir
		.byte	OP_STS,	    AM_DPG	; 9f - STS dir

		.byte	OP_SUB,AM_A|AM_IDX	; a0 - SUB A idx,X
		.byte	OP_CMP,AM_A|AM_IDX	; a1 - CMP A idx,X
		.byte	OP_SBC,AM_A|AM_IDX	; a2 - SBC A idx,X
		.byte	OP_ERR,	    AM_INH	; a3 -
		.byte	OP_AND,AM_A|AM_IDX	; a4 - AND A idx,X
		.byte	OP_BIT,AM_A|AM_IDX	; a5 - BIT A idx,X
		.byte	OP_LDA,AM_A|AM_IDX	; a6 - LDA A idx,X
		.byte	OP_STA,AM_A|AM_IDX	; a7 - STA A idx,X
		.byte	OP_EOR,AM_A|AM_IDX	; a8 - EOR A idx,X
		.byte	OP_ADC,AM_A|AM_IDX	; a9 - ADC A idx,X
		.byte	OP_ORA,AM_A|AM_IDX	; aa - ORA A idx,X
		.byte	OP_ADD,AM_A|AM_IDX	; ab - ADD A idx,X
		.byte	OP_CPX,	    AM_IDX	; ac - CPX idx,X
		.byte	OP_JSR,	    AM_IDX	; ad - JSR idx,X
		.byte	OP_LDS,	    AM_IDX	; ae - LDS idx,X
		.byte	OP_STS,	    AM_IDX	; af - STS idx,X

		.byte	OP_SUB,AM_A|AM_EXT	; b0 - SUB A ext
		.byte	OP_CMP,AM_A|AM_EXT	; b1 - CMP A ext
		.byte	OP_SBC,AM_A|AM_EXT	; b2 - SBC A ext
		.byte	OP_ERR,	    AM_INH	; b3 -
		.byte	OP_AND,AM_A|AM_EXT	; b4 - AND A ext
		.byte	OP_BIT,AM_A|AM_EXT	; b5 - BIT A ext
		.byte	OP_LDA,AM_A|AM_EXT	; b6 - LDA A ext
		.byte	OP_STA,AM_A|AM_EXT	; b7 - STA A ext
		.byte	OP_EOR,AM_A|AM_EXT	; b8 - EOR A ext
		.byte	OP_ADC,AM_A|AM_EXT	; b9 - ADC A ext
		.byte	OP_ORA,AM_A|AM_EXT	; ba - ORA A ext
		.byte	OP_ADD,AM_A|AM_EXT	; bb - ADD A ext
		.byte	OP_CPX,	    AM_EXT	; bc - CPX ext
		.byte	OP_JSR,	    AM_EXT	; bd - JSR ext
		.byte	OP_LDS,	    AM_EXT	; be - LDS ext
		.byte	OP_STS,	    AM_EXT	; bf - STS ext

		.byte	OP_SUB,AM_B|AM_IMB	; c0 - SUB B #imm
		.byte	OP_CMP,AM_B|AM_IMB	; c1 - CMP B #imm
		.byte	OP_SBC,AM_B|AM_IMB	; c2 - SBC B #imm
		.byte	OP_ERR,	    AM_INH	; c3 -
		.byte	OP_AND,AM_B|AM_IMB	; c4 - AND B #imm
		.byte	OP_BIT,AM_B|AM_IMB	; c5 - BIT B #imm
		.byte	OP_LDA,AM_B|AM_IMB	; c6 - LDA B #imm
		.byte	OP_ERR,	    AM_INH	; c7 -
		.byte	OP_EOR,AM_B|AM_IMB	; c8 - EOR B #imm
		.byte	OP_ADC,AM_B|AM_IMB	; c9 - ADC B #imm
		.byte	OP_ORA,AM_B|AM_IMB	; ca - ORA B #imm
		.byte	OP_ADD,AM_B|AM_IMB	; cb - ADD B #imm
		.byte	OP_ERR,	    AM_INH	; cc -
		.byte	OP_ERR,	    AM_INH	; cd -
		.byte	OP_LDX,	    AM_IMW	; ce - LDX #imm
		.byte	OP_SYS,AM_B|AM_IMB	; cf - *SYS B #imm

		.byte	OP_SUB,AM_B|AM_DPG	; d0 - SUB B dir
		.byte	OP_CMP,AM_B|AM_DPG	; d1 - CMP B dir
		.byte	OP_SBC,AM_B|AM_DPG	; d2 - SBC B dir
		.byte	OP_ERR,	    AM_INH	; d3 -
		.byte	OP_AND,AM_B|AM_DPG	; d4 - AND B dir
		.byte	OP_BIT,AM_B|AM_DPG	; d5 - BIT B dir
		.byte	OP_LDA,AM_B|AM_DPG	; d6 - LDA B dir
		.byte	OP_STA,AM_B|AM_DPG	; d7 -STA B dir
		.byte	OP_EOR,AM_B|AM_DPG	; d8 - EOR B dir
		.byte	OP_ADC,AM_B|AM_DPG	; d9 - ADC B dir
		.byte	OP_ORA,AM_B|AM_DPG	; da - ORA B bir
		.byte	OP_ADD,AM_B|AM_DPG	; db - ADD B dir
		.byte	OP_ERR,	    AM_INH	; dc -
		.byte	OP_ERR,	    AM_INH	; dd -
		.byte	OP_LDX,	    AM_DPG	; de - LDX dir
		.byte	OP_STX,	    AM_DPG	; df - STX dir

		.byte	OP_SUB,AM_B|AM_IDX	; e0 - SUB B idx,X
		.byte	OP_CMP,AM_B|AM_IDX	; e1 - CMP B idx,X
		.byte	OP_SBC,AM_B|AM_IDX	; e2 - SBC B idx,X
		.byte	OP_ERR,	    AM_INH	; e3 -
		.byte	OP_AND,AM_B|AM_IDX	; e4 - AND B idx,X
		.byte	OP_BIT,AM_B|AM_IDX	; e5 - BIT B idx,X
		.byte	OP_LDA,AM_B|AM_IDX	; e6 - LDA B idx,X
		.byte	OP_STA,AM_B|AM_IDX	; e7 - STA B idx,X
		.byte	OP_EOR,AM_B|AM_IDX	; e8 - EOR B idx,X
		.byte	OP_ADC,AM_B|AM_IDX	; e9 - ADC B idx,X
		.byte	OP_ORA,AM_B|AM_IDX	; ea - ORA B idx,X
		.byte	OP_ADD,AM_B|AM_IDX	; eb - ADD B idx,X
		.byte	OP_ERR,	    AM_INH	; ec -
		.byte	OP_ERR,	    AM_INH	; ed -
		.byte	OP_LDX,	    AM_IDX	; ee - LDX idx,X
		.byte	OP_STX,	    AM_IDX	; ef - STX idx,X

		.byte	OP_SUB,AM_B|AM_EXT	; f0 - SUB B ext
		.byte	OP_CMP,AM_B|AM_EXT	; f1 - CMP B ext
		.byte	OP_SBC,AM_B|AM_EXT	; f2 - SBC B ext
		.byte	OP_ERR,	    AM_INH	; f3 -
		.byte	OP_AND,AM_B|AM_EXT	; f4 - AND B ext
		.byte	OP_BIT,AM_B|AM_EXT	; f5 - BIT B ext
		.byte	OP_LDA,AM_B|AM_EXT	; f6 - LDA B ext
		.byte	OP_STA,AM_B|AM_EXT	; f7 - STA B ext
		.byte	OP_EOR,AM_B|AM_EXT	; f8 - EOR B ext
		.byte	OP_ADC,AM_B|AM_EXT	; f9 - ADC B ext
		.byte	OP_ORA,AM_B|AM_EXT	; fa - ORA B ext
		.byte	OP_ADD,AM_B|AM_EXT	; fb - ADD B ext
		.byte	OP_ERR,	    AM_INH	; fc -
		.byte	OP_ERR,	    AM_INH	; fd -
		.byte	OP_LDX,	    AM_EXT	; fe - LDX ext
		.byte	OP_STX,	    AM_EXT	; ff - STX ext

MNEMONICS:
		.byte	"???","ABA","ADC","ADD"
		.byte	"AND","ASL","ASR","BCC"
		.byte	"BCS","BEQ","BGE","BGT"
		.byte	"BIT","BHI","BLE","BLS"
		.byte	"BLT","BMI","BNE","BPL"
		.byte	"BRA","BSR","BVC","BVS"
		.byte	"CBA","CLC","CLI","CLR"
		.byte	"CLV","CMP","COM","CPX"
		.byte	"DAA","DEC","DES","DEX"
		.byte	"EOR","INC","INS","INX"
		.byte	"JMP","JSR","LDA","LDS"
		.byte	"LDX","LSR","NEG","NOP"
		.byte	"ORA","PSH","PUL","ROL"
		.byte	"ROR","RTI","RTS","SBA"
		.byte	"SBC","SEC","SEI","SEV"
		.byte	"STA","STS","STX","SUB"
		.byte	"SWI","TAB","TAP","TBA"
		.byte	"TPA","TST","TSX","TXS"
		.byte	"WAI","SYS"

SPLASH:		.byte	"Weevil [17.08]"
CRLF:		.byte	CR,LF,EOT

;===============================================================================
; Vectors
;-------------------------------------------------------------------------------

		.org	$fff8

		.word	IRQ
		.word	SWI
		.word	NMI
		.word	RESET

		.end