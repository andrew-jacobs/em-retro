;===============================================================================
;     _	   _   _ ____  _____	      _	  _	  ____	 ____	 ____  __ ____
;    / \  | \ | / ___||	 ___|__	 _ __| |_| |__	 / ___| / ___|	/ /  \/	 |  _ \
;   / _ \ |  \| \___ \| |_ / _ \| '__| __| '_ \	 \___ \| |     / /| |\/| | |_) |
;  / ___ \| |\	|___) |	 _| (_) | |  | |_| | | |  ___) | |___ / / | |  | |  __/
; /_/	\_\_| \_|____/|_|  \___/|_|   \__|_| |_| |____/ \____/_/  |_|  |_|_|
;
; An Indirect Threaded ANS Forth for the SC/MP
;-------------------------------------------------------------------------------
; Copyright (C)2016 HandCoded Software Ltd.
; All rights reserved.
;
; This work is made available under the terms of the Creative Commons
; Attribution-NonCommercial-ShareAlike 4.0 International license. Open the
; following URL to see the details.
;
; http://creativecommons.org/licenses/by-nc-sa/4.0/
;
;===============================================================================
; Notes:
;
; Of the three general purpose registers is used to hold the base address of the
; system memory area which holds the Forth instructon pointer as well as the
; current data and return stack pointers.
;
; Only the low byte of the data and return stack pointers is ever adjusted by a
; stack operation limiting thier size to 256 bytes and they can not cross a 256
; byte page boundary.
;
; R2(P3) contains the address of NEXT to allow native words to continue quickly
;
; Some of the high-level definitions are based on Bradford J. Rodriguez's
; CamelForth implementations.
;
; Thoughts:
;
; Aligning word addresses on even bytes would speed up the IP += 2 in the inner
; interpreter.
;
;-------------------------------------------------------------------------------

		.INCLUDE "../em-scmp.inc"
; Register assigments

PC		.EQU	0		; SC/MP program counter (pre-incremented)
MA		.EQU	1		; System memory base address
R1		.EQU	2		; General purpose
R2		.EQU	3		; Next address / General purpose

;===============================================================================
;-------------------------------------------------------------------------------

LAST		.SET	0

NORMAL		.EQU	X'00
IMMEDIATE	.EQU	X'80

WORD		.MACRO	NAME,TYPE
THIS		.SET	$
		.WORD	LAST
		.BYTE	TYPE
		.BYTE	STRLEN(NAME)
		.BYTE	NAME
LAST		.SET	THIS
		.ENDM

NATIVE		.MACRO
		.WORD	$+1
		.ENDM

FORTH		.MACRO
		.WORD	DO_COLON-1
		.ENDM

;===============================================================================
;-------------------------------------------------------------------------------

		.BSS
		.ORG	X'1000

TIB_SIZE	.EQU	128

DSTACK		.SPACE	128
DSTACK_END	.SPACE	0
TIB_AREA	.SPACE	TIB_SIZE
RSTACK		.SPACE	128
RSTACK_END	.SPACE	0
PAD_AREA	.SPACE	40
PAD_END		.SPACE	0

SYS_VARS	.SPACE	10

IP		.EQU	0
WA		.EQU	2
RP		.EQU	4
SP		.EQU	6
UP		.EQU	8

USR_VARS	.SPACE	22

TO_IN_OFFSET	.EQU	0
BASE_OFFSET	.EQU	2
BLK_OFFSET	.EQU	4
DP_OFFSET	.EQU	6
LATEST_OFFSET	.EQU	8
SCR_OFFSET	.EQU	10
SOURCEID_OFFSET .EQU	12			; Input source flag
STATE_OFFSET	.EQU	14			; Compiling/Interpreting flag
BUFFER_OFFSET	.EQU	16			; Address of the input buffer
LENGTH_OFFSET	.EQU	18			; Length of the input buffer
HP_OFFSET	.EQU	20

NEXT_WORD	.SPACE	0

;===============================================================================
; Power On Reset
;-------------------------------------------------------------------------------

		.CODE
		.ORG	X'C000

		NOP
		LDI	LO(SYS_VARS)	; Initialise pointer to system variables
		XPAL	MA
		LDI	HI(SYS_VARS)
		XPAH	MA

		LDI	LO(DSTACK_END)	; Initialise the data stack
		ST	SP+0(MA)
		LDI	HI(DSTACK_END)
		ST	SP+1(MA)

		LDI	LO(RSTACK_END)	; Initialise the return stack
		ST	RP+0(MA)
		LDI	HI(RSTACK_END)
		ST	RP+1(MA)

		LDI	LO(USR_VARS)	; Initialise the USER pointer
		ST	UP+0(MA)
		LDI	HI(USR_VARS)
		ST	UP+1(MA)

		LDI	LO(COLD)	; Initialise the IP
		ST	IP+0(MA)
		LDI	HI(COLD)
		ST	IP+1(MA)

		LDI	LO(NEXT-1)	; Initialise pointer to NEXT
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAH	R2
		XPPC	R2		; And start COLD execution

COLD:		.WORD	DECIMAL
		.WORD	ZERO
		.WORD	BLK
		.WORD	STORE
		.WORD	FALSE
		.WORD	STATE
		.WORD	STORE
		.WORD	DO_LITERAL,NEXT_WORD
		.WORD	DP
		.WORD	STORE
		.WORD	DO_LITERAL,LAST_WORD
		.WORD	FETCH
		.WORD	LATEST
		.WORD	STORE
		.WORD	CR
		.WORD	CR
		.WORD	DO_TITLE
		.WORD	TYPE
		.WORD	CR
		.WORD	CR
		.WORD	ABORT

;===============================================================================
; System/User Variables
;-------------------------------------------------------------------------------

; #TIB ( -- a-addr )
;
; a-addr is the address of a cell containing the number of characters in the
; terminal input buffer.

		WORD	"#TIB",NORMAL
HASH_TIB:	.WORD	DO_USER-1
		.WORD	$+2
		.WORD	TIB_SIZE-2

; >IN ( -- a-addr )
;
; a-addr is the address of a cell containing the offset in characters from the
; start of the input buffer to the start of the parse area.

		WORD	">IN",NORMAL
TO_IN:		.WORD	DO_USER-1
		.WORD	TO_IN_OFFSET

; BASE ( -- a-addr )
;
; a-addr is the address of a cell containing the current number-conversion
; radix {{2...36}}.

		WORD	"BASE",NORMAL
BASE:		.WORD	DO_USER-1
		.WORD	BASE_OFFSET

; BLK ( -- a-addr )
;
; a-addr is the address of a cell containing zero or the number of the mass-
; storage block being interpreted. If BLK contains zero, the input source is
; not a block and can be identified by SOURCE-ID, if SOURCE-ID is available. An
; ambiguous condition exists if a program directly alters the contents of BLK.

		WORD	"BLK",NORMAL
BLK:		.WORD	DO_USER-1
		.WORD	BLK_OFFSET

; (BUFFER)

BUFFER:		.WORD	DO_USER-1
		.WORD	BUFFER_OFFSET

; DP ( -- a-addr )
;
; Dictionary Pointer

		WORD	"DP",NORMAL
DP:		.WORD	DO_USER-1
		.WORD	DP_OFFSET

; HP ( -- a-addr )
;
; Hold Pointer

HP:		.WORD	DO_USER-1
		.WORD	HP_OFFSET

; LATEST ( -- a-addr )

		WORD	"LATEST",NORMAL
LATEST:		.WORD	DO_USER-1
		.WORD	LATEST_OFFSET

; (LENGTH)

LENGTH:		.WORD	DO_USER-1
		.WORD	LENGTH_OFFSET

; SCR ( -- a-addr )
;
; a-addr is the address of a cell containing the block number of the block most
; recently LISTed.

		WORD	"SCR",NORMAL
SCR:		.WORD	DO_USER-1
		.WORD	SCR_OFFSET

; (SOURCE-ID)

SOURCEID:	.WORD	DO_USER-1
		.WORD	SOURCEID_OFFSET

; STATE ( -- a-addr )
;
; a-addr is the address of a cell containing the compilation-state flag. STATE
; is true when in compilation state, false otherwise. The true value in STATE
; is non-zero, but is otherwise implementation-defined.

		WORD	"STATE",NORMAL
STATE:		.WORD	DO_USER-1
		.WORD	STATE_OFFSET

; TIB ( -- c-addr )
;
; c-addr is the address of the terminal input buffer.

		WORD	"TIB",NORMAL
TIB:		.WORD	DO_CONSTANT-1
		.WORD	TIB_AREA

;===============================================================================
; Constants
;-------------------------------------------------------------------------------

; 0 ( -- 0 )
;
; Push the constant value zero on the stack

		WORD	"0",NORMAL
ZERO:		.WORD	DO_CONSTANT-1
		.WORD	0

; BL ( -- char )
;
; char is the character value for a space.

		WORD	"BL",NORMAL
BL:		.WORD	DO_CONSTANT
		.WORD	' '

; FALSE ( -- false )
;
; Return a false flag.

		WORD	"FALSE",NORMAL
FALSE:		.WORD	DO_CONSTANT-1
		.WORD	0

; TRUE ( -- true )
;
; Return a true flag, a single-cell value with all bits set.

		WORD	"TRUE",NORMAL
TRUE:		.WORD	DO_CONSTANT-1
		.WORD	-1

;===============================================================================
; Radix
;-------------------------------------------------------------------------------

; DECIMAL ( -- )
;
; Set the numeric conversion radix to ten (decimal).

		WORD	"DECIMAL",NORMAL
DECIMAL:	FORTH
		.WORD	DO_LITERAL,10
		.WORD	BASE
		.WORD	STORE
		.WORD	EXIT

; HEX ( -- )
;
; Set contents of BASE to sixteen.

		WORD	"HEX",NORMAL
HEX:		FORTH
		.WORD	DO_LITERAL,16
		.WORD	BASE
		.WORD	STORE
		.WORD	EXIT

;===============================================================================
; Memory Operations
;-------------------------------------------------------------------------------

; ! ( x a-addr -- )
;
; Store x at a-addr.

		WORD	"!",NORMAL
STORE:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Fetch the target address
		XPAL	R2
		LD	1(R1)
		XPAH	R2
		LD	2(R1)		; Store the data word
		ST	0(R2)
		LD	3(R1)
		ST	1(R2)
		ILD	SP+0(MA)	; Drop the top two words
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		ILD	SP+0(MA)

		LDI	LO(NEXT-1)	; Restore R2
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAH	R2
		XPPC	R2		; And continue

; +! ( n|u a-addr -- )
;
; Add n|u to the single-cell number at a-addr.

		WORD	"+!",NORMAL
PLUS_STORE:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Fetch the target address
		XPAL	R2
		LD	1(R1)
		XPAH	R2
		CCL
		LD	2(R1)		; Add top word to memory
		ADD	0(R2)
		ST	0(R2)
		LD	3(R1)
		ADD	1(R2)
		ST	1(R2)
		ILD	SP+0(MA)	; Drop the top two words
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		ILD	SP+0(MA)

		LDI	LO(NEXT-1)	; Restore R2
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAH	R2
		XPPC	R2		; And continue

; , ( x -- )
;
; Reserve one cell of data space and store x in the cell. If the data-space
; pointer is aligned when , begins execution, it will remain aligned when ,
; finishes execution. An ambiguous condition exists if the data-space pointer
; is not aligned prior to execution of ,.
;
; In this implementation is its defined as:
;
;   HERE ! 1 CELLS ALLOT

		WORD	",",NORMAL
COMMA:		FORTH
		.WORD	HERE
		.WORD	STORE
		.WORD	DO_LITERAL,1
		.WORD	CELLS
		.WORD	ALLOT
		.WORD	EXIT

; 2! ( x1 x2 a-addr -- )
;
; Store the cell pair x1 x2 at a-addr, with x2 at a-addr and x1 at the next
; consecutive cell.
;
; In this implementation is its defined as:
;
;   SWAP OVER ! CELL+ !.

		WORD	"2!",NORMAL
TWO_STORE:	FORTH
		.WORD	SWAP
		.WORD	OVER
		.WORD	STORE
		.WORD	CELL_PLUS
		.WORD	STORE
		.WORD	EXIT

; 2@ ( a-addr -- x1 x2 )
;
; Fetch the cell pair x1 x2 stored at a-addr. x2 is stored at a-addr and x1 at
; the next consecutive cell.
;
; In this implementation is its defined as:
;
;   DUP CELL+ @ SWAP @

		WORD	"2@",NORMAL
TWO_FETCH:	FORTH
		.WORD	DUP
		.WORD	CELL_PLUS
		.WORD	FETCH
		.WORD	SWAP
		.WORD	FETCH
		.WORD	EXIT

; @ ( a-addr -- x )
;
; x is the value stored at a-addr.

		WORD	"@",NORMAL
FETCH:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Fetch the target address
		XPAL	R2
		LD	1(R1)
		XPAH	R2
		LD	0(R2)		; Fetch the data word from memory
		ST	0(R1)
		LD	1(R2)
		ST	1(R1)

		LDI	LO(NEXT-1)	; Restore R2
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAH	R2
		XPPC	R2		; And continue

; ALLOT ( n -- )
;
; If n is greater than zero, reserve n address units of data space. If n is
; less than zero, release |n| address units of data space. If n is zero, leave
; the data-space pointer unchanged.
;
; In this implementation its is defined as:
;
;   DP +!

		WORD	"ALLOT",NORMAL
ALLOT:		FORTH
		.WORD	DP
		.WORD	PLUS_STORE
		.WORD	EXIT

; C! ( char c-addr -- )
;
; Store char at c-addr. When character size is smaller than cell size, only the
; number of low-order bits corresponding to character size are transferred.

		WORD	"C!",NORMAL
C_STORE:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Fetch the target address
		XPAL	R2
		LD	1(R1)
		XPAH	R2
		LD	2(R1)		; Store the data word
		ST	0(R2)
		ILD	SP+0(MA)	; Drop the top two words
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		ILD	SP+0(MA)

		LDI	LO(NEXT-1)	; Restore R2
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAH	R2
		XPPC	R2		; And continue

; C, ( char -- )
;
; Reserve space for one character in the data space and store char in the
; space. If the data-space pointer is character aligned when C, begins
; execution, it will remain character aligned when C, finishes execution.
; An ambiguous condition exists if the data-space pointer is not character-
; aligned prior to execution of C,
;
;   HERE C! 1 CHARS ALLOT

		WORD	"C,",NORMAL
C_COMMA:	FORTH
		.WORD	HERE
		.WORD	C_STORE
		.WORD	DO_LITERAL,1
		.WORD	CHARS
		.WORD	ALLOT
		.WORD	EXIT

; C@ ( c-addr -- char )
;
; Fetch the character stored at c-addr. When the cell size is greater than
; character size, the unused high-order bits are all zeroes.

		WORD	"C@",NORMAL
C_FETCH:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Fetch the target address
		XPAL	R2
		LD	1(R1)
		XPAH	R2
		LD	0(R2)		; Fetch the data byte from memory
		ST	0(R1)
		LDI	0
		ST	1(R1)

		LDI	LO(NEXT-1)	; Restore R2
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAH	R2
		XPPC	R2		; And continue

; HERE ( -- addr )
;
; addr is the data-space pointer.

		WORD	"HERE",NORMAL
HERE:		FORTH
		.WORD	DP
		.WORD	FETCH
		.WORD	EXIT

;===============================================================================
; Alignment
;-------------------------------------------------------------------------------

