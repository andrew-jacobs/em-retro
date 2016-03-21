;===============================================================================
;  __  __  ___  ____    _____                 _       _   _
; |  \/  |/ _ \/ ___|  | ____|_ __ ___  _   _| | __ _| |_(_) ___  _ __
; | |\/| | | | \___ \  |  _| | '_ ` _ \| | | | |/ _` | __| |/ _ \| '_ \
; | |  | | |_| |___) | | |___| | | | | | |_| | | (_| | |_| | (_) | | | |
; |_|  |_|\___/|____/  |_____|_| |_| |_|\__,_|_|\__,_|\__|_|\___/|_| |_|
;
; An Extended Acorn MOS Emulation
;-------------------------------------------------------------------------------
; Copyright (C)2013-2015 HandCoded Software Ltd.
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
;
;===============================================================================
; Revision History:
;
; 2013-04-11 AJ Initial version
;-------------------------------------------------------------------------------
; $Id: mos.asm 48 2015-07-12 22:50:54Z andrew $
;-------------------------------------------------------------------------------

		.include "../em-6502.inc"

;===============================================================================
; Target Environment
;-------------------------------------------------------------------------------

		.6502

N		.EQU	7
V		.EQU	6
B		.EQU	4
D		.EQU	3
I		.EQU	2
Z		.EQU	1
C		.EQU	0

;===============================================================================
; ASCII Control Characters
;-------------------------------------------------------------------------------

NUL		.EQU	$00
BEL		.EQU	$07
BS		.EQU	$08
HT		.EQU 	$09
CR		.EQU	$0D
LF		.EQU	$0A
ESC		.EQU	$1B
DEL		.EQU	$7F

BUF_KBD		.EQU	0
BUF_UTX		.EQU	1
BUF_URX		.EQU	2
BUF_PRN		.EQU	3
BUF_SN0		.EQU	4
BUF_SN1		.EQU	5
BUF_SN2		.EQU	6
BUF_SN3		.EQU	7
BUF_SPH		.EQU	8

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

; 00-8F Language
; 90-9F Econet
; A0-A7 NMI Owner
; A8-AF OS
; B0-BF Filing System Scratch
; C0-CF Filing System
; D0-DF Video

BUF_PTR		.EQU	$E8		; OSWORD 0 Buffer pointer

OS_A		.EQU	$EF
OS_X		.EQU	$F0
OS_Y		.EQU	$F1
ROM_NUM		.EQU	$F4

OS_WS		.EQU	$FA		; General purpose workspace ($FA/$FB)
IRQ_TMP		.EQU	$FC
OS_PTR		.EQU	$FD		; General purpose pointer ($FD/$FE)
ESCFLG		.EQU	$FF

;-------------------------------------------------------------------------------

STACK		.EQU	$0100

;-------------------------------------------------------------------------------

; Vector table

USERV		.EQU	$0200
BRKV		.EQU	$0202
IRQV1		.EQU	$0204
IRQV2		.EQU	$0206
CLIV		.EQU	$0208
BYTEV		.EQU	$020A
WORDV		.EQU	$020C
WRCHV		.EQU	$020E
RDCHV		.EQU	$0210
FILEV		.EQU	$0212
ARGSV		.EQU	$0214
BGETV		.EQU	$0216
BPUTV		.EQU	$0218
GBPBV		.EQU	$021A
FINDV		.EQU	$021C
FSCV		.EQU	$021E
EVNTV		.EQU	$0220
UPTV		.EQU	$0222
NETV		.EQU	$0224
VDUV		.EQU	$0226
KEYV		.EQU	$0228
INSV		.EQU	$022A
REMV		.EQU	$022C
CNPV		.EQU	$022E
IND1V		.EQU	$0230
IND2V		.EQU	$0232
IND3V		.EQU	$0234

OS_VARS		.EQU	$0236		; Start of OS variables

OSHWM_P		.EQU	$0243		; Primary OSHWM
OSHWM		.EQU	$0244		; Current OSHWM (PAGE)
BASIC_ROM	.EQU	$024B		; ROM number containing BASIC

CLKIDX		.EQU	$0283		; Clock offset (5 or 10)
ROM		.EQU	$028C		; Current ROM number
TIME 		.EQU	$0292		; Time (A + B)

ROM_TYPE	.EQU	$02A1		; ROM type byte
INKEY_CNT	.EQU	$02B1		; 16-bit INKEY count
MAX_LEN		.EQU	$02B3		; Maximum line length
MIN_CHR		.EQU	$02B4		; Minimum acceptable ASCII character
MAX_CHR		.EQU	$02B5		; Maximum acceptable ASCII character

BUF_HD		.EQU	$02D8		; Buffer head indexes
BUF_TL		.EQU	$02E1		; Buffer tail indexes

FILE_BLK	.EQU	$02EE

;-------------------------------------------------------------------------------

; 300-37F VDU
; 400-7FF Language Workspace
; 800-8FF Buffers
; 900-9FF Envelopes
; A00-AFF Cassette buffer
; B00-BFF Soft Key Buffer
; C00-CFF Font

;-------------------------------------------------------------------------------

NMI		.EQU	$0D00		; Fixed NMI handler location

;===============================================================================
; ROM Image
;-------------------------------------------------------------------------------

		.CODE
		.ORG	$C000

;-------------------------------------------------------------------------------
; Reset Handler

RES:
		LDA	#$40		; Set NMI first instruction to RTI
		STA	NMI

		SEI
		CLD
		LDX	#$FF		; Reset the system stack
		TXS

		INX
		TXA
		REPEAT			; Clear operating system memory area
		 STA	$0000,X
		 STA	$0100,X
		 STA	$0200,X
		 STA	$0300,X
		 STA	$0400,X
		 STA	$0500,X
		 STA	$0600,X
		 STA	$0700,X
		 STA	$0800,X
		 STA	$0900,X
		 STA	$0A00,X
		 STA	$0B00,X
		 STA	$0C00,X
		 CPX	#0
		 IF 	NE
		  STA	$0D00,X
		 ENDIF
		 INX
		UNTIL	EQ

		LDX	#53		; Initialise default vectors
		REPEAT
		 LDA	VECTORS,X
		 STA	USERV,X
		 DEX
		UNTIL	MI

		LDX	#8		; Clear all buffers
		REPEAT
		 LDA	BUF_IX,X
		 STA	BUF_HD,X
		 STA	BUF_TL,X
		 DEX
		UNTIL	MI

		LDX	#9		; Reset clock values
		LDA	#0
		REPEAT
		 STA	TIME,X
		 DEX
		UNTIL	MI

		LDA	#5		; And set current index
		STA	CLKIDX

		LDA	#INT_100HZ|INT_UART_RX
		IO_IEW			; Enable hardware interrupts
		CLI

		LDA	#$0E		; Reset OSHWM
		STA	OSHWM_P
		STA	OSHWM

;-------------------------------------------------------------------------------

		JSR	OSNEWL

		LDX	#0		; Print ROM Title
		REPEAT
		 LDA	OS_TITLE,X
		 BREAK	EQ
		 JSR	OSASCI
		 INX
		FOREVER

		JSR	OSNEWL
		JSR	OSNEWL

		LDX	#15		; Scan all the ROMS
		REPEAT
		 TXA
		 IO_BNK
		 LDA	$8006		; And save their type bytes
		 STA	ROM_TYPE,X
		 IF 	NE
		  IF 	PL
		   STA	BASIC_ROM
		  ENDIF
		 ENDIF
		 DEX
		UNTIL	MI

;-------------------------------------------------------------------------------

		LDX	BASIC_ROM	; Start the language ROM
		SEC
		JMP	BYTE_8E

		BRK	#$F9
		.BYTE	"Language?",0

;-------------------------------------------------------------------------------

OS_TITLE:
		.BYTE	"Virtual BBC Microcomputer 32K",0

VECTORS:	.WORD	_USER
		.WORD	_BRK
		.WORD	_IRQ1
		.WORD	_IRQ2
		.WORD	_CLI
		.WORD	_BYTE
		.WORD	_WORD
		.WORD	_WRCH
		.WORD	_RDCH
		.WORD	_FILE
		.WORD	_ARGS
		.WORD	_BGET
		.WORD	_BPUT
		.WORD	_GBPB
		.WORD	_FIND
		.WORD	_FSC
		.WORD	_EVNT
		.WORD	_UPT
		.WORD	_NET
		.WORD	_VDU
		.WORD	_KEY
		.WORD	_INS
		.WORD	_REM
		.WORD	_CNP
		.WORD	_IND1
		.WORD	_IND2
		.WORD	_IND3

;===============================================================================
; Utility Functions
;-------------------------------------------------------------------------------

CALL_WS:
		JMP	(OS_WS)

; Useful bytes for setting the N & V flags with a BIT

SET_N:		.BYTE 	$80
SET_V:		.BYTE	$40
SET_NV:		.BYTE	$C0

;===============================================================================
; Default User Vector Handler
;-------------------------------------------------------------------------------

_USER:
		RTS			; Do nothing by default

;===============================================================================
; Default OSCLI Vector Handler
;-------------------------------------------------------------------------------

_CLI:
		RTS

;-------------------------------------------------------------------------------

		.BYTE	"BASIC"
		.BYTE	"FX"
		.BYTE	"LOAD"
		.BYTE	"SAVE"
		.BYTE	"DUMP"

;===============================================================================
; Default OSBYTE Handler
;-------------------------------------------------------------------------------

_BYTE:
		PHA
		PHP
		SEI
		STA	OS_A
		STX	OS_X
		STY	OS_Y

		CMP	#$16
		IF	CC		; OSBYTE $00-$15
		 TAY
		 LDA	ByteLo1-$00,Y
		 STA	OS_WS+0
		 LDA	ByteHi1-$00,Y
		 STA	OS_WS+1
		 LDA	OS_A
		 LDY	OS_Y
		 JSR	CALL_WS
		 ROR	A
		 PLP
		 ROL	A
		 PLA
		 RTS
		ENDIF

		CMP	#$75
		IF	CS		; OSBYTE $75-$A0
		 CMP	#$A1
		 IF	CC
		  TAY
		  LDA	ByteLo2-$75,Y
		  STA	OS_WS+0
		  LDA	ByteHi2-$75,Y
		  STA	OS_WS+1
		  LDA	OS_A
		  LDY	OS_Y
		  JSR	CALL_WS
		  ROR	A
		  PLP
		  ROL	A
		  PLA
		  RTS
		 ENDIF
		ENDIF

		CMP	#$A6		; OSBYTE $A6-$FF
		IF	CS
		 TAX
		 LDA	OS_VARS-$A6+0,X
		 LDY	OS_VARS-$A6+1,X
		 PHA
		 AND	OS_Y
		 EOR	OS_X
		 STA	OS_VARS-$A6,X
		 PLA
		 TAX
		 PLP
		 PLA
		 RTS
		ENDIF

		PLP
		PLA
		RTS

;-------------------------------------------------------------------------------

ByteLo1:
		.BYTE	LO BYTE_00,LO BYTE_01,LO BYTE_02,LO BYTE_03
		.BYTE	LO BYTE_04,LO BYTE_05,LO BYTE_06,LO BYTE_07
		.BYTE	LO BYTE_08,LO BYTE_09,LO BYTE_0A,LO BYTE_0B
		.BYTE	LO BYTE_0C,LO BYTE_0D,LO BYTE_0E,LO BYTE_0F
		.BYTE	LO BYTE_10,LO BYTE_11,LO BYTE_12,LO BYTE_13
		.BYTE	LO BYTE_14,LO BYTE_15

ByteHi1:
		.BYTE	HI BYTE_00,HI BYTE_01,HI BYTE_02,HI BYTE_03
		.BYTE	HI BYTE_04,HI BYTE_05,HI BYTE_06,HI BYTE_07
		.BYTE	HI BYTE_08,HI BYTE_09,HI BYTE_0A,HI BYTE_0B
		.BYTE	HI BYTE_0C,HI BYTE_0D,HI BYTE_0E,HI BYTE_0F
		.BYTE	HI BYTE_10,HI BYTE_11,HI BYTE_12,HI BYTE_13
		.BYTE	HI BYTE_14,HI BYTE_15

ByteLo2:
		.BYTE	           LO BYTE_75,LO BYTE_76,LO BYTE_77
		.BYTE	LO BYTE_78,LO BYTE_79,LO BYTE_7A,LO BYTE_7B
		.BYTE	LO BYTE_7C,LO BYTE_7D,LO BYTE_7E,LO BYTE_7F
		.BYTE	LO BYTE_80,LO BYTE_81,LO BYTE_82,LO BYTE_83
		.BYTE	LO BYTE_84,LO BYTE_85,LO BYTE_86,LO BYTE_87
		.BYTE	LO BYTE_88,LO BYTE_89,LO BYTE_8A,LO BYTE_8B
		.BYTE	LO BYTE_8C,LO BYTE_8D,LO BYTE_8E,LO BYTE_8F
		.BYTE	LO BYTE_90,LO BYTE_91,LO BYTE_92,LO BYTE_93
		.BYTE	LO BYTE_94,LO BYTE_95,LO BYTE_96,LO BYTE_97
		.BYTE	LO BYTE_98,LO BYTE_99,LO BYTE_9A,LO BYTE_9B
		.BYTE	LO BYTE_9C,LO BYTE_9D,LO BYTE_9E,LO BYTE_9F
		.BYTE	LO BYTE_A0

ByteHi2:
		.BYTE	           HI BYTE_75,HI BYTE_76,HI BYTE_77
		.BYTE	HI BYTE_78,HI BYTE_79,HI BYTE_7A,HI BYTE_7B
		.BYTE	HI BYTE_7C,HI BYTE_7D,HI BYTE_7E,HI BYTE_7F
		.BYTE	HI BYTE_80,HI BYTE_81,HI BYTE_82,HI BYTE_83
		.BYTE	HI BYTE_84,HI BYTE_85,HI BYTE_86,HI BYTE_87
		.BYTE	HI BYTE_88,HI BYTE_89,HI BYTE_8A,HI BYTE_8B
		.BYTE	HI BYTE_8C,HI BYTE_8D,HI BYTE_8E,HI BYTE_8F
		.BYTE	HI BYTE_90,HI BYTE_91,HI BYTE_92,HI BYTE_93
		.BYTE	HI BYTE_94,HI BYTE_95,HI BYTE_96,HI BYTE_97
		.BYTE	HI BYTE_98,HI BYTE_99,HI BYTE_9A,HI BYTE_9B
		.BYTE	HI BYTE_9C,HI BYTE_9D,HI BYTE_9E,HI BYTE_9F
		.BYTE	HI BYTE_A0

;-------------------------------------------------------------------------------
; $00 (0) Identity Operating System Version

BYTE_00:
		CPX	#$00
		IF	EQ
		 BRK	#$F7
		 .BYTE	"OS 1.20",0
		ENDIF
		LDX	#1
		RTS

BYTE_01:
BYTE_02:
BYTE_03:
BYTE_04:
BYTE_05:
BYTE_06:
BYTE_07:
BYTE_08:
BYTE_09:
BYTE_0A:
BYTE_0B:
BYTE_0C:
BYTE_0D:
BYTE_0E:
BYTE_0F:
BYTE_10:
BYTE_11:
BYTE_12:
BYTE_13:
BYTE_14:
BYTE_15:

BYTE_75:
BYTE_76:
BYTE_77:
BYTE_78:
BYTE_79:
BYTE_7A:
BYTE_7B:

;-------------------------------------------------------------------------------
; $7C (124) Clear ESCAPE Condition

BYTE_7C:
		LDA	$FF
		AND	#$7F
		STA	$FF
		RTS

BYTE_7D:
BYTE_7E:

;-------------------------------------------------------------------------------

BYTE_7F:
BYTE_80:

;-------------------------------------------------------------------------------
BYTE_81:
		RTS

;-------------------------------------------------------------------------------
; $82 (130) Read Machine High Order Address

BYTE_82:
		LDX	#$FF		; I/O Processor is $FFFF
		LDY	#$FF
		RTS

;-------------------------------------------------------------------------------
; $83 (131) Read Top of Operating System RAM Address (OWHWM)

BYTE_83:
		LDX	#$00
		LDY	OSHWM
		RTS

;-------------------------------------------------------------------------------
; $84 (132) Read Bottom of Display RAM address (HIMEM)
; $85 (133) Read Bottom of Display RAM for Specific Mode

BYTE_84:
BYTE_85:
		LDX	#$00		; Fetch from host device
		LDY	#$80
		RTS

;-------------------------------------------------------------------------------
; $86 (134) Read Text Cursor Position (POS and VPOS)

BYTE_86:
		LDX	#0		; Not implemented
		LDY	#0
		RTS

;-------------------------------------------------------------------------------
; $87 (135) Read Character at Text Cursor Position

BYTE_87:
		LDX	#0		; Not implemented
		LDY	#0
		RTS

BYTE_88:
BYTE_89:

;-------------------------------------------------------------------------------
; $8A (138) Put byte into Buffer

BYTE_8A:
		TYA
OS_INS:		JMP	(INSV)

;-------------------------------------------------------------------------------
BYTE_8B:
BYTE_8C:
BYTE_8D:
		RTS

;-------------------------------------------------------------------------------
; $8E (142) Enter Language ROM

BYTE_8E:
		PHP
		STX	ROM		; Select the ROM
		TXA
		STA	ROM_NUM
		IO_BNK
		LDY	#0
		REPEAT
		 LDA	$8009,Y
		 BREAK	EQ
		 JSR	OSASCI
		 INY
		FOREVER
		JSR	OSNEWL
		JSR	OSNEWL
		PLP
		LDA	#1
		JMP	$8000

BYTE_8F:
BYTE_90:

;------------------------------------------------------------------------------
; $91 (145) Get Bytes from Buffer

BYTE_91:
		CLV
		JMP	(REMV)

;------------------------------------------------------------------------------
; $92 (146) Read a Byte from FRED area (Not implemented)

BYTE_92:
		LDY	#0
		RTS

;------------------------------------------------------------------------------
BYTE_93:

;------------------------------------------------------------------------------
; $94 (148) Read a Byte from JIM area (Not implemented)

BYTE_94:
		LDY	#0
		RTS

;------------------------------------------------------------------------------
BYTE_95:

;------------------------------------------------------------------------------
; $96 (150) Read a Byte from SHEILA area (Not implemented)

BYTE_96:
		LDY	#0
		RTS

;------------------------------------------------------------------------------
BYTE_97:

;-------------------------------------------------------------------------------
; $98 (152) Examine Buffer Status

BYTE_98:
		BIT	SET_V
OS_REM:		JMP	(REMV)

BYTE_99:
BYTE_9A:
BYTE_9B:
BYTE_9C:

;------------------------------------------------------------------------------
; $9D (157) Fast BPUT

BYTE_9D:
		TXA
		JMP	OSBPUT

; $9E (158)
BYTE_9E:
; $9F (159)
BYTE_9F:
; $A0 (160)
BYTE_A0:
		RTS

;===============================================================================
; OSWORD Emulation
;-------------------------------------------------------------------------------

_WORD:
		PHA
		PHP
		STA	OS_A
		STX	OS_X
		STY	OS_Y

		CMP	#$0E
		IF	CC
		 TAY
		 LDA	WordLo,Y
		 STA	OS_WS+0
		 LDA	WordHi,Y
		 STA	OS_WS+1
		 LDA	OS_A
		 LDY	OS_Y
		 JSR	CALL_WS
		ENDIF

		ROR	A
		PLP
		ROL	A
		PLA
		RTS

;-------------------------------------------------------------------------------

WordLo:
		.BYTE	LO WORD_00,LO WORD_01,LO WORD_02,LO WORD_03
		.BYTE	LO WORD_04,LO WORD_05,LO WORD_06,LO WORD_07
		.BYTE	LO WORD_08,LO WORD_09,LO WORD_0A,LO WORD_0B
		.BYTE	LO WORD_0C,LO WORD_0D

WordHi:
		.BYTE	HI WORD_00,HI WORD_01,HI WORD_02,HI WORD_03
		.BYTE	HI WORD_04,HI WORD_05,HI WORD_06,HI WORD_07
		.BYTE	HI WORD_08,HI WORD_09,HI WORD_0A,HI WORD_0B
		.BYTE	HI WORD_0C,HI WORD_0D

;-------------------------------------------------------------------------------
; $00 (0) Read Line

WORD_00:
		LDY	#4		; Copy parameters to OS_VARS
		REPEAT
		 LDA	(OS_X),Y
		 STA	MAX_LEN-2,Y
		 DEY
		 CPY	#1
		UNTIL	EQ

		LDA	(OS_X),Y	; And setup buffer pointer
		STA	BUF_PTR+1
		DEY
		LDA	(OS_X),Y
		STA	BUF_PTR+0

		REPEAT
		 JSR	OSRDCH

		 CMP	#DEL		; Handle delete
		 IF	EQ
		  CPY	#0
		  IF	NE
		   JSR	OSWRCH
		   DEY
		  ENDIF
		  CONTINUE
		 ENDIF

		 CMP	#CR		; End of input?
		 IF	EQ
		  STA	(BUF_PTR),Y	; Yes, mark the end
		  INY
		  JSR	OSASCI
		  CLC
		  RTS
		 ENDIF

		 CMP	#ESC		; Escape?
		 IF	EQ
		   SEC
		   RTS
		 ENDIF

		 CMP	MIN_CHR		; Acceptable character?
		 IF	CS
		  CMP	MAX_CHR
		  IF	CS
		   IF	NE
		    CONTINUE		; Too big?
		   ENDIF
		  ENDIF

		  CPY	MAX_LEN		; Fits in the buffer?
		  IF	CC
		   STA	(BUF_PTR),Y	; Just right, save it
		   INY
		   JSR	OSWRCH		; And display
		   CONTINUE
		  ENDIF
		 ENDIF

		 LDA	#BEL
		 JSR	OSWRCH
		FOREVER

;-------------------------------------------------------------------------------
; $01 (1) Read System Clock

WORD_01:
		LDX	CLKIDX		; Get current timer index
		LDY	#0
		REPEAT			; And copy the current value
		 LDA	TIME-1,X
		 STA	(OS_X),Y
		 DEX
		 INY
		 CPY	#5
		UNTIL	EQ
		RTS			; Done

;-------------------------------------------------------------------------------
; $02 (2) Write System Clock

WORD_02:
		LDA	CLKIDX		; Get the current timer index
		PHA
		TAX
		LDY	#0		; And install the new value
		REPEAT
		 LDA	(OS_X),Y
		 STA	TIME-1,X
		 DEX
		 INY
		 CPY	#5
		UNTIL	EQ
		PLA			; Ensure value used on next update
		STA	CLKIDX
		RTS			; Done

;-------------------------------------------------------------------------------

WORD_03:
WORD_04:
WORD_05:
WORD_06:
WORD_07:
WORD_08:
WORD_09:
WORD_0A:
WORD_0B:
WORD_0C:
WORD_0D:
		RTS

;===============================================================================
; Write character
;-------------------------------------------------------------------------------

_WRCH:
		; Handle I/O redirect

;-------------------------------------------------------------------------------

		CMP	#NUL		; Ignore NUL characters
		IF	EQ
		 RTS
		ENDIF

		CMP	#DEL		; Translate DEL into BS ' ' BS
		IF	EQ
		 PHA
		 LDA	#BS
		 PHA
		 JSR	_WRCH
		 LDA	#' '
		 JSR	_WRCH
		 PLA
		 JSR	_WRCH
		 PLA
		 RTS
		ENDIF

		PHA
		PHA
		REPEAT
		 IO_IFR			; Is UART ready to transmit
		 AND	#INT_UART_TX
		UNTIL NE
		PLA			; Yes, display the character
		IO_TXD
		PLA
		RTS			; Done.

;===============================================================================
; Read Character
;-------------------------------------------------------------------------------

_RDCH:
		PHA
		TXA
		PHA
		TYA
		PHA

		LDX	#BUF_KBD
		REPEAT
		 CLV
		 JSR	OS_REM
		 BREAK	CC
		FOREVER

		TSX
		STA	STACK+3,X
		PLA
		TAY
		PLA
		TAX
		PLA
		RTS

;===============================================================================
; Filing System Emulation
;-------------------------------------------------------------------------------

_FILE
		RTS

_ARGS
		RTS

_BGET
		RTS

_BPUT
		RTS

_GBPB
		RTS

_FIND
		RTS

_FSC
		RTS

;===============================================================================
; Event Handler
;-------------------------------------------------------------------------------

; Generate an event

EVENT:

; MOS generates events but does not actually make any use of them. The default
; handler is just an RTS.

_EVNT:
		RTS			; Done

; There isn't a standard entry point to generate an event so we will define one
; here.

OSEVNT:
		JMP	(EVNTV)		; Indirect thru the vector

;===============================================================================
;-------------------------------------------------------------------------------

_UPT:
		RTS

_NET:
		RTS

;===============================================================================
;-------------------------------------------------------------------------------

_VDU:
		RTS

_KEY:
		RTS

;===============================================================================
; Buffer Routines
;-------------------------------------------------------------------------------

; The following tables hold base addresses and indexes for the various buffer
; address. The head and tail pointer are incremented from teh IX value until it
; reaches zero.

BUF_HI:		.BYTE	$03,$0A,$08,$07,$07,$07,$07,$07,$09
BUF_LO:		.BYTE	$00,$00,$C0,$C0,$50,$60,$70,$80,$00
BUF_IX:		.BYTE	$E0,$00,$40,$C0,$F0,$F0,$F0,$F0,$C0

;------------------------------------------------------------------------------

SET_BUF_PTR:
		LDA	BUF_LO,X	; Fetch buffer base address
		STA	OS_WS+0		; And set OS_WS pointer
		LDA	BUF_HI,X
		STA	OS_WS+1
		RTS

;------------------------------------------------------------------------------
; Insert into buffer

_INS:
		PHP			; Save flags
		SEI
		PHA			; Save A
		LDY	BUF_TL,X	; Get buffer tail
		INY			; And bump
		IF	EQ
		 LDY	BUF_IX,X
		ENDIF
		TYA
		CMP	BUF_HD,X	; Is the buffer full?
		IF	NE
		 LDY	BUF_TL,X	; No, set up for insert
		 STA	BUF_TL,X
		 JSR	SET_BUF_PTR	
		 PLA			; Store A
		 STA	(OS_WS),Y
		 PLP
		 CLC			; Done success
		 RTS
		ENDIF
		PLA
		CPX	#BUF_URX
		IF	CC
		 LDY	#1		; Generate an event
		 JSR	EVENT
		 PHA
		ENDIF
		PLA			; Restore A
		PLP			; Restore flags
		SEC			; Set carry
		RTS			; Done

;------------------------------------------------------------------------------
; Peek/Remove from buffer

_REM:
		PHP
		SEI
		LDA	BUF_HD,X	; Get the head index
		CMP	BUF_TL,X	; And compare with the tail
		IF	NE
		 TAY			; Buffer not empty
		 JSR	SET_BUF_PTR	; Get pointer to buffer
		 LDA	(OS_WS),Y	; And extract a character
		 IF	VC
		  PHA			; Otherwise save character
		  INY			; Bump index
		  TYA
		  IF	EQ		; Reached end of buffer?
		   LDA	BUF_IX,X	; Yes, wrap back to start
		  ENDIF
		  STA	BUF_HD,X	; Update head index
		  CPX	#2
		  IF	CS
		   CMP	BUF_TL,X	; Buffer empty?
		   IF	EQ
		    LDY	#0		; Generate buffer empty event
		    JSR	EVENT
		   ENDIF
		  ENDIF
		  PLA			; Pull back character
		  TAY			; And put in result register
		 ENDIF
		 PLP			; Restore flags
		 CLC			; Buffer was not empty
		 RTS			; Done.
		ENDIF
		PLP			; Restore flags
		SEC			; Buffer was empty
		RTS			; Done.

;------------------------------------------------------------------------------
; Count/Purge Buffer

_CNP:
		IF	VS		; Purge selected?
		 LDA	BUF_TL,X	; Yes, copy tail to head
		 STA	BUF_HD,X
		 RTS			; Done
		ENDIF

		PHP			; Save flags
		SEI			; Disable interrupts
		PHP			; Push flags again
		SEC
		LDA	BUF_TL,X	; Work out tail-head
		SBC	BUF_HD,X
		IF	CC
		 SEC
		 SBC	BUF_IX,X
		ENDIF
		PLP			; Pull back flags
		IF	CS		; Bytes used or left?
		 CLC			; Work out bytes used
		 ADC	BUF_LO,X
		 EOR	#$FF
		ENDIF
		LDY	#0
		TAX			; Put result in X
		PLP			; Recover flags
		RTS			; Done

;===============================================================================
;-------------------------------------------------------------------------------

_IND1
		RTS

_IND2
		RTS

_IND3
		RTS

;===============================================================================
; Interrupt Request Handler
;-------------------------------------------------------------------------------

IRQ:
		CLD
		STA	IRQ_TMP		; Save the accumulator
		PLA			; And recover the flags
		PHA
		AND	#1<<B		; Hardware interrupt?
		IF	EQ
		 JMP	(IRQV1)		; And go to handler
		ENDIF

		TXA
		PHA			; No software interrupt
		TSX
		LDA	STACK+3,X	; Work out program counter
		SEC
		SBC	#1
		STA	OS_PTR+0
		LDA	STACK+4,X
		SBC	#0
		STA	OS_PTR+1

		PLA
		TAX
		LDA	IRQ_TMP
		JMP	(BRKV)

;===============================================================================
; Default IRQ Handler
;-------------------------------------------------------------------------------

_IRQ1:
		TXA			; Save users X and Y
		PHA
		TYA
		PHA

;------------------------------------------------------------------------------

		IO_IFR			; Get the interrupt source
		AND	#INT_100HZ	; Is it a Timer?
		IF	NE
		 IO_IFC			; Yes, clear flag

		 LDA	CLKIDX		; Get current index
		 TAX
		 EOR	#$0F		; Work out index for new value
		 PHA
		 TAY

		 SEC			; Increment old into new time
		 REPEAT
		  LDA	TIME-1,X
		  ADC	#0
		  STA	TIME-1,Y
		  DEX
		  BREAK EQ
		  DEY
		 UNTIL EQ

		 PLA			; And update index
		 STA	CLKIDX

		 LDA	INKEY_CNT+0	; Is INKEY count LSB zero?
		 IF 	EQ
		  LDA	INKEY_CNT+1	; Is the MSB also zero?
		  BEQ	.Skip		; Yes, nothing to do
		  DEC	INKEY_CNT+1	; No, decrement MSB
		 ENDIF
		 DEC	INKEY_CNT+0	; Decrement LSB
.Skip:

		 ; Decrement other timers

		ENDIF

;------------------------------------------------------------------------------

		IO_IFR
		AND	#INT_UART_RX	; Is it a UART RX?
		IF	NE
		 IO_RXD			; Yes, read the keyboard
		 LDX	#BUF_KBD	; And insert into buffer
		 JSR	OS_INS
		ENDIF

;------------------------------------------------------------------------------

		PLA			; Restore users X & Y
		TAY
		PLA
		TAX

		JMP	(IRQV2)		; Indirect thru second vector

_IRQ2:
		LDA	IRQ_TMP		; Restore the accumulator
		RTI			; All done.

;===============================================================================
; Default BRK Handler
;-------------------------------------------------------------------------------

_BRK:
		LDY	#0		; Print the error message
		REPEAT
		 LDA	(OS_PTR),Y
		 BREAK	EQ
		 JSR	OSASCI
		 INY
		FOREVER
		JSR	OSNEWL		; And a couple of blank lines
		JSR	OSNEWL

		CLC			; Then re-enter the language
		JMP	BYTE_8E

;===============================================================================
; Vectors
;-------------------------------------------------------------------------------

		.ORG	$FFC8

NVRDCH:		JMP	_RDCH		; $FFC8
NVWRCH:		JMP	_WRCH		; $FFCB

OSFIND:		JMP	(FINDV)		; $FFCE
OSGBPB:		JMP	(GBPBV)		; $FFD1
OSBPUT:		JMP	(BPUTV)		; $FFD4
OSBGET:		JMP	(BGETV)		; $FFD7
OSARGS:		JMP	(ARGSV)		; $FFDA
OSFILE		JMP	(FILEV)		; $FFDD

OSRDCH:		JMP	(RDCHV)		; $FFE0

OSASCI:		CMP	#CR		; $FFE3
		BNE	OSWRCH
OSNEWL:		LDA	#LF		; $FFE7
		JSR	OSWRCH
		LDA	#CR
OSWRCH:		JMP	(WRCHV)		; $FFEE
OSWORD:		JMP	(WORDV)		; $FFF1
OSBYTE:		JMP	(BYTEV)		; $FFF4
OSCLI:		JMP	(CLIV)		; $FFF7


		.WORD	NMI
		.WORD	RES
		.WORD	IRQ

		.END