; ALIGN ( -- )
;
; If the data-space pointer is not aligned, reserve enough space to align it.

		WORD	"ALIGN",NORMAL
ALIGN:		NATIVE
		XPPC	R2		; And continue

; ALIGNED ( addr -- a-addr )
;
; a-addr is the first aligned address greater than or equal to addr.

		WORD	"ALIGNED",NORMAL
ALIGNED:	NATIVE
		XPPC	R2		; And continue

; CELL+ ( a-addr1 -- a-addr2 )
;
; Add the size in address units of a cell to a-addr1, giving a-addr2.

		WORD	"CELL+",NORMAL
CELL_PLUS:	FORTH
		.WORD	DO_LITERAL,2
		.WORD	PLUS
		.WORD	EXIT

; CELLS ( n1 -- n2 )
;
; n2 is the size in address units of n1 cells.

		WORD	"CELLS",NORMAL
CELLS:		FORTH
		.WORD	TWO_STAR
		.WORD	EXIT

; CHAR+ ( c-addr1 -- c-addr2 )
;
; Add the size in address units of a character to c-addr1, giving c-addr2.

		WORD	"CHAR+",NORMAL
CHAR_PLUS:	FORTH
		.WORD	ONE_PLUS
		.WORD	EXIT

; CHAR- ( c-addr1 -- c-addr2 )
;
; Subtract the size in address units of a character to c-addr1, giving c-addr2.

		WORD	"CHAR-",NORMAL
CHAR_MINUS:	FORTH
		.WORD	ONE_MINUS
		.WORD	EXIT

; CHARS ( n1 -- n2 )
;
; n2 is the size in address units of n1 characters.

		WORD	"CHARS",NORMAL
CHARS:		NATIVE
		XPPC	R2		; And continue

;===============================================================================
; Stack Operations
;-------------------------------------------------------------------------------

; 2DROP ( x1 x2 -- )
;
; Drop cell pair x1 x2 from the stack.

		WORD	"2DROP",NORMAL
TWO_DROP:	NATIVE
		ILD	SP+0(MA)	; Increment the data stack poiner
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; 2DUP ( x1 x2 -- x1 x2 x1 x2 )
;
; Duplicate cell pair x1 x2.

		WORD	"2DUP",NORMAL
TWO_DUP:	FORTH
		.WORD	OVER
		.WORD	OVER
		.WORD	EXIT

; 2OVER ( x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2 )
;
; Copy cell pair x1 x2 to the top of the stack.

		WORD	"2OVER",NORMAL
TWO_OVER:	FORTH
		.WORD	EXIT

		; 2ROT ( x1 x2 x3 x4 x5 x6 -- x3 x4 x5 x6 x1 x2 )
;
; Rotate the top three cell pairs on the stack bringing cell pair x1 x2 to
; the top of the stack.

		WORD	"2ROT",NORMAL
TWO_ROT:	FORTH
		.WORD	EXIT

; 2SWAP ( x1 x2 x3 x4 -- x3 x4 x1 x2 )
;
; Exchange the top two cell pairs.

		WORD	"2SWAP",NORMAL
TWO_SWAP:	FORTH
		.WORD	EXIT

; ?DUP ( x -- 0 | x x )
;
; Duplicate x if it is non-zero.

		WORD	"?DUP",NORMAL
QUERY_DUP:	NATIVE
		LD	SP+0(MA)
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)
		OR	1(R1)
		JNZ	DUP+2
		XPPC	R2

; DEPTH ( -- +n )
;
; +n is the number of single-cell values contained in the data stack before +n
; was placed on the stack.

		WORD	"DEPTH",NORMAL
DEPTH:		FORTH
		.WORD	AT_DP
		.WORD	DO_LITERAL,DSTACK_END-1
		.WORD	SWAP
		.WORD	MINUS
		.WORD	TWO_SLASH
		.WORD	EXIT

; DROP ( x -- )
;
; Remove x from the stack.

		WORD	"DROP",NORMAL
DROP:		NATIVE
		ILD	SP+0(MA)	; Increment the data stack poiner
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; DUP ( x -- x x )
;
; Duplicate x.

		WORD	"DUP",NORMAL
DUP:		NATIVE
		DLD	SP+0(MA)	; Reserved a cell on the stack
		DLD	SP+0(MA)
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	2(R1)		; Duplicate the top cell
		ST	0(R1)
		LD	3(R1)
		ST	1(R1)
		XPPC	R2

; NIP ( x1 x2 -- x2 )
;
; Drop the first item below the top of stack.

		WORD	"NIP",NORMAL
NIP:		FORTH
		.WORD	SWAP
		.WORD	DROP
		.WORD	EXIT

; OVER ( x1 x2 -- x1 x2 x1 )
;
; Place a copy of x1 on top of the stack.

		WORD	"OVER",NORMAL
OVER:		NATIVE
		DLD	SP+0(MA)	; Reserved a cell on the stack
		DLD	SP+0(MA)
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	4(R1)		; Duplicate the second cell
		ST	0(R1)
		LD	5(R1)
		ST	1(R1)
		XPPC	R2

; PICK ( xu ... x1 x0 u -- xu ... x1 x0 xu )
;
; Remove u. Copy the xu to the top of the stack. An ambiguous condition exists
; if there are less than u+2 items on the stack before PICK is executed.

		WORD	"PICK",NORMAL
PICK:		NATIVE
		XPPC	R2

; ROLL ( xu xu-1 ... x0 u -- xu-1 ... x0 xu )
;
; Remove u. Rotate u+1 items on the top of the stack. An ambiguous condition
; exists if there are less than u+2 items on the stack before ROLL is executed.

		WORD	"ROLL",NORMAL
ROLL:		NATIVE
		XPPC	R2

; ROT ( x1 x2 x3 -- x2 x3 x1 )
;
; Rotate the top three stack entries.

		WORD	"ROT",NORMAL
ROT:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	4(R1)		; Rotate the LSBs
		XAE
		LD	2(R1)
		ST	4(R1)
		LD	0(R1)
		ST	2(R1)
		LDE
		ST	0(R1)
		LD	5(R1)		; Rotate the MSBs
		XAE
		LD	3(R1)
		ST	5(R1)
		LD	1(R1)
		ST	3(R1)
		LDE
		ST	1(R1)
		XPPC	R2		; And continue

; SWAP ( x1 x2 -- x2 x1 )
;
; Exchange the top two stack items.

		WORD	"SWAP",NORMAL
SWAP:		NATIVE
		LD	SP+0(MA)	; Load the stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Swap LSBs
		XAE
		LD	2(R1)
		ST	0(R1)
		XAE
		ST	2(R1)
		LD	1(R1)		; Swap MSBs
		XAE
		LD	3(R1)
		ST	1(R1)
		XAE
		ST	3(R1)
		XPPC	R2		; And continue

; TUCK ( x1 x2 -- x2 x1 x2 )
;
; Copy the first (top) stack item below the second stack item.

		WORD	"TUCK",NORMAL
TUCK:		FORTH
		.WORD	SWAP
		.WORD	OVER
		.WORD	EXIT

;===============================================================================
; Return Stack Operations
;-------------------------------------------------------------------------------

; 2>R ( x1 x2 -- ) ( R: -- x1 x2 )
;
; Transfer cell pair x1 x2 to the return stack. Semantically equivalent to
; SWAP >R >R.

		WORD	"2>R",NORMAL
TWO_TO_R:	FORTH
		.WORD	SWAP
		.WORD	TO_R
		.WORD	TO_R
		.WORD	EXIT

; 2R> ( -- x1 x2 ) ( R: x1 x2 -- )
;
; Transfer cell pair x1 x2 from the return stack. Semantically equivalent to R>
; R> SWAP.

		WORD	"2R>",NORMAL
TWO_R_FROM:	FORTH
		.WORD	R_FROM
		.WORD	R_FROM
		.WORD	SWAP
		.WORD	EXIT

; 2R@ ( -- x1 x2 ) ( R: x1 x2 -- x1 x2 )
;
; Copy cell pair x1 x2 from the return stack. Semantically equivalent to R> R>
; 2DUP >R >R SWAP.

		WORD	"2R@",NORMAL
TWO_R_FETCH:	FORTH
		.WORD	R_FROM
		.WORD	R_FROM
		.WORD	OVER
		.WORD	OVER
		.WORD	TO_R
		.WORD	TO_R
		.WORD	SWAP
		.WORD	EXIT

; >R ( x -- ) ( R: -- x )
;
; Move x to the return stack.

		WORD	">R",NORMAL
TO_R:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		DLD	RP+0(MA)	; Reserve a cell on the return stack
		DLD	RP+0(MA)	; .. and load the pointer
		XPAL	R2
		LD	RP+1(MA)
		XPAH	R2
		LD	0(R1)		; Tranfer a word across
		ST	0(R2)
		LD	1(R1)
		ST	1(R2)
		ILD	SP+0(MA)	; Drop cell from data stack
		ILD	SP+0(MA)

		LDI	LO(NEXT-1)	; Restore the NEXT pointer
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAL	R2
		XPPC	R2		; All done

; I ( -- n|u ) ( R: loop-sys -- loop-sys )
;
; n|u is a copy of the current (innermost) loop index. An ambiguous condition
; exists if the loop control parameters are unavailable.

		WORD	"I",NORMAL
I:		NATIVE
		DLD	SP+0(MA)	; Reserve a cell in the data stack
		DLD	SP+0(MA)	; .. and load the pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	RP+0(MA)	; Load the return stack pointer
		XPAL	R2
		LD	RP+1(MA)
		XPAH	R2
		LD	0(R2)		; Copy the inner loop counter
		ST	0(R1)
		LD	1(R2)
		ST	1(R1)
		LDI	LO(NEXT-1)	; Restore the NEXT pointer
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAL	R2
		XPPC	R2		; And continue

; J ( -- n|u ) ( R: loop-sys1 loop-sys2 -- loop-sys1 loop-sys2 )
;
; n|u is a copy of the next-outer loop index. An ambiguous condition exists if
; the loop control parameters of the next-outer loop, loop-sys1, are
; unavailable.

		WORD	"J",NORMAL
J:		NATIVE
		DLD	SP+0(MA)	; Reserve a cell in the data stack
		DLD	SP+0(MA)	; .. and load the pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	RP+0(MA)	; Load the return stack pointer
		XPAL	R2
		LD	RP+1(MA)
		XPAH	R2
		LD	4(R2)		; Copy the outer loop counter
		ST	0(R1)
		LD	5(R2)
		ST	1(R1)
		LDI	LO(NEXT-1)	; Restore the NEXT pointer
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAL	R2
		XPPC	R2		; And continue

; R> ( -- x ) ( R: x -- )
;
; Move x from the return stack to the data stack.

		WORD	"R>",NORMAL
R_FROM:		NATIVE
		DLD	SP+0(MA)	; Reserve a cell in the data stack
		DLD	SP+0(MA)	; .. and load the pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	RP+0(MA)	; Load the return stack pointer
		XPAL	R2
		LD	RP+1(MA)
		XPAH	R2
		LD	0(R2)		; Copy the top cell
		ST	0(R1)
		LD	1(R2)
		ST	1(R1)
		ILD	RP+0(MA)	; Drop cell from return stack
		ILD	RP+1(MA)
		LDI	LO(NEXT-1)	; Restore the NEXT pointer
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAL	R2
		XPPC	R2		; And continue

; R@ ( -- x ) ( R: x -- x )
;
; Copy x from the return stack to the data stack.

		WORD	"R@",NORMAL
R_FETCH:	NATIVE
		DLD	SP+0(MA)	; Reserve a cell in the data stack
		DLD	SP+0(MA)	; .. and load the pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	RP+0(MA)	; Load the return stack pointer
		XPAL	R2
		LD	RP+1(MA)
		XPAH	R2
		LD	0(R2)		; Copy the top cell
		ST	0(R1)
		LD	1(R2)
		ST	1(R1)
		LDI	LO(NEXT-1)	; Restore the NEXT pointer
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAL	R2
		XPPC	R2		; And continue

;===============================================================================
; Single Precision Arithmetic
;-------------------------------------------------------------------------------

; * ( n1|u1 n2|u2 -- n3|u3 )
;
; Multiply n1|u1 by n2|u2 giving the product n3|u3.
;
; In this implementation it is defined as:
;
;   M* DROP

		WORD	"*",NORMAL
STAR:		FORTH
		.WORD	M_STAR
		.WORD	DROP
		.WORD	EXIT

; */ ( n1 n2 n3 -- n4 )
;
; Multiply n1 by n2 producing the intermediate double-cell result d. Divide d
; by n3 giving the single-cell quotient n4. An ambiguous condition exists if
; n3 is zero or if the quotient n4 lies outside the range of a signed number.
; If d and n3 differ in sign, the implementation-defined result returned will
; be the same as that returned by either the phrase >R M* R> FM/MOD SWAP DROP
; or the phrase >R M* R> SM/REM SWAP DROP.
;
; In this implementation it is defined as:
;
;   >R M* R> FM/MOD SWAP DROP

		WORD	"*/",NORMAL
STAR_SLASH:	FORTH
		.WORD	TO_R
		.WORD	M_STAR
		.WORD	R_FROM
		.WORD	FM_SLASH_MOD
		.WORD	SWAP
		.WORD	DROP
		.WORD	EXIT

; */MOD ( n1 n2 n3 -- n4 n5 )
;
; Multiply n1 by n2 producing the intermediate double-cell result d. Divide d
; by n3 producing the single-cell remainder n4 and the single-cell quotient n5.
; An ambiguous condition exists if n3 is zero, or if the quotient n5 lies
; outside the range of a single-cell signed integer. If d and n3 differ in
; sign, the implementation-defined result returned will be the same as that
; returned by either the phrase >R M* R> FM/MOD or the phrase >R M* R> SM/REM.
;
; In this implementation it is defined as:
;
;   >R M* R> FM/MOD

		WORD	"*/MOD",NORMAL
STAR_SLASH_MOD: FORTH
		.WORD	TO_R
		.WORD	M_STAR
		.WORD	R_FROM
		.WORD	FM_SLASH_MOD
		.WORD	EXIT

; + ( n1|u1 n2|u2 -- n3|u3 )
;
; Add n2|u2 to n1|u1, giving the sum n3|u3.

		WORD	"+",NORMAL
PLUS:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Add the top two cells
		LD	2(R1)
		ADD	0(R1)
		ST	2(R1)
		LD	3(R1)
		ADD	2(R1)
		ST	3(R1)
		ILD	SP+0(MA)	; Drop the top cell
		ILD	SP+1(MA)
		XPPC	R2		; And continue

; - ( n1|u1 n2|u2 -- n3|u3 )
;
; Subtract n2|u2 from n1|u1, giving the difference n3|u3.

		WORD	"-",NORMAL
MINUS:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		SCL			; Add the top two cells
		LD	2(R1)
		CAD	0(R1)
		ST	2(R1)
		LD	3(R1)
		CAD	1(R1)
		ST	3(R1)
		ILD	SP+0(MA)	; Drop the top cell
		ILD	SP+1(MA)
		XPPC	R2		; And continue

; / ( n1 n2 -- n3 )
;
; Divide n1 by n2, giving the single-cell quotient n3. An ambiguous condition
; exists if n2 is zero. If n1 and n2 differ in sign, the implementation-defined
; result returned will be the same as that returned by either the phrase >R S>D
; R> FM/MOD SWAP DROP or the phrase >R S>D R> SM/REM SWAP DROP.
;
; In this implementatio it is defined as:
;
;   >R S>D R> FM/MOD SWAP DROP

		WORD	"/",NORMAL
SLASH:		FORTH
		.WORD	TO_R
		.WORD	S_TO_D
		.WORD	R_FROM
		.WORD	FM_SLASH_MOD
		.WORD	SWAP
		.WORD	DROP
		.WORD	EXIT

; /MOD ( n1 n2 -- n3 n4 )
;
; Divide n1 by n2, giving the single-cell remainder n3 and the single-cell
; quotient n4. An ambiguous condition exists if n2 is zero. If n1 and n2 differ
; in sign, the implementation-defined result returned will be the same as that
; returned by either the phrase >R S>D R> FM/MOD or the phrase >R S>D R> SM/REM.
;
; In this implementation it is defined as:
;
;   >R S>D R> FM/MOD

		WORD	"/MOD",NORMAL
SLASH_MOD:	FORTH
		.WORD	TO_R
		.WORD	S_TO_D
		.WORD	R_FROM
		.WORD	FM_SLASH_MOD
		.WORD	EXIT

; 1+ ( n1|u1 -- n2|u2 )
;
; Add one (1) to n1|u1 giving the sum n2|u2.

		WORD	"1+",NORMAL
ONE_PLUS:	FORTH
		.WORD	DO_LITERAL,1
		.WORD	PLUS
		.WORD	EXIT

; 1- ( n1|u1 -- n2|u2 )
;
; Subtract one (1) from n1|u1 giving the difference n2|u2.

		WORD	"1-",NORMAL
ONE_MINUS:	FORTH
		.WORD	DO_LITERAL,1
		.WORD	MINUS
		.WORD	EXIT

; 2* ( x1 -- x2 )
;
; x2 is the result of shifting x1 one bit toward the most-significant bit,
; filling the vacated least-significant bit with zero.

		WORD	"2*",NORMAL
TWO_STAR:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Add top of stack to itself
		LD	0(R1)
		ADD	0(R1)
		ST	0(R1)
		LD	1(R1)
		ADD	1(R1)
		ST	1(R1)
		XPPC	R2		; And continue

; 2/ ( x1 -- x2 )
;
; x2 is the result of shifting x1 one bit toward the least-significant bit,
; leaving the most-significant bit unchanged.

		WORD	"2/",NORMAL
TWO_SLASH:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Shift MSB into carry
		LD	1(R1)
		ADD	1(R1)
		LD	1(R1)		; Then rotate cell right
		RRL
		ST	1(R1)
		LD	0(R1)
		RRL
		ST	0(R1)
		XPPC	R2		; And continue

; ?NEGATE ( x sign -- x/-x)
;
; If the sign value is negative then negate the value of x to match.
;
; In this implementation it is defined as:
;
;   0< IF NEGATE THEN

QUERY_NEGATE:	FORTH
		.WORD	ZERO_LESS
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	NEGATE
.SKIP 		.WORD	EXIT

; ABS ( n -- u )
;
; u is the absolute value of n.

		WORD	"ABS",NORMAL
ABS:		FORTH
		.WORD	DUP
		.WORD	ZERO_LESS
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	NEGATE
.SKIP		.WORD	EXIT

; FM/MOD ( n1 n2 -- n3 n4 )
;
; Divide n1 by n2, giving the single-cell remainder n3 and the single-cell
; quotient n4. An ambiguous condition exists if n2 is zero. If n1 and n2 differ
; in sign, the implementation-defined result returned will be the same as that
; returned by either the phrase >R S>D R> FM/MOD or the phrase >R S>D R> SM/REM.
;
; In this implementation it is defined as:
;
;   DUP >R			divisor
;   2DUP XOR >R			sign of quotient
;   >R				divisor
;   DABS R@ ABS UM/MOD
;   SWAP R> ?NEGATE SWAP	apply sign to remainder
;   R> 0< IF			if quotient negative,
;	NEGATE
;	OVER IF			if remainder nonzero,
;	R@ ROT - SWAP 1-	adjust rem,quot
;	THEN
;   THEN  R> DROP ;

		WORD	"FM/MOD",NORMAL
FM_SLASH_MOD:	FORTH
		.WORD	DUP
		.WORD	TO_R
		.WORD	TWO_DUP
		.WORD	XOR
		.WORD	TO_R
		.WORD	TO_R
		.WORD	DABS
		.WORD	R_FETCH
		.WORD	ABS
		.WORD	UM_SLASH_MOD
		.WORD	SWAP
		.WORD	R_FROM
		.WORD	QUERY_NEGATE
		.WORD	SWAP
		.WORD	R_FROM
		.WORD	ZERO_LESS
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	NEGATE
		.WORD	OVER
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	R_FETCH
		.WORD	ROT
		.WORD	MINUS
		.WORD	SWAP
		.WORD	ONE_MINUS
.SKIP		.WORD	R_FROM
		.WORD	DROP
		.WORD	EXIT

; MAX ( n1 n2 -- n3 )
;
; n3 is the greater of n1 and n2.

		WORD	"MAX",NORMAL
MAX:		FORTH
		.WORD	TWO_DUP
		.WORD	LESS
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	SWAP
.SKIP		.WORD	DROP
		.WORD	EXIT

; MIN ( n1 n2 -- n3 )
;
; n3 is the lesser of n1 and n2.

		WORD	"MIN",NORMAL
MIN:		FORTH
		.WORD	TWO_DUP
		.WORD	GREATER
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	SWAP
.SKIP		.WORD	DROP
		.WORD	EXIT

; MOD ( n1 n2 -- n3 )
;
; Divide n1 by n2, giving the single-cell remainder n3. An ambiguous condition
; exists if n2 is zero. If n1 and n2 differ in sign, the implementation-defined
; result returned will be the same as that returned by either the phrase >R S>D
; R> FM/MOD DROP or the phrase >R S>D R> SM/REM DROP.
;
; In this implementation it is defined as:
;
;   >R S>D R> FM/MOD DROP

		WORD	"MOD",NORMAL
MOD:		FORTH
		.WORD	TO_R
		.WORD	S_TO_D
		.WORD	R_FROM
		.WORD	FM_SLASH_MOD
		.WORD	DROP
		.WORD	EXIT

; NEGATE ( n1 -- n2 )
;
; Negate n1, giving its arithmetic inverse n2.

		WORD	"NEGATE",NORMAL
NEGATE:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		SCL			; Negate the top word
		LDI	0
		CAD	0(R1)
		ST	0(R1)
		LDI	0
		CAD	1(R1)
		ST	1(R1)
		XPPC	R2		; And continue

; UMAX ( x1 x2 -- x3 )
;
; x3 is the greater of x1 and x2.

		WORD	"UMAX",NORMAL
UMAX:		FORTH
		.WORD	TWO_DUP
		.WORD	U_LESS
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	SWAP
.SKIP		.WORD	DROP
		.WORD	EXIT

; UMIN ( x1 x2 -- x3 )
;
; x3 is the lesser of x1 and x2.

		WORD	"UMIN",NORMAL
UMIN:		FORTH
		.WORD	TWO_DUP
		.WORD	U_LESS
		.WORD	INVERT
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	SWAP
.SKIP		.WORD	DROP
		.WORD	EXIT

;===============================================================================
; Double Precision Arithmetic
;-------------------------------------------------------------------------------

; ?DNEGATE ( d1 sign -- d1/-d1 )
;
; If sign is less than zero than negate d1 otherwise leave it unchanged.

QUERY_DNEGATE:	FORTH
		.WORD	ZERO_LESS
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	DNEGATE
.SKIP		.WORD	EXIT

; D+ ( d1|ud1 d2|ud2 -- d3|ud3 )
;
; Add d2|ud2 to d1|ud1, giving the sum d3|ud3.

		WORD	"D+",NORMAL
D_PLUS:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Add top cells
		LD	6(R1)
		ADD	2(R1)
		ST	6(R1)
		LD	7(R1)
		ADD	3(R1)
		ST	7(R1)
		LD	4(R1)
		ADD	0(R1)
		ST	4(R1)
		LD	5(R1)
		ADD	1(R1)
		ST	5(R1)
		ILD	SP+0(MA)	; Drop the top two cells
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		XPPC	R2

; D- ( d1|ud1 d2|ud2 -- d3|ud3 )
;
; Subtract d2|ud2 from d1|ud1, giving the difference d3|ud3.

		WORD	"D-",NORMAL
D_MINUS:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		SCL			; Subtract top cells
		LD	6(R1)
		CAD	2(R1)
		ST	6(R1)
		LD	7(R1)
		CAD	3(R1)
		ST	7(R1)
		LD	4(R1)
		CAD	0(R1)
		ST	4(R1)
		LD	5(R1)
		CAD	1(R1)
		ST	5(R1)
		ILD	SP+0(MA)	; Drop the top two cells
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		ILD	SP+0(MA)
		XPPC	R2

; D0< ( d -- flag )
;
; flag is true if and only if d is less than zero.

		WORD	"D0<",NORMAL
D_ZERO_LESS:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Extract the sign bit
		LD	1(R1)
		ADD	1(R1)
		LDI	0		; Work out sign byte
		ADI	X'FF
		XRI	X'FF
		ST	2(R1)		; And create flag
		ST	3(R1)
		ILD	SP+0(MA)	; Drop top cell
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; D0= ( d -- flag )
;
; flag is true if and only if d is equal to zero.

		WORD	"D0=",NORMAL
D_ZERO_EQUAL:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Test all the bits
		OR	1(R1)
		OR	2(R1)
		OR	3(R1)
		JZ	.ZERO		; Make the flag byte
		LDI	X'FF
.ZERO		XRI	X'FF
		ST	2(R1)
		ST	3(R1)
		ILD	SP+0(MA)	; Drop top cell
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; D2* ( xd1 -- xd2 )
;
; xd2 is the result of shifting xd1 one bit toward the most-significant bit,
; filling the vacated least-significant bit with zero.

		WORD	"D2*",NORMAL
D_TWO_STAR:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Add top cells to themselves
		LD	2(R1)
		ADD	2(R1)
		ST	2(R1)
		LD	3(R1)
		ADD	3(R1)
		ST	3(R1)
		LD	0(R1)
		ADD	0(R1)
		ST	0(R1)
		LD	1(R1)
		ADD	1(R1)
		ST	1(R1)
		XPPC	R2		; And continue

; D2/ ( xd1 -- xd2 )
;
; xd2 is the result of shifting xd1 one bit toward the least-significant bit,
; leaving the most-significant bit unchanged.

		WORD	"D2/",NORMAL
D_TWO_SLASH:
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Extract the sign bit
		LD	1(R1)
		ADD	1(R1)
		LD	1(R1)		; Shift the value right
		RRL
		ST	1(R1)
		LD	0(R1)
		RRL
		ST	0(R1)
		LD	3(R1)
		RRL
		ST	3(R1)
		LD	2(R1)
		RRL
		ST	2(R1)
		XPPC	R2		; And continue

; D< ( d1 d2 -- flag )
;
; flag is true if and only if d1 is less than d2.

		WORD	"D<",NORMAL
D_LESS:		FORTH
		.WORD	D_MINUS
		.WORD	D_ZERO_LESS
		.WORD	EXIT

; D= ( d1 d2 -- flag )
;
; flag is true if and only if d1 is bit-for-bit the same as d2.

		WORD	"D=",NORMAL
D_EQUAL:	FORTH
		.WORD	D_MINUS
		.WORD	D_ZERO_EQUAL
		.WORD	EXIT

; DABS ( d -- ud )
;
; ud is the absolute value of d.

		WORD	"DABS",NORMAL
DABS:		FORTH
		.WORD	TWO_DUP
		.WORD	D_ZERO_LESS
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	DNEGATE
.SKIP		.WORD	EXIT

; DMAX ( d1 d2 -- d3 )
;
; d3 is the greater of d1 and d2.

		WORD	"DMAX",NORMAL
DMAX:		FORTH
		.WORD	TWO_OVER
		.WORD	TWO_OVER
		.WORD	D_LESS
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	TWO_SWAP
.SKIP		.WORD	TWO_DROP
		.WORD	EXIT

; DMIN ( d1 d2 -- d3 )
;
; d3 is the lesser of d1 and d2.

		WORD	"DMIN",NORMAL
DMIN:		FORTH
		.WORD	TWO_OVER
		.WORD	TWO_OVER
		.WORD	D_LESS
		.WORD	INVERT
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	TWO_SWAP
.SKIP		.WORD	TWO_DROP
		.WORD	EXIT

; DNEGATE ( d1 -- d2 )
;
; d2 is the negation of d1.

		WORD	"DNEGATE",NORMAL
DNEGATE:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		SCL			; Negate the top word
		LDI	0
		CAD	2(R1)
		ST	2(R1)
		LDI	0
		CAD	3(R1)
		ST	3(R1)
		LDI	0
		CAD	0(R1)
		ST	0(R1)
		LDI	0
		CAD	1(R1)
		ST	1(R1)
		XPPC	R2		; And continue

;===============================================================================
; Mixed Arithmetic
;-------------------------------------------------------------------------------

; D>S ( d -- n )
;
; n is the equivalent of d. An ambiguous condition exists if d lies outside the
; range of a signed single-cell number.

		WORD	"D>S",NORMAL
D_TO_S:		NATIVE
		ILD	SP+0(MA)	; Drop the high word
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; M* ( n1 n2 -- d )
;
; d is the signed product of n1 times n2.
;
; In this implementation it is defined as:
;
;   2DUP XOR >R			carries sign of the result
;   SWAP ABS SWAP ABS UM*
;   R> ?DNEGATE

		WORD	"M*",NORMAL
M_STAR:		FORTH
		.WORD	TWO_DUP
		.WORD	XOR
		.WORD	TO_R
		.WORD	SWAP
		.WORD	ABS
		.WORD	SWAP
		.WORD	ABS
		.WORD	UM_STAR
		.WORD	R_FROM
		.WORD	QUERY_DNEGATE
		.WORD	EXIT

; M*/ ( d1 n1 +n2 -- d2 )
;
; Multiply d1 by n1 producing the triple-cell intermediate result t. Divide t
; by +n2 giving the double-cell quotient d2. An ambiguous condition exists if
; +n2 is zero or negative, or the quotient lies outside of the range of a
; double-precision signed integer.



; M+ ( d1|ud1 n -- d2|ud2 )
;
; Add n to d1|ud1, giving the sum d2|ud2.

		WORD	"M+",NORMAL
M_PLUS:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Add n to d
		LD	4(R1)
		ADD	0(R1)
		ST	4(R1)
		LD	5(R1)
		ADD	1(R1)
		ST	5(R1)
		LD	2(R1)
		ADI	0
		ST	2(R1)
		LD	3(R1)
		ADI	0
		ST	3(R1)
		ILD	SP+0(MA)	; Drop the top cell
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; S>D ( n -- d )
;
; Convert the number n to the double-cell number d with the same numerical
; value.

		WORD	"S>D",NORMAL
S_TO_D:		FORTH
		.WORD	DUP
		.WORD	ZERO_LESS
		.WORD	EXIT

; SM/REM ( d1 n1 -- n2 n3 )
;
; Divide d1 by n1, giving the symmetric quotient n3 and the remainder n2.
; Input and output stack arguments are signed. An ambiguous condition exists if
; n1 is zero or if the quotient lies outside the range of a single-cell signed
; integer.
;
; In this implementation it is defined as:
;
;   2DUP XOR >R			sign of quotient
;   OVER >R			sign of remainder
;   ABS >R DABS R> UM/MOD
;   SWAP R> ?NEGATE
;   SWAP R> ?NEGATE ;

		WORD	"SM/REM",NORMAL
SM_SLASH_REM:	FORTH
		.WORD	TWO_DUP
		.WORD	XOR
		.WORD	TO_R
		.WORD	OVER
		.WORD	TO_R
		.WORD	ABS
		.WORD	TO_R
		.WORD	DABS
		.WORD	R_FROM
		.WORD	UM_SLASH_MOD
		.WORD	SWAP
		.WORD	R_FROM
		.WORD	QUERY_NEGATE
		.WORD	SWAP
		.WORD	R_FROM
		.WORD	QUERY_NEGATE
		.WORD	EXIT

; UD* ( ud1 d2 -- ud3)
;
; 32*16->32 multiply
;
;   DUP >R UM* DROP SWAP R> UM* ROT + ;

		WORD	"UD*",NORMAL
UD_STAR:	FORTH
		.WORD	DUP
		.WORD	TO_R
		.WORD	UM_STAR
		.WORD	DROP
		.WORD	SWAP
		.WORD	R_FROM
		.WORD	UM_STAR
		.WORD	ROT
		.WORD	PLUS
		.WORD	EXIT

; UM* ( u1 u2 -- ud )
;
; Multiply u1 by u2, giving the unsigned double-cell product ud. All values and
; arithmetic are unsigned.

		WORD	"UM*",NORMAL
UM_STAR:	NATIVE
	.IF	0
;		 lda	 <1			 ; Fetch multiplier
;		 pha
;		 stz	 <1			 ; Clear the result
;		 ldx	 #16
;UM_STAR_1:	 lda	 <3			 ; Shift multiplier one bit
;		 lsr	 a
;		 bcc	 UM_STAR_2		 ; Not set, no add
;		 lda	 1,s			 ; Fetch multiplicand
;		 clc
;		 adc	 <1
;		 sta	 <1
;UM_STAR_2:	 ror	 <1			 ; Rotate high word down
;		 ror	 <3
;		 dex
;		 bne	 UM_STAR_1
;		 pla
	.ENDIF
		XPPC	R2		; And continue

; UM/MOD ( ud u1 -- u2 u3 )
;
; Divide ud by u1, giving the quotient u3 and the remainder u2. All values and
; arithmetic are unsigned. An ambiguous condition exists if u1 is zero or if the
; quotient lies outside the range of a single-cell unsigned integer.

		WORD	"UM/MOD",NORMAL
UM_SLASH_MOD:	NATIVE
	.IF	0
;		 sec				 ; Check for overflow
;		 lda	 <3
;		 sbc	 <1
;		 bcs	 UM_SLASH_MOD_3

;		 ldx	 #17
;UM_SLASH_MOD_1: rol	 <5			 ; Rotate dividend lo
;		 dex
;		 beq	 UM_SLASH_MOD_4
;		 rol	 <3
;		 bcs	 UM_SLASH_MOD_2		 ; Carry set dividend > divisor

;		 lda	 <3			 ; Is dividend < divisor?;
;		 cmp	 <1
;		 bcc	 UM_SLASH_MOD_1		 ; Yes, shift in 0

;UM_SLASH_MOD_2: lda	 <3			 ; Reduce dividend
;		 sbc	 <1
;		 sta	 <3
;		 bra	 UM_SLASH_MOD_1		 ; Shift in 1

;UM_SLASH_MOD_3: lda	 #$ffff			 ; Overflowed set results
;		 sta	 <3
;		 sta	 <5
;UM_SLASH_MOD_4: tdc				 ; Drop top word
;		 inc	 a
;		 inc	 a
;		 tcd
;		 jmp	 SWAP			 ; Swap quotient and remainder
	.ENDIF
		XPPC	R2		; And continue

;===============================================================================
; Comparisons
;-------------------------------------------------------------------------------

; 0< ( n -- flag )
;
; flag is true if and only if n is less than zero.

		WORD	"0<",NORMAL
ZERO_LESS:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		CCL			; Extract the sign bit
		LD	1(R1)
		ADD	1(R1)
		LDI	0		; Convert to flag value
		ADI	X'FF
		XRI	X'FF
		ST	0(R1)		; And write back to the stack
		ST	1(R1)
		XPPC	R2		; And continue

; 0<> ( x -- flag )
;
; flag is true if and only if x is not equal to zero.

		WORD	"0<>",NORMAL
ZERO_NOT_EQUAL:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Test bits in top cell
		OR	1(R1)
		JZ	.ZERO		; And form the flag
		LDI	X'FF
.ZERO		ST	0(R1)		; Write back
		ST	1(R1)
		XPPC	R2		; And continue


; 0= ( x -- flag )
;
; flag is true if and only if x is equal to zero.

		WORD	"0=",NORMAL
ZERO_EQUAL:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Test bits in top cell
		OR	1(R1)
		JZ	.ZERO		; And form the flag
		LDI	X'FF
.ZERO		XRI	X'FF
		ST	0(R1)		; Write back
		ST	1(R1)
		XPPC	R2		; And continue

; 0> ( n -- flag )
;
; flag is true if and only if n is greater than zero.

		WORD	"0>",NORMAL
ZERO_GREATER:	FORTH
		.WORD	DUP
		.WORD	ZERO_EQUAL
		.WORD	SWAP
		.WORD	ZERO_LESS
		.WORD	OR
		.WORD	INVERT
		.WORD	EXIT

; < ( n1 n2 -- flag )
;
; flag is true if and only if n1 is less than n2.

		WORD	"<",NORMAL
LESS:		FORTH
		.WORD	SWAP
		.WORD	GREATER
		.WORD	EXIT

; <> ( x1 x2 -- flag )
;
; flag is true if and only if x1 is not bit-for-bit the same as x2.

		WORD	"<>",NORMAL
NOT_EQUAL:	FORTH
		.WORD	MINUS
		.WORD	ZERO_EQUAL
		.WORD	INVERT
		.WORD	EXIT

; = ( x1 x2 -- flag )
;
; flag is true if and only if x1 is bit-for-bit the same as x2.

		WORD	"=",NORMAL
EQUAL:		FORTH
		.WORD	MINUS
		.WORD	ZERO_EQUAL
		.WORD	EXIT

; > ( n1 n2 -- flag )
;
; flag is true if and only if n1 is greater than n2.

		WORD	">",NORMAL
GREATER:	FORTH
		.WORD	MINUS
		.WORD	ZERO_GREATER
		.WORD	EXIT

; U< ( u1 u2 -- flag )
;
; flag is true if and only if u1 is less than u2.

		WORD	"U<",NORMAL
U_LESS:		FORTH
		.WORD	MINUS
		.WORD	ZERO_LESS
		.WORD	EXIT

; U> ( u1 u2 -- flag )
;
; flag is true if and only if u1 is greater than u2.

		WORD	"U>",NORMAL
U_GREATER:	FORTH
		.WORD	SWAP
		.WORD	U_LESS
		.WORD	EXIT

;===============================================================================
; Logical Operations
;-------------------------------------------------------------------------------

; AND ( x1 x2 -- x3 )
;
; x3 is the bit-by-bit logical “and” of x1 with x2.

		WORD	"AND",NORMAL
AND:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	2(R1)		; Perform AND
		AND	0(R1)
		ST	2(R1)
		LD	3(R1)
		AND	1(R1)
		ST	3(R1)
		ILD	SP+0(MA)	; Drop top cell
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; INVERT ( x1 -- x2 )
;
; Invert all bits of x1, giving its logical inverse x2.

		WORD	"INVERT",NORMAL
INVERT:		FORTH
		.WORD	TRUE
		.WORD	XOR
		.WORD	EXIT

; LSHIFT ( x1 u -- x2 )
;
; Perform a logical left shift of u bit-places on x1, giving x2. Put zeroes
; into the least significant bits vacated by the shift. An ambiguous condition
; exists if u is greater than or equal to the number of bits in a cell.

		WORD	"LSHIFT",NORMAL
LSHIFT:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
.LOOP		LD	0(R1)		; Any shift left?
		OR	1(R1)
		JZ	.DONE
		CCL			; Shift by one bit
		LD	2(R1)
		ADD	2(R1)
		ST	2(R1)
		LD	3(R1)
		ADD	3(R1)
		ST	3(R1)
		LD	0(R1)		; Decrement bit count
		JNZ	.DECR
		DLD	1(R1)
.DECR		DLD	0(R1)
		JMP	.LOOP
.DONE		ILD	SP+0(MA)	; Drop the bit count
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; OR ( x1 x2 -- x3 )
;
; x3 is the bit-by-bit inclusive-or of x1 with x2.

		WORD	"OR",NORMAL
OR:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	2(R1)		; Perform OR
		OR	0(R1)
		ST	2(R1)
		LD	3(R1)
		OR	1(R1)
		ST	3(R1)
		ILD	SP+0(MA)	; Drop top cell
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; RSHIFT ( x1 u -- x2 )
;
; Perform a logical right shift of u bit-places on x1, giving x2. Put zeroes
; into the most significant bits vacated by the shift. An ambiguous condition
; exists if u is greater than or equal to the number of bits in a cell.

		WORD	"RSHIFT",NORMAL
RSHIFT:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
.LOOP		LD	0(R1)		; Any shift left?
		OR	1(R1)
		JZ	.DONE
		CCL
		LD	3(R1)		; Shift by one bit
		RRL
		ST	2(R1)
		LD	3(R1)
		RRL
		ST	3(R1)
		LD	0(R1)		; Decrement bit count
		JNZ	.DECR
		DLD	1(R1)
.DECR		DLD	0(R1)
		JMP	.LOOP
.DONE		ILD	SP+0(MA)	; Drop the bit count
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; XOR ( x1 x2 -- x3 )
;
; x3 is the bit-by-bit exclusive-or of x1 with x2.

		WORD	"XOR",NORMAL
XOR:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	2(R1)		; Perform AND
		XOR	0(R1)
		ST	2(R1)
		LD	3(R1)
		XOR	1(R1)
		ST	3(R1)
		ILD	SP+0(MA)	; Drop top cell
		ILD	SP+0(MA)
		XPPC	R2		; And continue

;===============================================================================
; Control Words
;-------------------------------------------------------------------------------

; ?ABORT
;
;   ROT IF TYPE ABORT THEN 2DROP ;

QUERY_ABORT:	FORTH
		.WORD	ROT
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	TYPE
		.WORD	ABORT
.SKIP		.WORD	TWO_DROP
		.WORD	EXIT

; ABORT ( i*x -- ) ( R: j*x -- )
;
; Empty the data stack and perform the function of QUIT, which includes
; emptying the return stack, without displaying a message.

		WORD	"ABORT",NORMAL
ABORT:		FORTH
		.WORD	DO_ABORT
		.WORD	QUIT

DO_ABORT:	NATIVE
		LDI	LO(DSTACK_END)	; Reset the data stack pointer
		ST	SP+0(MA)
		LDI	HI(DSTACK_END)
		ST	SP+1(MA)
		XPPC	R2		; And continue

; (BUILD) ( dtc-addr -- )
;
; Adds a jump the to exection function for the new word.

;		WORD	"(BUILD)",NORMAL
BUILD:		FORTH
		.WORD	ONE_MINUS
		.WORD	COMMA
		.WORD	EXIT

; CREATE ( -- )
;
; Skip leading space delimiters. Parse name delimited by a space. Create a
; definition for name with the execution semantics defined below. If the data-
; space pointer is not aligned, reserve enough data space to align it. The new
; data-space pointer defines name’s data field. CREATE does not allocate data
; space in name’s data field.

		WORD	"CREATE",NORMAL
CREATE:		FORTH
		.WORD	LATEST
		.WORD	FETCH
		.WORD	COMMA
		.WORD	ZERO
		.WORD	C_COMMA
		.WORD	HERE
		.WORD	LATEST
		.WORD	STORE
		.WORD	BL
		.WORD	WORD
		.WORD	C_FETCH
		.WORD	ONE_PLUS
		.WORD	ALLOT
		.WORD	EXIT

; EXECUTE ( i*x xt -- j*x )
;
; Remove xt from the stack and perform the semantics identified by it. Other
; stack effects are due to the word EXECUTEd.

		WORD	"EXECUTE",NORMAL
EXECUTE:	NATIVE
		LD	SP+0(MA)	; Load the data stack
		XPAL	R1
		LD	SP+1(MA)
		XPAL	R1
		LD	0(R1)		; Fetch the word address
		XAE
		LD	1(R1)
		XPAH	R1
		LDE
		XPAL	R1
		LD	0(R1)		; Fetch the code address
		XAE
		LD	1(R1)
		XPAH	R1
		LDE
		XPAL	R1
		ILD	SP+0(MA)	; Drop the word address
		ILD	SP+0(MA)
		XPPC	R1		; And execute the word

; EXIT ( -- ) ( R: nest-sys -- )
;
; Return control to the calling definition specified by nest-sys. Before
; executing EXIT within a do-loop, a program shall discard the loop-control
; parameters by executing UNLOOP.

		WORD	"EXIT",NORMAL
EXIT:		NATIVE
		LD	RP+0(MA)	; Load the return stack pointer
		XPAL	R1
		LD	RP+1(MA)
		XPAH	R1
		LD	0(R1)		; Copy the top cell to the IP
		ST	IP+0(MA)
		LD	1(R1)
		ST	IP+1(MA)
		ILD	RP+0(MA)	; Drop the return address
		ILD	RP+0(MA)
		XPPC	R2		; And continue

; QUIT ( -- ) ( R: i*x -- )
;
; Empty the return stack, store zero in SOURCE-ID if it is present, make the
; user input device the input source, and enter interpretation state. Do not
; display a message. Repeat the following:
; – Accept a line from the input source into the input buffer, set >IN to zero,
;   and interpret.
; – Display the implementation-defined system prompt if in interpretation state,
;   all processing has been completed, and no ambiguous condition exists.
;
; In this implementation it is defined as:
;
;   DO_QUIT 0 STATE !
;   0 (SOURCE-ID) !
;   BEGIN
;     REFILL
;     WHILE SOURCE EVALUATE
;     STATE @ 0= IF S" Ok" CR TYPE THEN
;   AGAIN ;

		WORD	"QUIT",NORMAL
QUIT:		FORTH
		.WORD	DO_QUIT
		.WORD	ZERO
		.WORD	STATE
		.WORD	STORE
		.WORD	ZERO
		.WORD	SOURCEID
		.WORD	STORE
QUIT_1:		.WORD	REFILL
		.WORD	QUERY_BRANCH,QUIT_2
		.WORD	INTERPRET
QUIT_2:		.WORD	STATE
		.WORD	FETCH
		.WORD	ZERO_EQUAL
		.WORD	QUERY_BRANCH,QUIT_3
		.WORD	DO_S_QUOTE
		.BYTE	2,"Ok"
		.WORD	TYPE
		.WORD	CR
QUIT_3:		.WORD	BRANCH,QUIT_1

DO_QUIT:	NATIVE
		LDI	LO(RSTACK_END)	; Reset the return stack
		ST	RP+0(MA)
		LDI	HI(RSTACK_END)
		ST	RP+1(MA)
		XPPC	R2		; And continue

;===============================================================================
; Parser & Interpreter
;-------------------------------------------------------------------------------

; ?NUMBER
;
;   DUP	 0 0 ROT COUNT	    -- ca ud adr n
;   ?SIGN >R  >NUMBER	    -- ca ud adr' n'
;   IF	 R> 2DROP 2DROP 0   -- ca 0   (error)
;   ELSE 2DROP NIP R>
;	IF NEGATE THEN	-1  -- n -1   (ok)
;   THEN ;

		WORD	"?NUMBER",NORMAL
QUERY_NUMBER:	FORTH
		.WORD	DUP
		.WORD	ZERO
		.WORD	ZERO
		.WORD	ROT
		.WORD	COUNT
		.WORD	QUERY_SIGN
		.WORD	TO_R
		.WORD	TO_NUMBER
		.WORD	QUERY_BRANCH,QNUM_1
		.WORD	R_FROM
		.WORD	TWO_DROP
		.WORD	TWO_DROP
		.WORD	ZERO
		.WORD	BRANCH,QNUM_3
QNUM_1:		.WORD	TWO_DROP
		.WORD	NIP
		.WORD	R_FROM
		.WORD	QUERY_BRANCH,QNUM_2
		.WORD	NEGATE
QNUM_2:		.WORD	DO_LITERAL,-1
QNUM_3:		.WORD	EXIT

; ?SIGN ( c-addr n -- adr' n' f )
;
;   OVER C@		    -- adr n c
;   2C - DUP ABS 1 = AND    -- +=-1, -=+1, else 0
;   DUP IF 1+		    -- +=0, -=+2
;	>R 1 /STRING R>	    -- adr' n' f
;   THEN ;

		WORD	"?SIGN",NORMAL
QUERY_SIGN:	FORTH
		.WORD	OVER
		.WORD	C_FETCH
		.WORD	DO_LITERAL,','
		.WORD	MINUS
		.WORD	DUP
		.WORD	ABS
		.WORD	DO_LITERAL,1
		.WORD	EQUAL
		.WORD	AND
		.WORD	DUP
		.WORD	QUERY_BRANCH,.SKIP
		.WORD	ONE_PLUS
		.WORD	TO_R
		.WORD	DO_LITERAL,1
		.WORD	SLASH_STRING
		.WORD	R_FROM
.SKIP		.WORD	EXIT

; >COUNTED ( c-addr n -- )
;
;   2DUP C! CHAR+ SWAP CMOVE

TO_COUNTED:	FORTH
		.WORD	TWO_DUP
		.WORD	C_STORE
		.WORD	CHAR_PLUS
		.WORD	SWAP
		.WORD	CMOVE
		.WORD	EXIT

; >NUMBER ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
;
; ud2 is the unsigned result of converting the characters within the string
; specified by c-addr1 u1 into digits, using the number in BASE, and adding
; each into ud1 after multiplying ud1 by the number in BASE. Conversion
; continues left-to-right until a character that is not convertible, including
; any “+” or “-”, is encountered or the string is entirely converted. c-addr2
; is the location of the first unconverted character or the first character
; past the end of the string if the string was entirely converted. u2 is the
; number of unconverted characters in the string. An ambiguous condition exists
; if ud2 overflows during the conversion.
;
; In this implementation its is defined as:
;
;   BEGIN
;   DUP WHILE
;	OVER C@ DIGIT?
;	0= IF DROP EXIT THEN
;	>R 2SWAP BASE @ UD*
;	R> M+ 2SWAP
;	1 /STRING
;   REPEAT ;

		WORD	">NUMBER",NORMAL
TO_NUMBER:	FORTH
TO_NUM_1:	.WORD	DUP
		.WORD	QUERY_BRANCH,TO_NUM_3
		.WORD	OVER
		.WORD	C_FETCH
		.WORD	DIGIT_QUERY
		.WORD	ZERO_EQUAL
		.WORD	QUERY_BRANCH,TO_NUM_2
		.WORD	DROP
		.WORD	EXIT
TO_NUM_2:	.WORD	TO_R
		.WORD	TWO_SWAP
		.WORD	BASE
		.WORD	FETCH
		.WORD	UD_STAR
		.WORD	R_FROM
		.WORD	M_PLUS
		.WORD	TWO_SWAP
		.WORD	DO_LITERAL,1
		.WORD	SLASH_STRING
		.WORD	BRANCH,TO_NUM_1
TO_NUM_3:	.WORD	EXIT

; ACCEPT ( c-addr +n1 -- +n2 )
;
; Receive a string of at most +n1 characters. An ambiguous condition exists if
; +n1 is zero or greater than 32,767. Display graphic characters as they are
; received. A program that depends on the presence or absence of non-graphic
; characters in the string has an environmental dependency. The editing
; functions, if any, that the system performs in order to construct the string
; are implementation-defined.
;
; Input terminates when an implementation-defined line terminator is received.
; When input terminates, nothing is appended to the string, and the display is
; maintained in an implementation-defined way.
;
; +n2 is the length of the string stored at c-addr.
;
; In this implementation it is defined as:
;
;   OVER + 1- OVER	-- sa ea a
;   BEGIN KEY		-- sa ea a c
;   DUP 0D <> WHILE
;     DUP 8 = OVER 127 = OR IF
;	DROP 1-
;	>R OVER R> UMAX
;	8 EMIT SPACE 8 EMIT
;     ELSE
;	DUP EMIT	-- sa ea a c
;	OVER C! 1+ OVER UMIN
;     THEN		-- sa ea a
;   REPEAT		-- sa ea a c
;   DROP NIP SWAP - ;

		WORD	"ACCEPT",NORMAL
ACCEPT:		FORTH
		.WORD	OVER
		.WORD	PLUS
		.WORD	ONE_MINUS
		.WORD	OVER
ACCEPT_1:	.WORD	KEY
		.WORD	DUP
		.WORD	DO_LITERAL,X'0D
		.WORD	NOT_EQUAL
		.WORD	QUERY_BRANCH,ACCEPT_4
		.WORD	DUP
		.WORD	DO_LITERAL,X'08
		.WORD	EQUAL
		.WORD	OVER
		.WORD	DO_LITERAL,X'7f
		.WORD	EQUAL
		.WORD	OR
		.WORD	QUERY_BRANCH,ACCEPT_2
		.WORD	DROP
		.WORD	ONE_MINUS
		.WORD	TO_R
		.WORD	OVER
		.WORD	R_FROM
		.WORD	UMAX
		.WORD	DO_LITERAL,8
		.WORD	EMIT
		.WORD	SPACE
		.WORD	DO_LITERAL,8
		.WORD	EMIT
		.WORD	BRANCH,ACCEPT_3
ACCEPT_2:	.WORD	DUP
		.WORD	EMIT
		.WORD	OVER
		.WORD	C_STORE
		.WORD	ONE_PLUS
		.WORD	OVER
		.WORD	UMIN
ACCEPT_3:	.WORD	BRANCH,ACCEPT_1
ACCEPT_4:	.WORD	DROP
		.WORD	NIP
		.WORD	SWAP
		.WORD	MINUS
		.WORD	EXIT

; DIGIT?
;
;   [ HEX ] DUP 39 > 100 AND +	   silly looking
;   DUP 140 > 107 AND -	  30 -	   but it works!
;   DUP BASE @ U< ;

		WORD	"DIGIT?",NORMAL
DIGIT_QUERY:	FORTH
		.WORD	DUP
		.WORD	DO_LITERAL,'9'
		.WORD	GREATER
		.WORD	DO_LITERAL,X'100
		.WORD	AND
		.WORD	PLUS
		.WORD	DUP
		.WORD	DO_LITERAL,X'140
		.WORD	GREATER
		.WORD	DO_LITERAL,X'107
		.WORD	AND
		.WORD	MINUS
		.WORD	DO_LITERAL,'0'
		.WORD	MINUS
		.WORD	DUP
		.WORD	BASE
		.WORD	FETCH
		.WORD	U_LESS
		.WORD	EXIT

; EVALUATE ( i*x c-addr u -- j*x )
;
; Save the current input source specification. Store minus-one (-1) in
; SOURCE-ID if it is present. Make the string described by c-addr and u both
; the input source and input buffer, set >IN to zero, and interpret. When the
; parse area is empty, restore the prior input source specification. Other
; stack effects are due to the words EVALUATEd.
;
;   >R >R SAVE-INPUT
;   -1 (SOURCE-ID) !
;   0 >IN ! (LENGTH) ! (BUFFER) !
;   INTERPRET
;   RESTORE-INPUT DROP

		WORD	"EVALUATE",NORMAL
EVALUATE:	FORTH
		.WORD	TO_R
		.WORD	TO_R
		.WORD	SAVE_INPUT
		.WORD	R_FROM
		.WORD	R_FROM
		.WORD	TRUE
		.WORD	SOURCEID
		.WORD	STORE
		.WORD	ZERO
		.WORD	TO_IN
		.WORD	STORE
		.WORD	LENGTH
		.WORD	STORE
		.WORD	BUFFER
		.WORD	STORE
		.WORD	INTERPRET
		.WORD	RESTORE_INPUT
		.WORD	DROP
		.WORD	EXIT

; INTERPRET ( -- )
;
;
;   BEGIN
;   BL WORD DUP C@ WHILE	-- textadr
;	FIND			-- a 0/1/-1
;	?DUP IF			-- xt 1/-1
;	    1+ STATE @ 0= OR	immed or interp?
;	    IF EXECUTE ELSE , THEN
;	ELSE			-- textadr
;	    ?NUMBER
;	    IF STATE @
;		IF POSTPONE LITERAL THEN     converted ok
;	    ELSE COUNT TYPE 3F EMIT CR ABORT  err
;	    THEN
;	THEN
;   REPEAT DROP ;

		WORD	"INTERPRET",NORMAL
INTERPRET:	FORTH
INTERPRET_1:	.WORD	BL
		.WORD	WORD
		.WORD	DUP
		.WORD	C_FETCH
		.WORD	QUERY_BRANCH,INTERPRET_7
		.WORD	FIND
		.WORD	QUERY_DUP
		.WORD	QUERY_BRANCH,INTERPRET_4
		.WORD	ONE_PLUS
		.WORD	STATE
		.WORD	FETCH
		.WORD	ZERO_EQUAL
		.WORD	OR
		.WORD	QUERY_BRANCH,INTERPRET_2
		.WORD	EXECUTE
		.WORD	BRANCH,INTERPRET_3
INTERPRET_2:	.WORD	COMMA
INTERPRET_3:	.WORD	BRANCH,INTERPRET_6
INTERPRET_4:	.WORD	QUERY_NUMBER
		.WORD	QUERY_BRANCH,INTERPRET_5
		.WORD	STATE
		.WORD	FETCH
		.WORD	QUERY_BRANCH,INTERPRET_6
		.WORD	LITERAL
		.WORD	BRANCH,INTERPRET_6
INTERPRET_5:	.WORD	COUNT
		.WORD	TYPE
		.WORD	DO_LITERAL,X'3f
		.WORD	EMIT
		.WORD	CR
		.WORD	ABORT
INTERPRET_6	.WORD	BRANCH,INTERPRET_1
INTERPRET_7:	.WORD	DROP
		.WORD	EXIT

; FIND ( c-addr -- c-addr 0 | xt 1 | xt -1 )
;
; Find the definition named in the counted string at c-addr. If the definition
; is not found, return c-addr and zero. If the definition is found, return its
; execution token xt. If the definition is immediate, also return one (1),
; otherwise also return minus-one (-1). For a given string, the values returned
; by FIND while compiling may differ from those returned while not compiling.
;
; In this implementation it is defined as:
;
;   LATEST @ BEGIN	       -- a nfa
;	2DUP OVER C@ CHAR+     -- a nfa a nfa n+1
;	S=		       -- a nfa f
;	DUP IF
;	    DROP
;	    NFA>LFA @ DUP      -- a link link
;	THEN
;   0= UNTIL		       -- a nfa	 OR  a 0
;   DUP IF
;	NIP DUP NFA>CFA	       -- nfa xt
;	SWAP IMMED?	       -- xt iflag
;	0= 1 OR		       -- xt 1/-1
;   THEN ;

		WORD	"FIND",NORMAL
FIND:		FORTH
		.WORD	LATEST
		.WORD	FETCH
FIND1:		.WORD	TWO_DUP
		.WORD	OVER
		.WORD	C_FETCH
		.WORD	CHAR_PLUS
		.WORD	S_EQUAL
		.WORD	DUP
		.WORD	QUERY_BRANCH,FIND2
		.WORD	DROP
		.WORD	NFA_TO_LFA
		.WORD	FETCH
		.WORD	DUP
FIND2:		.WORD	ZERO_EQUAL
		.WORD	QUERY_BRANCH,FIND1
		.WORD	DUP
		.WORD	QUERY_BRANCH,FIND3
		.WORD	NIP
		.WORD	DUP
		.WORD	NFA_TO_CFA
		.WORD	SWAP
		.WORD	IMMED_QUERY
		.WORD	ZERO_EQUAL
		.WORD	DO_LITERAL,1
		.WORD	OR
FIND3:		.WORD	EXIT

; IMMED? ( nfa -- f )

IMMED_QUERY:	FORTH
		.WORD	ONE_MINUS
		.WORD	C_FETCH
		.WORD	EXIT

; NFA>CFA ( nfa -- cfa )

NFA_TO_CFA:	FORTH
		.WORD	COUNT
		.WORD	PLUS
		.WORD	EXIT

; NFA>LFA ( nfa -- lfa )

NFA_TO_LFA:	FORTH
		.WORD	DO_LITERAL,3
		.WORD	MINUS
		.WORD	EXIT

; REFILL ( -- flag )
;
; Attempt to fill the input buffer from the input source, returning a true flag
; if successful.
;
; When the input source is the user input device, attempt to receive input into
; the terminal input buffer. If successful, make the result the input buffer,
; set >IN to zero, and return true. Receipt of a line containing no characters
; is considered successful. If there is no input available from the current
; input source, return false.
;
; When the input source is a string from EVALUATE, return false and perform no
; other action.
;
; In this implementation it is defined as:
;
;   SOURCE-ID 0= IF
;     TIB DUP #TIB @ ACCEPT SPACE
;     LENGTH ! BUFFER !
;     0 >IN ! TRUE EXIT
;   THEN
;   FALSE

		WORD	"REFILL",NORMAL
REFILL:		FORTH
		.WORD	SOURCE_ID
		.WORD	ZERO_EQUAL
		.WORD	QUERY_BRANCH,REFILL_1
		.WORD	TIB
		.WORD	DUP
		.WORD	HASH_TIB
		.WORD	FETCH
		.WORD	ACCEPT
		.WORD	SPACE
		.WORD	LENGTH
		.WORD	STORE
		.WORD	BUFFER
		.WORD	STORE
		.WORD	ZERO
		.WORD	TO_IN
		.WORD	STORE
		.WORD	TRUE
		.WORD	EXIT
REFILL_1:	.WORD	FALSE
		.WORD	EXIT

; RESTORE-INPUT ( xn ... x1 n -- flag )
;
; Attempt to restore the input source specification to the state described by
; x1 through xn. flag is true if the input source specification cannot be so
; restored.
;
; An ambiguous condition exists if the input source represented by the
; arguments is not the same as the current input source.
;
; In this implementation it is defined as:
;
;   >IN ! (LENGTH) ! BUFFER !
;   SOURCEID !
;   TRUE

		WORD	"RESTORE-INPUT",NORMAL
RESTORE_INPUT	FORTH
		.WORD	TO_IN
		.WORD	STORE
		.WORD	LENGTH
		.WORD	STORE
		.WORD	BUFFER
		.WORD	STORE
		.WORD	SOURCEID
		.WORD	STORE
		.WORD	TRUE
		.WORD	EXIT

; S= ( c-addr1 caddr2 u -- n)
;
; Misnamed, more like C's strncmp. Note that counted length bytes are compared!

S_EQUAL:	NATIVE
	.IF 0
;		 phy
;		 ldx	 <1			 ; Fetch maximum length
;		 beq	 S_EQUAL_3
;		 ldy	 #0
;		 short_a
;S_EQUAL_1:
;		 lda	 (5),y			 ; Compare bytes
;		 cmp	 (3),y
;		 bne	 S_EQUAL_2
;		 iny
;		 dex				 ; End of strings?
;		 bne	 S_EQUAL_1		 ; No
;		 bra	 S_EQUAL_3		 ; Yes. must be the same
;S_EQUAL_2:
;		 ldx	 #$ffff			 ; Difference found
;S_EQUAL_3:
 ;		 long_a
;		 tdc				 ; Clean up the stack
;		 inc	 a
;		 inc	 a
;		 inc	 a
;		 inc	 a
;		 tcd
;		 stx	 <1			 ; Save the flag
;		 ply
;		 CONTINUE
	.ENDIF
		XPPC	R2		; And continue

; SAVE-INPUT ( -- xn ... x1 n )
;
; x1 through xn describe the current state of the input source specification
; for later use by RESTORE-INPUT.

		WORD	"SAVE-INPUT",NORMAL
SAVE_INPUT:	FORTH
		.WORD	SOURCEID
		.WORD	FETCH
		.WORD	BUFFER
		.WORD	FETCH
		.WORD	LENGTH
		.WORD	FETCH
		.WORD	TO_IN
		.WORD	FETCH
		.WORD	EXIT

; SCAN ( c-addr n c == c-addr' n' )

SCAN:		NATIVE
	.IF 0
;SCAN_1:
;		 lda	 <3			 ; Any data left to scan?
;		 beq	 SCAN_2			 ; No.
;		 lda	 <1			 ; Fetch and compare with scan
;		 short_a
;		 cmp	 (5)
;		 long_a
;		 beq	 SCAN_2
;		 inc	 <5
;		 dec	 <3
;		 bra	 SCAN_1
;SCAN_2:
;		 jmp	 DROP			 ; Drop the character
	.ENDIF
		XPPC	R2		; And continue

; SKIP ( c-addr n c == c-addr' n' )

SKIP:		NATIVE
	.IF 0
;SKIP_1:	 lda	 <3			 ; Any data left to skip over?
;		 beq	 SKIP_2			 ; No.
;		 lda	 <1			 ; Fetch and compare with skip
;		 short_a
;		 cmp	 (5)
;		 long_a
;		 bne	 SKIP_2			 ; Cannot be skipped
;		 inc	 <5			 ; Bump data address
;		 dec	 <3			 ; and update length
;		 bra	 SKIP_1			 ; And repeat
;SKIP_2:
;		 jmp	 DROP			 ; Drop the character
	.ENDIF
		XPPC	R2		; And continue

; SOURCE ( -- c-addr u )
;
; c-addr is the address of, and u is the number of characters in, the input
; buffer.
;
; In this implementation it is defined as
;
;   BUFFER @ LENGTH @

		WORD	"SOURCE",NORMAL
SOURCE:		FORTH
		.WORD	BUFFER
		.WORD	FETCH
		.WORD	LENGTH
		.WORD	FETCH
		.WORD	EXIT

; SOURCE-ID ( -- 0 | -1 )
;
; Identifies the input source: -1 if string (via EVALUATE), 0 if user input
; device.

		WORD	"SOURCE-ID",NORMAL
SOURCE_ID:	FORTH
		.WORD	SOURCEID
		.WORD	FETCH
		.WORD	EXIT

; WORD ( char “<chars>ccc<char>” -- c-addr )
;
; Skip leading delimiters. Parse characters ccc delimited by char. An
; ambiguous condition exists if the length of the parsed string is greater
; than the implementation-defined length of a counted string.
;
; c-addr is the address of a transient region containing the parsed word as
; a counted string. If the parse area was empty or contained no characters
; other than the delimiter, the resulting string has a zero length. A space,
; not included in the length, follows the string. A program may replace
; characters within the string.
;
; In this implementation it is defined as:
;
;   DUP	 SOURCE >IN @ /STRING	-- c c adr n
;   DUP >R   ROT SKIP		-- c adr' n'
;   OVER >R  ROT SCAN		-- adr" n"
;   DUP IF CHAR- THEN	     skip trailing delim.
;   R> R> ROT -	  >IN +!	update >IN offset
;   TUCK -			-- adr' N
;   HERE >counted		--
;   HERE			-- a
;   BL OVER COUNT + C! ;    append trailing blank

		WORD	"WORD",NORMAL
WORD:		FORTH
		.WORD	DUP
		.WORD	SOURCE
		.WORD	TO_IN
		.WORD	FETCH
		.WORD	SLASH_STRING
		.WORD	DUP
		.WORD	TO_R
		.WORD	ROT
		.WORD	SKIP
		.WORD	OVER
		.WORD	TO_R
		.WORD	ROT
		.WORD	SCAN
		.WORD	DUP
		.WORD	QUERY_BRANCH,WORD_1
		.WORD	CHAR_MINUS
WORD_1:		.WORD	R_FROM
		.WORD	R_FROM
		.WORD	ROT
		.WORD	MINUS
		.WORD	TO_IN
		.WORD	PLUS_STORE
		.WORD	TUCK
		.WORD	MINUS
		.WORD	HERE
		.WORD	TO_COUNTED
		.WORD	HERE
		.WORD	BL
		.WORD	OVER
		.WORD	COUNT
		.WORD	PLUS
		.WORD	C_STORE
		.WORD	EXIT

;===============================================================================
; String Words
;-------------------------------------------------------------------------------

; -TRAILING ( c-addr u1 -- c-addr u2 )
;
; If u1 is greater than zero, u2 is equal to u1 less the number of spaces at
; the end of the character string specified by c-addr u1. If u1 is zero or the
; entire string consists of spaces, u2 is zero.

		WORD	"-TRAILING",NORMAL
DASH_TRAILING:	NATIVE
	.IF 0
;		 phy				 ; Save IP
;		 ldy	 <1			 ; Is u1 > 0?
;		 beq	 DASH_TRAIL_3		 ; No
;		 short_a
;		 dey				 ; Convert to offset
;DASH_TRAIL_1:	 lda	 (3),y			 ; Space character at end?
;		 cmp	 #' '
;		 bne	 DASH_TRAIL_2		 ; No
;		 dey				 ; More characters to check?
;		 bpl	 DASH_TRAIL_1		 ; Yes
;DASH_TRAIL_2:	 long_a
;		 iny				 ; Convert to length
;DASH_TRAIL_3:	 sty	 <1			 ; Update
;		 ply				 ; Restore IP
;		 CONTINUE			 ; Done
	.ENDIF
		XPPC	R2

; /STRING ( c-addr1 u1 n -- c-addr2 u2 )
;
; Adjust the character string at c-addr1 by n characters. The resulting
; character string, specified by c-addr2 u2, begins at c-addr1 plus n;
; characters and is u1 minus n characters long.
;
; In this implementation it is defined as:
;
;   ROT OVER + ROT ROT -

		WORD	"/STRING",NORMAL
SLASH_STRING:	FORTH
		.WORD	ROT
		.WORD	OVER
		.WORD	PLUS
		.WORD	ROT
		.WORD	ROT
		.WORD	MINUS
		.WORD	EXIT

; BLANK ( c-addr u -- )
;
; If u is greater than zero, store the character value for space in u
; consecutive character positions beginning at c-addr.
;
; In this implementation it is defined as
;
;   ?DUP IF OVER + SWAP DO BL I C! LOOP ELSE DROP THEN

		WORD	"BLANK",NORMAL
BLANK:		FORTH
		.WORD	QUERY_DUP
		.WORD	QUERY_BRANCH,BLANK_2
		.WORD	OVER
		.WORD	PLUS
		.WORD	SWAP
		.WORD	DO_DO
BLANK_1:	.WORD	BL
		.WORD	I
		.WORD	C_STORE
		.WORD	DO_LOOP,BLANK_1
		.WORD	EXIT
BLANK_2:	.WORD	DROP
		.WORD	EXIT

; CMOVE ( c-addr1 c-addr2 u -- )
;
; If u is greater than zero, copy u consecutive characters from the data space
; starting at c-addr1 to that starting at c-addr2, proceeding character-by-
; character from lower addresses to higher addresses.

		WORD	"CMOVE",NORMAL
CMOVE:		NATIVE
	.IF 0
;		 phy
;		 ldx	 <1			 ; Any characters to move?
;		 beq	 CMOVE_2		 ; No
;		 ldy	 #0
;		 short_a
;CMOVE_1:					 ; Transfer a byte
;		 lda	 (5),y
;		 sta	 (3),y
;		 iny
;		 dex				 ; Decrement count
;		 bne	 CMOVE_1		 ; .. and repeat until done
;		 long_a;
;CMOVE_2:
;		 tdc				 ; Clean up the stack
;		 clc
;		 adc	 #6
;		 tcd
;		 ply
;		 CONTINUE			 ; Done
	.ENDIF
		XPPC	R2

; CMOVE> ( c-addr1 c-addr2 u -- )
;
; If u is greater than zero, copy u consecutive characters from the data space
; starting at c-addr1 to that starting at c-addr2, proceeding character-by-
; character from higher addresses to lower addresses.

		WORD	"CMOVE>",NORMAL
CMOVE_GREATER:	NATIVE
	.IF 0
;		 phy
;		 ldx	 <1			 ; Any characters to move?
;		 beq	 CMOVE_GT_2		 ; No.
;		 ldy	 <1
;		 short_a
;CMOVE_GT_1:
;		 dey				 ; Transfer a byte
;		 lda	 (5),y
;		 sta	 (3),y
;		 dex				 ; Decrement length
;		 bne	 CMOVE_GT_1		 ; .. and repeat until done
;		 long_a
;CMOVE_GT_2:
;		 tdc				 ; Clean up the stack
;		 clc
;		 adc	 #6;
;		 tcd
;		 ply
;		 CONTINUE			 ; Done
	.ENDIF
		XPPC	R2

; COMPARE ( c-addr1 u1 c-addr2 u2 -- n )
;
; Compare the string specified by c-addr1 u1 to the string specified by c-addr2
; u2. The strings are compared, beginning at the given addresses, character by
; character, up to the length of the shorter string or until a difference is
; found. If the two strings are identical, n is zero. If the two strings are
; identical up to the length of the shorter string, n is minus-one (-1) if u1
; is less than u2 and one (1) otherwise. If the two strings are not identical
; up to the length of the shorter string, n is minus-one (-1) if the first
; non-matching character in the string specified by c-addr1 u1 has a lesser
; numeric value than the corresponding character in the string specified by
; c-addr2 u2 and one (1) otherwise.

		WORD	"COMPARE",NORMAL
COMPARE:	NATIVE
	.IF 0
;		 lda	 <1			 ; Both string lengths zero?
;		 ora	 <5
;		 beq	 COMPARE_X		 ; Yes, must be equal;
;
;		 lda	 <1			 ; Second string length zero?
;		 beq	 COMPARE_P		 ; Yes, must be shorter
;		 lda	 <5			 ; First string length zero?
;		 beq	 COMPARE_N		 ; Yes, must be shorter
;		 short_a
;		 lda	 (7)			 ; Compare next characters
;		 cmp	 (3)
;		 long_a
;		bcc	COMPARE_N
;		 bne	 COMPARE_P

;		 inc	 <3			 ; Bump string pointers
;		 inc	 <7
;		 dec	 <1			 ; And reduce lengths
;		 dec	 <5
;		 bra	 COMPARE

;COMPARE_P:	 lda	 #1
;		 bra	 COMPARE_X
;COMPARE_N:	 lda	 #-1;

;COMPARE_X:	 sta	 <7			 ; Save the result
;		 tdc
;		 clc
;		 adc	 #6
;		 tcd
;		 CONTINUE			 ; Done
	.ENDIF
		XPPC	R2
		
; COUNT ( c-addr1 -- c-addr2 u )
;
; Return the character string specification for the counted string stored at
; c-addr1. c-addr2 is the address of the first character after c-addr1. u is
; the contents of the character at c-addr1, which is the length in characters
; of the string at c-addr2.
;
; In this implementation it is defined as
;
;   DUP CHAR+ SWAP C@

		WORD	"COUNT",NORMAL
COUNT:		FORTH
		.WORD	DUP
		.WORD	CHAR_PLUS
		.WORD	SWAP
		.WORD	C_FETCH
		.WORD	EXIT

; SEARCH ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
;
; Search the string specified by c-addr1 u1 for the string specified by c-addr2
; u2. If flag is true, a match was found at c-addr3 with u3 characters
; remaining. If flag is false there was no match and c-addr3 is c-addr1 and u3
; is u1.

		WORD	"SEARCH",NORMAL
SEARCH:		FORTH
; TODO
		.WORD	EXIT

;===============================================================================
; Compiling Words
;-------------------------------------------------------------------------------

; ( ( -- )
;
; Parse ccc delimited by ) (right parenthesis). ( is an immediate word.
;
; The number of characters in ccc may be zero to the number of characters in the
; parse area.
;
; In this implementation it is defined as:
;
;  [ HEX ] 29 WORD DROP ; IMMEDIATE

		WORD	"(",IMMEDIATE
LEFT_PAREN:	FORTH
		.WORD	DO_LITERAL,')'
		.WORD	WORD
		.WORD	DROP
		.WORD	EXIT

; .( ( “ccc<paren>” -- )
;
; Parse and display ccc delimited by ) (right parenthesis). .( is an immediate
; word.

		WORD	".(",IMMEDIATE
DOT_PAREN:	FORTH
		.WORD	DO_LITERAL,')'
		.WORD	WORD
		.WORD	COUNT
		.WORD	TYPE
		.WORD	EXIT

; ." ( “ccc<quote>” -- )
;
; Parse ccc delimited by " (double-quote). Append the run-time semantics given
; below to the current definition.

		WORD	".\"",IMMEDIATE
DOT_QUOTE:	FORTH
		.WORD	S_QUOTE
		.WORD	DO_LITERAL,TYPE
		.WORD	COMMA
		.WORD	EXIT

; +LOOP ( -- )

		WORD	"+LOOP",IMMEDIATE
PLUS_LOOP:	FORTH
		.WORD	DO_LITERAL,DO_PLUS_LOOP
		.WORD	COMMA
		.WORD	COMMA
		.WORD	QUERY_DUP
		.WORD	QUERY_BRANCH,PLUS_LOOP_1
		.WORD	HERE
		.WORD	SWAP
		.WORD	STORE
PLUS_LOOP_1:	.WORD	EXIT

DO_PLUS_LOOP:	NATIVE
	.IF 0
		ldx	<1			; Fetch increment
		tdc				; And drop
		inc	a
		inc	a
		tcd
		clc				; Add to loop counter
		txa
		adc	1,s
		sta	1,s
		cmp	3,s			; Reached limit?
		bcs	DO_PLOOP_END		; Yes
		lda	!0,y			; No, branch back to start
		tay
		CONTINUE			; Done

DO_PLOOP_END:	iny				; Skip over address
		iny
		pla				; Drop loop variables
		pla
		CONTINUE			; Done
	.ENDIF
		XPPC	R2

; ' ( -- xt )
;
; Skip leading space delimiters. Parse name delimited by a space. Find name and
; return xt, the execution token for name. An ambiguous condition exists if name
; is not found.
;
; In this implementation it is defined as:
;
;   BL WORD FIND 0= IF ." ?" ABORT THEN

		WORD	"'",NORMAL
TICK:		FORTH
		.WORD	BL
		.WORD	WORD
		.WORD	FIND
		.WORD	ZERO_EQUAL
		.WORD	QUERY_BRANCH,TICK_1
		.WORD	DO_S_QUOTE
		.BYTE	1,"?"
		.WORD	ABORT
TICK_1:		.WORD	EXIT

; : ( -- )

		WORD	":",NORMAL
COLON:		FORTH
		.WORD	CREATE
		.WORD	DO_LITERAL,DO_COLON
		.WORD	BUILD
		.WORD	RIGHT_BRACKET
		.WORD	EXIT

DO_COLON:
		DLD	RP+0(MA)	; Create a cell on the return stack
		DLD	RP+0(MA)	; .. and load the pointer
		XPAL	R2
		LD	RP+1(MA)
		XPAH	R2
		LD	IP+0(MA)	; Push the old IP
		ST	0(R2)
		LD	IP+1(MA)
		ST	1(R2)
		CCL			; Calculate new IP from WA
		XPAL	R1
		ADI	2
		ST	IP+0(MA)
		XPAH	R1
		ADI	0
		ST	IP+1(MA)

NEXT:
		LD	IP+0(MA)	; Load the instruction pointer
		XPAL	R2
		LD	IP+1(MA)
		XPAH	R2

		ILD	IP+0(MA)	; Bump the IP
		JNZ	.SKIPL
		ILD	IP+1(MA)
.SKIPL
		ILD	IP+0(MA)
		JNZ	.SKIPH
		ILD	IP+1(MA)
.SKIPH

		LD	0(R2)		; Fetch the next word address
		XPAL	R1
		LD	1(R2)
		XPAH	R1

		LD	0(R1)		; Fetch the code address
		XPAL	R2
		LD	1(R1)
		XPAH	R2

		XPPC	R2		; Execute the word
		JMP	NEXT		; And repeat

; :NONAME ( -- xt )

		WORD	":NONAME",NORMAL
NONAME:		FORTH
		.WORD	HERE
		.WORD	DO_LITERAL,DO_COLON
		.WORD	BUILD
		.WORD	RIGHT_BRACKET
		.WORD	EXIT

; ; ( -- )

		WORD	";",IMMEDIATE
SEMICOLON:	FORTH
		.WORD	DO_LITERAL,EXIT
		.WORD	COMMA
		.WORD	LEFT_BRACKET
		.WORD	EXIT

; ?DO ( -- jump orig )

		WORD	"?DO",IMMEDIATE
QUERY_DO:	FORTH
		.WORD	DO_LITERAL,QUERY_DO_DO
		.WORD	COMMA
		.WORD	HERE
		.WORD	ZERO
		.WORD	COMMA
		.WORD	HERE
		.WORD	EXIT

QUERY_DO_DO:	NATIVE
	.IF 0
		lda	<1			; Are the start and limit
		eor	<3			; .. the same?
		beq	QUERY_DO_DO_1
		iny				; No, Skip over jump address
		iny
		jmp	DO_DO			; And start a normal loop

QUERY_DO_DO_1:	tdc				; Drop the loop parameters
		inc	a
		inc	a
		inc	a
		inc	a
		tcd
		jmp	BRANCH			; And skip over loop
	.ENDIF
		XPPC	R2

; 2CONSTANT ( x “<spaces>name” -- )
;
; Skip leading space delimiters. Parse name delimited by a space. Create a
; definition for name with the execution semantics defined below.

		WORD	"2CONSTANT",NORMAL
TWO_CONSTANT:	FORTH
		.WORD	CREATE
		.WORD	DO_LITERAL,DO_TWO_CONSTANT
		.WORD	BUILD
		.WORD	COMMA
		.WORD	COMMA
		.WORD	EXIT

DO_TWO_CONSTANT: NATIVE
	.IF 0
		plx				; Get return address
		tdc				; Create space on stack
		dec	a
		dec	a
		dec	a
		dec	a
		tcd
		lda	!1,x			; Transfer the value
		sta	<1
		lda	!3,x
		sta	<3
		CONTINUE			; Done
	.ENDIF
		XPPC	R2

; 2LITERAL

		WORD	"2LITERAL",IMMEDIATE
TWO_LITERAL:	FORTH
		.WORD	DO_LITERAL,DO_TWO_LITERAL
		.WORD	COMMA
		.WORD	COMMA
		.WORD	COMMA
		.WORD	EXIT

DO_TWO_LITERAL:	NATIVE
	.IF	0
		tdc				; Make room on stack
		dec	a
		dec	a
		dec	a
		dec	a
		tcd
		lda	!0,y			; Fetch constant from IP
		sta	<1
		lda	!2,y
		sta	<3
		iny				; Bump IP
		iny
		iny
		iny
		CONTINUE			; Done
	.ENDIF
		XPPC	R2

; 2VARIABLE

		WORD	"2VARIABLE",IMMEDIATE
TWO_VARIABLE:	FORTH
		.WORD	CREATE
		.WORD	DO_LITERAL,DO_VARIABLE
		.WORD	BUILD
		.WORD	DO_LITERAL,2
		.WORD	CELLS
		.WORD	ALLOT
		.WORD	EXIT

; ABORT" ( -- )

		WORD	"ABORT\"",IMMEDIATE
ABORT_QUOTE:	FORTH
		.WORD	S_QUOTE
		.WORD	DO_LITERAL,QUERY_ABORT
		.WORD	COMMA
		.WORD	EXIT

; AGAIN ( orig -- )

		WORD	"AGAIN",IMMEDIATE
AGAIN:		FORTH
		.WORD	DO_LITERAL,BRANCH
		.WORD	COMMA
		.WORD	COMMA
		.WORD	EXIT

; BEGIN ( -- orig )

		WORD	"BEGIN",IMMEDIATE
BEGIN:		FORTH
		.WORD	HERE
		.WORD	EXIT

; CHAR ( -- char )
;
;   BL WORD 1+ C@

		WORD	"CHAR",NORMAL
CHAR:		FORTH
		.WORD	BL
		.WORD	WORD
		.WORD	ONE_PLUS
		.WORD	C_FETCH
		.WORD	EXIT

; CONSTANT ( x “<spaces>name” -- )
;
; Skip leading space delimiters. Parse name delimited by a space. Create a
; definition for name with the execution semantics defined below.

		WORD	"CONSTANT",NORMAL
CONSTANT:	FORTH
		.WORD	CREATE
		.WORD	DO_LITERAL,DO_CONSTANT
		.WORD	BUILD
		.WORD	COMMA
		.WORD	EXIT

DO_CONSTANT:	NATIVE

		XPPC	R2

; DO ( -- 0 orig )

		WORD	"DO",IMMEDIATE
DO:		FORTH
		.WORD	DO_LITERAL,DO_DO
		.WORD	COMMA
		.WORD	ZERO
		.WORD	HERE
		.WORD	EXIT

DO_DO:		NATIVE
	.IF	0
		lda	<3
		pha
		lda	<1
		pha
		tdc
		inc	a
		inc	a
		inc	a
		inc	a
		tcd
		CONTINUE
	.ENDIF
		XPPC	R2

; ELSE ( jump -- jump' )

		WORD	"ELSE",IMMEDIATE
ELSE:		FORTH
		.WORD	DO_LITERAL,BRANCH
		.WORD	COMMA
		.WORD	HERE
		.WORD	ZERO
		.WORD	COMMA
		.WORD	HERE
		.WORD	SWAP
		.WORD	STORE
		.WORD	EXIT

BRANCH:		NATIVE
		LD	2(R1)		; Fetch the new IP value
		ST	IP+0(MA)
		LD	3(R1)
		ST	IP+1(MA)
		XPPC	R2		; And continue

; IF ( -- jump )

		WORD	"IF",IMMEDIATE
IF:		FORTH
		.WORD	DO_LITERAL,QUERY_BRANCH
		.WORD	COMMA
		.WORD	HERE
		.WORD	ZERO
		.WORD	COMMA
		.WORD	EXIT

QUERY_BRANCH:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R2
		LD	SP+1(MA)
		XPAH	R2
		LD	0(R2)		; Test the top cell value
		OR	1(R2)
		XAE			; .. and save the result
		ILD	SP+0(MA)	; Drop the top cell
		ILD	SP+0(MA)
		LDI	LO(NEXT-1)	; Restore the NEXT pointer
		XPAL	R2
		LDI	HI(NEXT-1)
		XPAH	R2
		LDE
		JNZ	.CONTINUE

		LD	2(R1)		; Fetch the new IP value
		ST	IP+0(MA)
		LD	3(R1)
		ST	IP+1(MA)
		XPPC	R2		; And continue

.CONTINUE	ILD	IP+0(MA)	; Increment IP over link
		JNZ	.SKIP1
		ILD	IP+1(MA)
.SKIP1		ILD	IP+0(MA)
		JNZ	.SKIP2
		ILD	IP+1(MA)
.SKIP2		XPPC	R2		; And continue

; IMMEDIATE ( -- )

		WORD	"IMMEDIATE",IMMEDIATE
IMMED:		FORTH
		.WORD	DO_LITERAL,IMMEDIATE
		.WORD	LATEST
		.WORD	FETCH
		.WORD	ONE_MINUS
		.WORD	C_STORE
		.WORD	EXIT

; LITERAL ( x -- )
;
; Append the run-time semantics given below to the current definition.

		WORD	"LITERAL",IMMEDIATE
LITERAL:	FORTH
		.WORD	DO_LITERAL,DO_LITERAL
		.WORD	COMMA
		.WORD	COMMA
		.WORD	EXIT

DO_LITERAL:	NATIVE

		XPPC	R2		; And continue


; LOOP ( jump orig -- )

		WORD	"LOOP",IMMEDIATE
LOOP:		FORTH
		.WORD	DO_LITERAL,DO_LOOP
		.WORD	COMMA
		.WORD	COMMA
		.WORD	QUERY_DUP
		.WORD	QUERY_BRANCH,LOOP_1
		.WORD	HERE
		.WORD	SWAP
		.WORD	STORE
LOOP_1:		.WORD	EXIT

; (LOOP)

DO_LOOP:	NATIVE
	.IF	0
		lda	1,s			; Add one to loop counter
		inc	a
		sta	1,s
		cmp	3,s			; Reached limit?
		bcs	DO_LOOP_END		; Yes
		lda	!0,y			; No, branch back to start
		tay
		CONTINUE			; Done

DO_LOOP_END:	iny				; Skip over address
		iny
		pla				; Drop loop variables
		pla
		CONTINUE			; Done
	.ENDIF
	XPPC	R2

; POSTPONE

;   BL WORD FIND
;   DUP 0= ABORT" ?"
;   0< IF   -- xt	non immed: add code to current
;			def'n to compile xt later.
;	['] LIT ,XT  ,	add "LIT,xt,COMMAXT"
;	['] ,XT ,XT	to current definition
;   ELSE  ,XT	   immed: compile into cur. def'n
;   THEN ; IMMEDIATE

		WORD	"POSTPONE",IMMEDIATE
POSTPONE:	FORTH
		.WORD	BL
		.WORD	WORD
		.WORD	FIND
		.WORD	DUP
		.WORD	ZERO_EQUAL
		.WORD	DO_S_QUOTE
		.BYTE	1,"?"
		.WORD	QUERY_ABORT
		.WORD	ZERO_LESS
		.WORD	QUERY_BRANCH,POSTPONE_1
		.WORD	DO_LITERAL,DO_LITERAL
		.WORD	COMMA
		.WORD	COMMA
		.WORD	BRANCH,POSTPONE_2
POSTPONE_1:	.WORD	COMMA
POSTPONE_2:	.WORD	EXIT

; RECURSE ( -- )

		WORD	"RECURSE",IMMEDIATE
RECURSE:	FORTH
		.WORD	LATEST
		.WORD	FETCH
		.WORD	NFA_TO_CFA
		.WORD	COMMA
		.WORD	EXIT

; REPEAT ( orig jump -- )

		WORD	"REPEAT",IMMEDIATE
REPEAT:		FORTH
		.WORD	SWAP
		.WORD	DO_LITERAL,BRANCH
		.WORD	COMMA
		.WORD	COMMA
		.WORD	HERE
		.WORD	SWAP
		.WORD	STORE
		.WORD	EXIT

; S"

		WORD	"S\"",IMMEDIATE
S_QUOTE:	FORTH
		.WORD	DO_LITERAL,DO_S_QUOTE
		.WORD	COMMA
		.WORD	DO_LITERAL,'"'
		.WORD	WORD
		.WORD	C_FETCH
		.WORD	ONE_PLUS
		.WORD	ALIGNED
		.WORD	ALLOT
		.WORD	EXIT

; (S") ( -- c-addr u )

DO_S_QUOTE:
		FORTH
		.WORD	R_FROM
		.WORD	COUNT
		.WORD	TWO_DUP
		.WORD	PLUS
		.WORD	ALIGNED
		.WORD	TO_R
		.WORD	EXIT

; THEN ( orig -- )

		WORD	"THEN",IMMEDIATE
THEN:		FORTH
		.WORD	HERE
		.WORD	SWAP
		.WORD	STORE
		.WORD	EXIT

; UNTIL ( orig -- )

		WORD	"UNTIL",IMMEDIATE
UNTIL:		FORTH
		.WORD	DO_LITERAL,QUERY_BRANCH
		.WORD	COMMA
		.WORD	COMMA
		.WORD	EXIT

; USER

		WORD	"USER",NORMAL
USER:		FORTH
		.WORD	CREATE
		.WORD	DO_LITERAL,DO_USER
		.WORD	BUILD
		.WORD	COMMA
		.WORD	EXIT

DO_USER:
	.IF	0
		tdc
		dec	a			; Push on data stack
		dec	a
		tcd
		plx
		clc
		lda	!1,x
		adc	#USER_AREA
		sta	<1
		CONTINUE			; Done
	.ENDIF
		XPPC	R2

; VARIABLE ( “<spaces>name” -- )
;
; Skip leading space delimiters. Parse name delimited by a space. Create a
; definition for name with the execution semantics defined below. Reserve one
; cell of data space at an aligned address.

		WORD	"VARIABLE",NORMAL
VARIABLE:	FORTH
		.WORD	CREATE
		.WORD	DO_LITERAL,DO_VARIABLE
		.WORD	BUILD
		.WORD	DO_LITERAL,1
		.WORD	CELLS
		.WORD	ALLOT
		.WORD	EXIT

DO_VARIABLE:
	.IF	0
		tdc
		dec	a
		dec	a
		tcd
		pla
		inc	a
		sta	<1
		CONTINUE
	.ENDIF
		XPPC	R2

; WHILE ( orig -- orig jump )

		WORD	"WHILE",IMMEDIATE
WHILE:		FORTH
		.WORD	DO_LITERAL,QUERY_BRANCH
		.WORD	COMMA
		.WORD	HERE
		.WORD	ZERO
		.WORD	COMMA
		.WORD	EXIT

; WORDS ( -- )
;
;   LATEST @ BEGIN
;	DUP COUNT TYPE SPACE
;	NFA>LFA @
;   DUP 0= UNTIL
;   DROP ;

		WORD	"WORDS",NORMAL
WORDS:		FORTH
		.WORD	LATEST
		.WORD	FETCH
WORDS_1:	.WORD	DUP
		.WORD	COUNT
		.WORD	TYPE
		.WORD	SPACE
		.WORD	NFA_TO_LFA
		.WORD	FETCH
		.WORD	DUP
		.WORD	ZERO_EQUAL
		.WORD	QUERY_BRANCH,WORDS_1
		.WORD	DROP
		.WORD	EXIT

; [
;
; In this implementation it is defined as
;
;   0 STATE !

		WORD	"[",IMMEDIATE
LEFT_BRACKET:	FORTH
		.WORD	ZERO
		.WORD	STATE
		.WORD	STORE
		.WORD	EXIT

; [']

		WORD	"[']",IMMEDIATE
BRACKET_TICK:	FORTH
		.WORD	TICK
		.WORD	DO_LITERAL,DO_LITERAL
		.WORD	COMMA
		.WORD	COMMA
		.WORD	EXIT

; [CHAR]
;
;   CHAR ['] LIT ,XT  , ; IMMEDIATE

		WORD	"[CHAR]",IMMEDIATE
BRACKET_CHAR:	FORTH
		.WORD	CHAR
		.WORD	DO_LITERAL,DO_LITERAL
		.WORD	COMMA
		.WORD	COMMA
		.WORD	EXIT

; \ ( -- )
;
; Parse and discard the remainder of the parse area. \ is an immediate word.
;
; In this implementation it is defined as
;
;   1 WORD DROP

		WORD	"\\",IMMEDIATE
BACKSLASH:	FORTH
		.WORD	DO_LITERAL,1
		.WORD	WORD
		.WORD	DROP
		.WORD	EXIT

; ]
;
; In this implementation it is defined as
;
;   -1 STATE !

		WORD	"]",NORMAL
RIGHT_BRACKET:	FORTH
		.WORD	DO_LITERAL,-1
		.WORD	STATE
		.WORD	STORE
		.WORD	EXIT

;===============================================================================
; I/O Operations
;-------------------------------------------------------------------------------

; CR ( -- )
;
; Cause subsequent output to appear at the beginning of the next line.
;
; In this implementation it is defined as
;
;   13 EMIT 10 EMIT

		WORD	"CR",NORMAL
CR:		FORTH
		.WORD	DO_LITERAL,13
		.WORD	EMIT
		.WORD	DO_LITERAL,10
		.WORD	EMIT
		.WORD	EXIT

; EMIT ( x -- )
;
; If x is a graphic character in the implementation-defined character set,
; display x. The effect of EMIT for all other values of x is implementation
; -defined.

		WORD	"EMIT",NORMAL
EMIT:		NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Fetch and print the character
		TXD
		ILD	SP+0(MA)	; Drop the top of stack
		ILD	SP+0(MA)
		XPPC	R2		; And continue

; KEY ( -- char )
;
; Receive one character char, a member of the implementation-defined character
; set. Keyboard events that do not correspond to such characters are discarded
; until a valid character is received, and those events are subsequently
; unavailable.
;
; All standard characters can be received. Characters received by KEY are not
; displayed.

		WORD	"KEY",NORMAL
KEY:		NATIVE
		DLD	SP+0(MA)	; Load the data stack pointer and
		DLD	SP+0(MA)	; .. create a new cell
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		RXD			; Read a character from the keyboard
		ST	0(R1)		; .. then save on the stack
		LDI	0
		ST	1(R1)
		XPPC	R2		; And continue


; KEY? ( -- flag )
;
; If a character is available, return true. Otherwise, return false. If
; non-character keyboard events are available before the first valid character,
; they are discarded and are subsequently unavailable. The character shall be
; returned by the next execution of KEY.

		WORD	"KEY?",NORMAL
KEY_QUERY:	.WORD	DO_CONSTANT-1
		.WORD	-1

; SPACE ( -- )
;
; Display one space.
;
; In this implementation it is defined as
;
;   BL EMIT

		WORD	"SPACE",NORMAL
SPACE:		FORTH
		.WORD	BL
		.WORD	EMIT
		.WORD	EXIT

; SPACES ( n -- )
;
; If n is greater than zero, display n spaces.
;
; In this implementation it is defined as
;
;   BEGIN DUP 0> WHILE SPACE 1- REPEAT DROP

		WORD	"SPACES",NORMAL
SPACES:		FORTH
SPACES_1:	.WORD	DUP
		.WORD	ZERO_GREATER
		.WORD	QUERY_BRANCH,SPACES_2
		.WORD	SPACE
		.WORD	ONE_MINUS
		.WORD	BRANCH,SPACES_1
SPACES_2:	.WORD	DROP
		.WORD	EXIT

; TYPE ( c-addr u -- )
;
; If u is greater than zero, display the character string specified by c-addr
; and u.
;
; In this implementation it is defined as
;
;   ?DUP IF
;     OVER + SWAP DO I C@ EMIT LOOP
;   ELSE DROP THEN

		WORD	"TYPE",NORMAL
TYPE:		FORTH
		.WORD	QUERY_DUP
		.WORD	QUERY_BRANCH,TYPE_2
		.WORD	OVER
		.WORD	PLUS
		.WORD	SWAP
		.WORD	DO_DO
TYPE_1:		.WORD	I
		.WORD	C_FETCH
		.WORD	EMIT
		.WORD	DO_LOOP,TYPE_1
		.WORD	BRANCH,TYPE_3
TYPE_2		.WORD	DROP
TYPE_3		.WORD	EXIT


;===============================================================================
; Formatted Output
;-------------------------------------------------------------------------------

; # ( ud1 -- ud2 )
;
; Divide ud1 by the number in BASE giving the quotient ud2 and the remainder n.
; (n is the least-significant digit of ud1.) Convert n to external form and add
; the resulting character to the beginning of the pictured numeric output string.
; An ambiguous condition exists if # executes outside of a <# #> delimited
; number conversion.
;
;	BASE @ >R 0 R@ UM/MOD ROT ROT R> UM/MOD ROT ROT DUP 9 > 7 AND + 30 + HOLD

		WORD	"#",NORMAL
HASH:		FORTH
		.WORD	BASE
		.WORD	FETCH
		.WORD	TO_R
		.WORD	ZERO
		.WORD	R_FETCH
		.WORD	UM_SLASH_MOD
		.WORD	ROT
		.WORD	ROT
		.WORD	R_FROM
		.WORD	UM_SLASH_MOD
		.WORD	ROT
		.WORD	ROT
		.WORD	DUP
		.WORD	DO_LITERAL,9
		.WORD	GREATER
		.WORD	DO_LITERAL,7
		.WORD	AND
		.WORD	PLUS
		.WORD	DO_LITERAL,'0'
		.WORD	PLUS
		.WORD	HOLD
		.WORD	EXIT

; #> ( xd -- c-addr u )
;
; Drop xd. Make the pictured numeric output string available as a character
; string. c-addr and u specify the resulting character string. A program may
; replace characters within the string.
;
;	2DROP HP @ PAD OVER -

		WORD	"#>",NORMAL
HASH_GREATER:	FORTH
		.WORD	TWO_DROP
		.WORD	HP
		.WORD	FETCH
		.WORD	PAD
		.WORD	OVER
		.WORD	MINUS
		.WORD	EXIT

; #S ( ud1 -- ud2 )
;
; Convert one digit of ud1 according to the rule for #. Continue conversion
; until the quotient is zero. ud2 is zero. An ambiguous condition exists if #S
; executes outside of a <# #> delimited number conversion.
;
;	BEGIN # 2DUP OR 0= UNTIL

		WORD	"#S",NORMAL
HASH_S:		FORTH
HASH_S_1:	.WORD	HASH
		.WORD	TWO_DUP
		.WORD	OR
		.WORD	ZERO_EQUAL
		.WORD	QUERY_BRANCH,HASH_S_1
		.WORD	EXIT

; . ( n -- )
;
; Display n in free field format.
;
;	<# DUP ABS 0 #S ROT SIGN #> TYPE SPACE

		WORD	".",NORMAL
DOT:		FORTH
		.WORD	LESS_HASH
		.WORD	DUP
		.WORD	ABS
		.WORD	ZERO
		.WORD	HASH_S
		.WORD	ROT
		.WORD	SIGN
		.WORD	HASH_GREATER
		.WORD	TYPE
		.WORD	SPACE
		.WORD	EXIT

; <# ( -- )
;
; Initialize the pictured numeric output conversion process.
;
;	PAD HP !

		WORD	"<#",NORMAL
LESS_HASH:	FORTH
		.WORD	PAD
		.WORD	HP
		.WORD	STORE
		.WORD	EXIT

; HOLD ( char -- )

; Add char to the beginning of the pictured numeric output string. An
; ambiguous condition exists if HOLD executes outside of a <# #> delimited
; number conversion.
;
;	-1 HP +!  HP @ C!

		WORD	"HOLD",NORMAL
HOLD:		FORTH
		.WORD	DO_LITERAL,-1
		.WORD	HP
		.WORD	PLUS_STORE
		.WORD	HP
		.WORD	FETCH
		.WORD	C_STORE
		.WORD	EXIT

; PAD ( -- c-addr )
;
; c-addr is the address of a transient region that can be used to hold data
; for intermediate processing.

		WORD	"PAD",NORMAL
PAD:		.WORD	DO_CONSTANT-1
		.WORD	PAD_END

; SIGN ( n -- )
;
; If n is negative, add a minus sign to the beginning of the pictured numeric
; output string. An ambiguous condition exists if SIGN executes outside of a
; <# #> delimited number conversion.
;
;	[ HEX ] 0< IF 2D HOLD THEN

		WORD	"SIGN",NORMAL
SIGN:		FORTH
		.WORD	ZERO_LESS
		.WORD	QUERY_BRANCH,SIGN_1
		.WORD	DO_LITERAL,'-'
		.WORD	HOLD
SIGN_1:		.WORD	EXIT

; U. ( u -- )
;
; Display u in free field format.
;
;  <# 0 #S #> TYPE SPACE

		WORD	"U.",NORMAL
U_DOT:		FORTH
		.WORD	LESS_HASH
		.WORD	ZERO
		.WORD	HASH_S
		.WORD	HASH_GREATER
		.WORD	TYPE
		.WORD	SPACE
		.WORD	EXIT

;===============================================================================
; Programming Tools
;-------------------------------------------------------------------------------

; .NYBBLE ( n -- )
;
; Print the least significant nybble of the top value on the stack in hex.

;		WORD	".NYBBLE",NORMAL
DOT_NYBBLE:	NATIVE
		LD	SP+0(MA)	; Load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	0(R1)		; Fetch the nybble
		ANI	X'0F
		XAE
		LDI	LO(DIGITS)
		XPAL	R1
		LDI	HI(DIGITS)
		XPAH	R1
		LD	-128(R1)	; Fetch a digit
		TXD
		ILD	SP+0(MA)	; Drop the top cell
		ILD	SP+0(MA)
		XPPC	R2		; And continue

DIGITS:		.BYTE	"01234567"
		.BYTE	"89ABCDEF"

; .BYTE ( n -- )
;
; Print least significant byte of top value on the stack in hex followed by
; a space.

		WORD	".BYTE",NORMAL
DOT_BYTE:	FORTH
		.WORD	DUP
		.WORD	DO_LITERAL,4
		.WORD	RSHIFT
		.WORD	DOT_NYBBLE
		.WORD	DOT_NYBBLE
		.WORD	SPACE
		.WORD	EXIT

; .WORD ( n -- )
;
; Print the top value on the stack in hex followed by a space.

		WORD	".WORD",NORMAL
DOT_WORD:	FORTH
		.WORD	DUP
		.WORD	DO_LITERAL,12
		.WORD	RSHIFT
		.WORD	DOT_NYBBLE
		.WORD	DUP
		.WORD	DO_LITERAL,8
		.WORD	RSHIFT
		.WORD	DOT_NYBBLE
		.WORD	DUP
		.WORD	DO_LITERAL,4
		.WORD	RSHIFT
		.WORD	DOT_NYBBLE
		.WORD	DOT_NYBBLE
		.WORD	SPACE
		.WORD	EXIT

; .DP ( -- )

		WORD	".DP",NORMAL
DOT_DP:		FORTH
		.WORD	AT_DP
		.WORD	DOT_WORD
		.WORD	EXIT

; .RP ( -- )

		WORD	".RP",NORMAL
DOT_RP:		FORTH
		.WORD	AT_RP
		.WORD	DOT_WORD
		.WORD	EXIT

; .S ( -- )
;
; Copy and display the values currently on the data stack. The format of the
; display is implementation-dependent.

		WORD	".S",NORMAL
DOT_S:		FORTH
		.WORD	DO_LITERAL,'{'
		.WORD	EMIT
		.WORD	SPACE
		.WORD	AT_DP
		.WORD	ONE_PLUS
		.WORD	DO_LITERAL,DSTACK_END
		.WORD	SWAP
		.WORD	QUERY_DO_DO,DOT_S_2
DOT_S_1:	.WORD	I
		.WORD	FETCH
		.WORD	DOT_WORD
		.WORD	DO_LITERAL,2
		.WORD	DO_PLUS_LOOP
		.WORD	DOT_S_1
DOT_S_2:	.WORD	DO_LITERAL,'}'
		.WORD	EMIT
		.WORD	SPACE
		.WORD	EXIT

; ? ( a-addr -- )
;
; Display the value stored at a-addr.

		WORD	"?",NORMAL
QUERY:		FORTH
		.WORD	FETCH
		.WORD	DOT_WORD
		.WORD	EXIT

; @DP ( -- a-addr )

		WORD	"@DP",NORMAL
AT_DP:
		LD	SP+0(MA)	; Save the original index
		XAE
		DLD	SP+0(MA)	; Reserve a new stack cell
		DLD	SP+0(MA)	; .. and load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LDE			; Save the original value
		ST	0(R1)
		LD	SP+1(MA)
		ST	1(R1)
		XPPC	R2		; And continue

; @DP ( -- a-addr )

		WORD	"@RP",NORMAL
AT_RP:
		DLD	SP+0(MA)	; Reserve a new stack cell
		DLD	SP+0(MA)	; .. and load the data stack pointer
		XPAL	R1
		LD	SP+1(MA)
		XPAH	R1
		LD	RP+0(MA)	; Copy across the return stack pointer
		ST	0(R1)
		LD	RP+1(MA)
		ST	1(R1)
		XPPC	R2		; And continue

;===============================================================================
; Device Customisation
;-------------------------------------------------------------------------------

; (TITLE) - ( -- )
;

;		WORD	"(TITLE)",NORMAL
DO_TITLE:	FORTH
		.WORD	DO_S_QUOTE
		.BYTE	23,"SC/MP ANS-Forth [16.09]"
		.WORD	EXIT

; BYE ( -- )
;
; Return control to the host operating system, if any.

		WORD	"BYE",NORMAL
BYE:		NATIVE
		LDI	0		; Load address zero
		XPAL	R2
		LDI	0
		XPAH	R2
		XPPC	R2		; And restart NIBL

; UNUSED ( -- u )
;
; u is the amount of space remaining in the region addressed by HERE , in
; address units.

		WORD	"UNUSED",NORMAL
UNUSED:		FORTH
		.WORD	DO_LITERAL,X'8000
		.WORD	HERE
		.WORD	MINUS
		.WORD	EXIT

LAST_WORD	.EQU	LAST

		.END