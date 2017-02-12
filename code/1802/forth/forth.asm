;===============================================================================
;     _    _   _ ____        _____          _   _       _  ___   ___ ____  
;    / \  | \ | / ___|      |  ___|__  _ __| |_| |__   / |( _ ) / _ \___ \ 
;   / _ \ |  \| \___ \ _____| |_ / _ \| '__| __| '_ \  | |/ _ \| | | |__) |
;  / ___ \| |\  |___) |_____|  _| (_) | |  | |_| | | | | | (_) | |_| / __/ 
; /_/   \_\_| \_|____/      |_|  \___/|_|   \__|_| |_| |_|\___/ \___/_____|
;                                                                          
; A Direct Threaded RCA CDP1802 ANS Forth
;-------------------------------------------------------------------------------
; Copyright (C)2014-2016 HandCoded Software Ltd.
; All rights reserved.
;
; This work is made available under the terms of the Creative Commons
; Attribution-NonCommercial-ShareAlike 4.0 International license. Open the
; following URL to see the details.
;
; http://creativecommons.org/licenses/by-nc-sa/4.0/
;===============================================================================
; Notes:
;
; Only the CDP 1802 long branch instructions contain a 16-bit address value and
; this is in big-endian order so this is the order used for data variables in
; memory and on the return stack. Values on the data stack are in little-endian
; order to make arithmetic faster
;
; There No Alignment
;
; The stacks are always kept in a safe state so that interrupt code could be
; implemented in Forth.

;-------------------------------------------------------------------------------

PC_CODE		.EQU	0			; Pointer used for native code
PC_COLON	.EQU	2
PC_NEXT		.EQU	3
PC_USER		.EQU	4
PC_CONSTANT	.EQU	5
PC_VARIABLE	.EQU	6

; 7 & 8 free -- 1 kept for interrupts

DSP		.EQU	9			; Data stack pointer
RSP		.EQU	10			; Return stack pointer
IP		.EQU	11			; Forth instruction pointer

T1		.EQU	12			; Temporary registers
T2		.EQU	13
T3		.EQU	14
T4		.EQU	15

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

		.BSS
		.ORG	$2000

RSTACK		.SPACE	128
DSTACK		.SPACE	128

;===============================================================================
;-------------------------------------------------------------------------------

LAST		.SET	0

NORMAL		.EQU	$00
IMMED		.EQU	$80

WORD		.MACRO	NAME,TYPE
THIS		.SET	@
		.WORD	LAST
		.BYTE	TYPE
		.BYTE	STRLEN(NAME)
		.BYTE	NAME
LAST		.SET	THIS
		.ENDM

STRING		.MACRO	MESG
		.BYTE	STRLEN(MESG)
		.BYTE	MESG
;		.SPACE	@ & 1
		.ENDM

;===============================================================================
;-------------------------------------------------------------------------------

		.CODE
		.ORG	$0000

		LDI	HI RSTACK		; Reset the return stack
		PHI	RSP
		LDI	LO RSTACK
		PLO	RSP

		LDI	HI DSTACK		; Reset the data stack
		PHI	DSP
		LDI	LO DSTACK
		PLO	DSP

		LDI	HI DO_NEXT		; Reset interpreter address
		PHI	PC_NEXT
		LDI	LO DO_NEXT
		PLO	PC_NEXT
		
		LDI	HI DO_USER
		PHI	PC_USER
		LDI 	LO DO_USER
		PLO	PC_USER
		
		LDI	HI DO_COLON
		PHI	PC_COLON
		LDI	LO DO_COLON
		PLO	PC_COLON
		
		LDI	HI DO_CONSTANT
		PHI	PC_CONSTANT
		LDI	LO DO_CONSTANT
		PLO	PC_CONSTANT
		
		LDI	HI DO_VARIABLE
		PHI	PC_VARIABLE
		LDI	LO DO_VARIABLE
		PLO	PC_VARIABLE
		
		SEX	DSP
		LBR	COLD

; Inner Interpreter

		SEP	PC_CODE			;
DO_NEXT:	LDA	IP			; Fetch the next word address
		PHI	PC_CODE
		LDA	IP
		PLO	PC_CODE
		BR	DO_NEXT-1

;===============================================================================
;-------------------------------------------------------------------------------

		WORD	"COLD",NORMAL
COLD:		SEP	PC_COLON

;===============================================================================
; Condition and Unconditional Branches
;-------------------------------------------------------------------------------

Q_BRANCH:
		SEP	PC_NEXT

BRANCH:
		SEP	PC_NEXT


;===============================================================================
; System Variables
;-------------------------------------------------------------------------------



;===============================================================================
; User Variables
;-------------------------------------------------------------------------------


; >IN ( -- a-addr )
;
; a-addr is the address of a cell containing the offset in characters from the
; start of the input buffer to the start of the parse area.

		WORD	">IN",NORMAL
TO_IN:		SEP	PC_USER
		.WORD	2

; BASE ( -- a-addr )
;
; a-addr is the address of a cell containing the current number-conversion radix
; {{2...36}}.

		WORD	"BASE",NORMAL
BASE:		SEP	PC_USER
		.WORD	4

; DP ( -- a )

		WORD	"DP",NORMAL
DP:		SEP	PC_USER
		.WORD	8

; LATEST ( -- a )

		WORD	"LASTEST",NORMAL
LATEST:		SEP	PC_USER
		.WORD	14

; STATE ( -- a-addr)
;
; a-addr is the address of a cell containing the compilation-state flag. STATE
; is true when in compilation state, false otherwise.

		WORD	"STATE",NORMAL
STATE:		SEP	PC_USER
		.WORD	6

;===============================================================================
; Constants
;-------------------------------------------------------------------------------

; 0 ( -- 0 )

		WORD	"0",NORMAL
ZERO:
		LDI	0			; Push zero onto data stack
		DEC	DSP
		STXD
		STR	DSP
		SEP	PC_NEXT			; And continue

; 1 ( -- 1 )

		WORD	"1",NORMAL
ONE:
		LDI	1			; Push one onto data stack
		DEC	DSP
		STXD
		STR	DSP
		SEP	PC_NEXT			; And continue

; BL ( -- char )
;
; char is the character value for a space.

		WORD	"BL",NORMAL
BL:		SEP	PC_CONSTANT
		.WORD	' '

; FALSE ( -- false )
;
; Return a false flag.

		WORD	"FALSE",NORMAL
FALSE:
		LDI	$00			; Push false onto data stack
		DEC	DSP
		STXD
		STR	DSP
		SEP	PC_NEXT			; And continue

; TRUE ( -- true )
;
; Return a true flag, a single-cell value with all bits set.

		WORD	"TRUE",NORMAL
TRUE:
		LDI	$FF			; Push true onto data stack
		DEC	DSP
		STXD
		STR	DSP
		SEP	PC_NEXT			; And continue

;===============================================================================
; Address Alignment
;-------------------------------------------------------------------------------

; ALIGN ( -- )
;
; If the data-space pointer is not aligned, reserve enough space to align it.

		WORD	"ALIGN",NORMAL
ALIGN:
		SEP	PC_NEXT

; ALIGNED ( addr -- a-addr )
;
; a-addr is the first aligned address greater than or equal to addr.

		WORD 	"ALIGNED",NORMAL
ALIGNED:
		SEP	PC_NEXT

; ALLOT ( n -- )
;
; If n is greater than zero, reserve n address units of data space. If n is less
; than zero, release |n| address units of data space. If n is zero, leave the
; data-space pointer unchanged.
;
; : ALLOT ( n -- ) DP +! ;

		WORD	"ALLOT",NORMAL
ALLOT:		SEP	PC_COLON
		.WORD	DP
		.WORD	PLUS_STORE
		.WORD	EXIT

; CELL+ ( a-addr1 -- a-addr2 )
;
; Add the size in address units of a cell to a-addr1, giving a-addr2.

		WORD	"CELL+",NORMAL
CELL_PLUS:
		LDA	DSP
		PLO	T1
		LDN	DSP
		PHI	T1
		INC	T1
		INC	T1
		GHI	T1
		STXD
		GLO	T1
		STR	DSP
		SEP	PC_NEXT

; CELLS ( n1 -- n2 )
;
; n2 is the size in address units of n1 cells.

		WORD	"CELLS",NORMAL
CELLS:
		LBR	TWO_TIMES

; CHAR+ ( c-addr1 -- c-addr2 )
;
; Add the size in address units of a character to c-addr1, giving c-addr2.

		WORD	"CHAR+",NORMAL
CHAR_PLUS:
		LBR	ONE_PLUS

; CHARS ( n1 -- n2 )
;
; n2 is the size in address units of n1 characters.

		WORD	"CHARS",NORMAL
CHARS:
		SEP	PC_NEXT

; HERE ( c-addr -- char )
;
; Fetch the character stored at c-addr. When the cell size is greater than
; character size, the unused high-order bits are all zeroes.

		WORD	"HERE",NORMAL
HERE:		SEP	PC_COLON
		.WORD	DP
		.WORD	FETCH
		.WORD	EXIT

;===============================================================================
; Memory Access
;-------------------------------------------------------------------------------

; ! ( x a-addr -- )
;
; Store x at a-addr.

		WORD	"!",NORMAL
STORE:
		LDA	DSP			; Pull the address
		PLO	T1
		LDA	DSP
		PHI	T1
		LDA	DSP			; Save data lo byte
		PLO	T2
		LDA	DSP			; Fetch data hi byte
		STR	T1			; .. and save
		INC	T1			; Bump address
		GLO	T2			; .. and save lo byte
		STR	T1
		SEP	PC_NEXT			; And continue

; +! ( n|u a-addr -- )
;
; Add n|u to the single-cell number at a-addr.

		WORD	"+!",NORMAL
PLUS_STORE:
		LDA	DSP			; Pull the address
		PLO	T1
		LDA	DSP
		PHI	T1
		SEX	T1			; Use memory for math
		INC	T1			; Point at lo byte
		LDA	DSP			; Add the lo bytes
		ADD
		STXD				; And save
		LDA	DSP			; Add the hi bytes
		ADC
		STR	T1			; And save
		SEX	DSP			; Use data stack for math
		SEP	PC_NEXT			; And continue

; , ( x -- )
;
; Reserve one cell of data space and store x in the cell. If the data-space
; pointer is aligned when , begins execution, it will remain aligned when ,
; finishes execution.

		WORD	",",NORMAL
COMMA:		SEP	PC_COLON
		.WORD	HERE
		.WORD	STORE
		.WORD	ONE
		.WORD 	CELLS
		.WORD	ALLOT
		.WORD	EXIT

; 2!
; 2@

; @ ( a-addr -- x )
;
; x is the value stored at a-addr.

		WORD	"@",NORMAL
FETCH:
		SEP	PC_NEXT

; C! ( char c-addr -- )
;
; Store char at c-addr. When character size is smaller than cell size, only the
; number of loworder bits corresponding to character size are transferred.

		WORD	"C!",NORMAL
C_STORE:
		SEP	PC_NEXT

; C, ( char -- )
;
; Reserve space for one character in the data space and store char in the space.
; If the data-space pointer is character aligned when C, begins execution, it
; will remain character aligned when C, finishes execution.

		WORD	"C,",NORMAL
C_COMMA:	SEP	PC_COLON
		.WORD	HERE
		.WORD	C_STORE
		.WORD	ONE
		.WORD	CHARS
		.WORD	ALLOT
		.WORD	EXIT

; C@ ( c-addr -- char )
;
; Fetch the character stored at c-addr. When the cell size is greater than
; character size, the unused high-order bits are all zeroes.

		WORD	"C@",NORMAL
C_FETCH:
		SEP	PC_NEXT

; CMOVE
; CMOVE>

; COMPILE, ( xt -- )
;
; Append the execution semantics of the definition represented by xt to the
; execution semantics of the current definition.

		WORD	"COMPILE,",NORMAL
COMPILE_COMMA:
		LBR	COMMA

; FILL

; MOVE

;===============================================================================
; Stack Operations
;-------------------------------------------------------------------------------

; ?DUP

		WORD	"?DUP",NORMAL
QDUP:
		SEP	PC_NEXT

; 2DROP ( x1 x2 -- )
;
; Drop cell pair x1 x2 from the stack.

		WORD	"2DROP",NORMAL
TWO_DROP:
		LDA	DSP			; Drop two words
		LDA	DSP
		LDA	DSP
		LDA	DSP
		SEP	PC_NEXT			; And continue

; 2DUP ( x1 x2 -- x1 x2 x1 x2 )
;
; Duplicate cell pair x1 x2.

		WORD	"2DUP",NORMAL
TWO_DUP:	SEP	PC_COLON
		.WORD	OVER
		.WORD	OVER
		.WORD	EXIT

; DROP ( x -- )
;
; Remove x from the stack.

		WORD	"DROP",NORMAL
DROP:
		INC	DSP			; Drop one word
		INC	DSP
		SEP	PC_NEXT			; And continue

; DUP ( x -- x x )
;
; Duplicate x.

		WORD	"DUP",NORMAL
DUP:
		SEP	PC_NEXT

		WORD	"NIP",NORMAL
NIP:
		SEP	PC_NEXT

		WORD	"OVER",NORMAL
OVER:
		SEP	PC_NEXT
		
		WORD	"ROT",NORMAL
ROT:
		SEP	PC_NEXT

; SWAP ( x1 x2 -- x2 x1 )
;
; Exchange the top two stack items.

		WORD	"SWAP",NORMAL
SWAP:
		SEP	PC_NEXT

		WORD	"TUCK",NORMAL
TUCK:
		SEP	PC_NEXT

;===============================================================================
; Return Stack Operations
;-------------------------------------------------------------------------------

; >R ( x -- ) ( R: -- x )
;
; Move x to the return stack.

		WORD	">R",NORMAL
TO_R:
		LDA	DSP			; Move the lo byte
		DEC	RSP
		STR	RSP
		LDA	DSP			; Then the hi byte
		DEC	RSP
		STR	RSP
		SEP	PC_NEXT			; And continue

; R> ( -- x ) ( R: x -- )
;
; Move x from the return stack to the data stack.

		WORD	"R>",NORMAL
R_FROM:
		LDA	RSP			; Move the hi byte
		DEC	DSP
		STXD
		LDA	RSP			; Then the lo byte
		STR	DSP
		SEP	PC_NEXT			; And continue

; R@

;===============================================================================
; Binary Operators
;-------------------------------------------------------------------------------

; AND ( x1 x2 -- x3 )
;
; x3 is the bit-by-bit logical “and” of x1 with x2.

		WORD	"AND",NORMAL
AND:
		LDA	DSP			; Pull X2
		PLO	T2
		LDA	DSP
		PHI	T2
		GLO	T2			; AND the lo byte
		AND
		PLO	T2			; .. and save
		INC	DSP			; AND the hi byte
		GHI	T2
		AND
		STXD				; Update the hi
		PLO	T2			; .. and lo bytes
		STR	DSP
		SEP	PC_NEXT			; And continue

; INVERT ( x1 -- x2 )
;
; Invert all bits of x1, giving its logical inverse x2.

		WORD	"INVERT",NORMAL
INVERT:
		LDA	DSP			; Fetch the lo byte
		XRI	$FF			; .. invert
		PLO	T1			; .. and save
		LDX				; Fetch the hi byte
		XRI	$FF			; .. invert
		STXD				; .. and write back
		GLO	T1			; Recover the lo byte
		STR	DSP			; .. and write back
		SEP	PC_NEXT			; And continue

; LSHIFT

; OR ( x1 x2 -- x3 )
;
; x3 is the bit-by-bit inclusive-or of x1 with x2.

		WORD	"OR",NORMAL
OR:
		LDA	DSP			; Pull X2
		PLO	T2
		LDA	DSP
		PHI	T2
		GLO	T2			; OR the lo byte
		OR
		PLO	T2			; .. and save
		INC	DSP			; OR the hi byte
		GHI	T2
		OR
		STXD				; Update the hi
		PLO	T2			; .. and lo bytes
		STR	DSP
		SEP	PC_NEXT			; And continue

; RSHIFT

; XOR ( x1 x2 -- x3 )
;
; x3 is the bit-by-bit exclusive-or of x1 with x2.

		WORD	"XOR",NORMAL
XOR:
		LDA	DSP			; Pull X2
		PLO	T2
		LDA	DSP
		PHI	T2
		GLO	T2			; XOR the lo byte
		XOR
		PLO	T2			; .. and save
		INC	DSP			; XOR the hi byte
		GHI	T2
		XOR
		STXD				; Update the hi
		PLO	T2			; .. and lo bytes
		STR	DSP
		SEP	PC_NEXT			; And continue

;===============================================================================
; Single Arithmetic
;-------------------------------------------------------------------------------

; + ( n1|u1 n2|u2 -- n3|u3 )
;
; Add n2|u2 to n1|u1, giving the sum n3|u3.

		WORD	"+",NORMAL
PLUS:
		SEP	PC_NEXT

; - ( n1|u1 n2|u2 -- n3|u3 )
;
; Subtract n2|u2 from n1|u1, giving the difference n3|u3.

		WORD	"-",NORMAL
MINUS:
		SEP	PC_NEXT

; 1+ ( n1|u1 -- n2|u2 )
;
; Add one (1) to n1|u1 giving the sum n2|u2.

		WORD	"1+",NORMAL
ONE_PLUS:
		LDA	DSP
		PLO	T1
		LDN	DSP
		PHI	T1
		INC	T1
		GHI	T1
		STXD
		GLO	T1
		STR	DSP
		SEP	PC_NEXT
		
; 1- ( n1|u1 -- n2|u2 )
;
; Subtract one (1) from n1|u1 giving the difference n2|u2.

		WORD	"1-",NORMAL
ONE_MINUS:
		LDA	DSP
		PLO	T1
		LDN	DSP
		PHI	T1
		DEC	T1
		GHI	T1
		STXD
		GLO	T1
		STR	DSP
		SEP	PC_NEXT

; 2* ( x1 -- x2 )
;
; x2 is the result of shifting x1 one bit toward the most-significant bit,
; filling the vacated least-significant bit with zero.

		WORD	"2*",NORMAL
TWO_TIMES:
		SEP	PC_NEXT

; 2/ ( x1 -- x2 )
;
; x2 is the result of shifting x1 one bit toward the least-significant bit,
; leaving the most-significant bit unchanged.

		WORD	"2/",NORMAL
TWO_SLASH:
		SEP	PC_NEXT

;===============================================================================
; Mixed Arithmetic
;-------------------------------------------------------------------------------


; M+ ( d1|ud1 n -- d2|ud2 )
;
; Add n to d1|ud1, giving the sum d2|ud2.

		WORD	"M+",NORMAL
M_PLUS:
		SEP	PC_NEXT

;===============================================================================
; Double Arithmetic
;-------------------------------------------------------------------------------

; DNEGATE ( d1 -- d2 )
;
; d2 is the negation of d1.

		WORD	"DNEGATE",NORMAL
D_NEGATE:	SEP	PC_COLON
		.WORD	SWAP
		.WORD	INVERT
		.WORD	SWAP
		.WORD	INVERT
		.WORD	ONE
		.WORD	M_PLUS
		.word	EXIT

;===============================================================================
; Comparisons
;-------------------------------------------------------------------------------

; 0< ( n -- flag )
;
; flag is true if and only if n is less than zero.

		WORD	"0<",NORMAL
ZERO_LESS:
		LBR	FALSE

; 0= ( x -- flag )
;
; flag is true if and only if x is equal to zero.

		WORD	"0=",NORMAL
ZERO_EQUAL:
		LBR	FALSE


; U<

		WORD	"U<",NORMAL
U_LESS:

; WITHIN ( n1|u1 n2|u2 n3|u3 -- flag )
;
; Perform a comparison of a test value n1|u1 with a lower limit n2|u2 and an
; upper limit n3|u3, returning true if either (n2|u2<n3|u3 and (n2|u2<=n1|u1 and
; n1|u1<n3|u3)) or (n2|u2>n3|u3 and (n2|u2<=n1|u1 or n1|u1<n3|u3)) is true,
; returning false otherwise. An ambiguous condition exists if n1|u1, n2|u2, and
; n3|u3 are not all the same type.

		WORD	"WITHIN",NORMAL
WITHIN:		SEP	PC_COLON
		.WORD	OVER
		.WORD	MINUS
		.WORD	TO_R
		.WORD	MINUS
		.WORD	R_FROM
		.WORD	U_LESS
		.WORD	EXIT

;===============================================================================
;
;-------------------------------------------------------------------------------

; DECIMAL ( -- )
;
; Set the numeric conversion radix to ten (decimal).

		WORD	"DECIMAL",NORMAL
DECIMAL:	SEP	PC_COLON
		.word	DO_LITERAL,10
		.word	BASE
		.word	STORE
		.word	EXIT

; HEX ( -- )
;
; Set contents of BASE to sixteen.

		WORD	"HEX",NORMAL
HEX:		SEP	PC_COLON
		.word	DO_LITERAL,16
		.word	BASE
		.word	STORE
		.word	EXIT

;===============================================================================
; Number Formatting
;-------------------------------------------------------------------------------

; #
; #>
; #S

;===============================================================================
; String Operations
;-------------------------------------------------------------------------------


;===============================================================================
; Control Operations
;-------------------------------------------------------------------------------

; ABORT
; ABORT"

; EXECUTE ( i*x xt -- j*x )
;
; Remove xt from the stack and perform the semantics identified by it. Other
; stack effects aredue to the word EXECUTEd.

		WORD	"EXECUTE",NORMAL
EXECUTE:
		LDI	HI DO_EXECUTE
		PHI	T1
		LDI	LO DO_EXECUTE
		PLO	T1
		SEP	T1
DO_EXECUTE:
		LDA	DSP
		PLO	PC_CODE
		LDA	DSP
		PHI	PC_CODE
		SEP	PC_CODE

; EXIT ( -- ) ( R: nest-sys -- )
;
; Return control to the calling definition specified by nest-sys. Before
; executing EXIT within a do-loop, a program shall discard the loop-control
; parameters by executing UNLOOP.

		WORD	"EXIT",NORMAL
EXIT:
		LDA	RSP
		PHI	IP
		LDA	RSP
		PLO	IP
		SEP	PC_NEXT

; QUIT


;===============================================================================
; Compiling Words
;-------------------------------------------------------------------------------


		WORD	":",NORMAL
COLON:


		SEP	PC_NEXT
DO_COLON:	GLO	IP			; Save callers IP
		DEC	RSP
		STR	RSP
		GHI	IP
		DEC	RSP
		STR	RSP
		GHI	PC_CODE			; Set IP from last code address
		PHI	IP
		GLO	PC_CODE
		PLO	IP
		BR	DO_COLON-1		; Reset COLON_PC and do NEXT


		WORD	";",IMMED

		WORD	"CONSTANT",NORMAL
CONSTANT:

		SEP	PC_NEXT
DO_CONSTANT:
		LDA	PC_CODE			; Push constant hi byte
		DEC	DSP
		STXD
		LDA	PC_CODE			; Push constant lo byte
		STR	DSP
		BR	DO_CONSTANT-1		; And continue

; LITERAL ( x -- )
;
; Append the run-time semantics given below to the current definition.

		WORD	"LITERAL",NORMAL
LITERAL:
		.WORD	DO_LITERAL,DO_LITERAL
		.WORD	COMPILE_COMMA
		.WORD	COMMA
		.WORD	EXIT

		WORD	"(LITERAL)",NORMAL
DO_LITERAL:
		LDA	IP			; Push literal hi byte
		DEC	DSP
		STXD
		LDA	IP			; Push literal lo byte
		STR	DSP
		SEP	PC_NEXT			; And continue

		WORD	"USER",NORMAL
USER:

DO_USER:

		WORD	"VARIABLE",NORMAL
VARIABLE:

DO_VARIABLE:

;===============================================================================
; I/O
;-------------------------------------------------------------------------------

; EMIT

		WORD	"EMIT",NORMAL
EMIT:
		SEP	PC_NEXT

; SPACE

		WORD	"SPACE",NORMAL
SPACE:		SEP	PC_COLON
		.WORD	BL
		.WORD	EMIT
		.WORD	EXIT

; SPACES

		WORD	"SPACES",NORMAL
SPACES:		SEP	PC_COLON
.LOOP		.WORD	DUP
		.WORD	Q_BRANCH,.DONE
		.WORD	SPACE
		.WORD	ONE_MINUS
		.WORD	BRANCH,.LOOP
.DONE		.WORD	DROP
		.WORD	EXIT

		.END


	.IF 0
;
;
; Revision history:
; 2009-02-09	First version for RCA 1802 based on Z80 CamelForth
;
;
; ===============================================
;   Source code is for the As1802 assembler.
;   Forth words are documented as follows:
;x   NAME     stack -- stack    description
;   where x=C for ANS Forth Core words, X for ANS
;   Extensions, Z for internal or private words.
;
; Direct-Threaded Forth model for RCA 1802
; 16 bit cell, 8 bit char, 8 bit (byte) adrs unit
;
; ===============================================
;
;	Stack Layouts
;
;	PSP->	TOS.LO		RSP->	RET.HI
;		TOS.HI			RET.LO
;		NEXT.LO
;		NEXT.HI
;
; Both stacks grow from high to low
; Parameter stack is stored little-endian
; Return stack is stored big-endian
; Compiled 16-bit data is stored big-endian
;
; ANSI 3.1.4.1 requires doubles to be stored with the MORE
; significant cell at the top of the stack. Therefore, doubles
; are stored mixed-endian as follows
;
;	PSP->	Byte [2]
;		Byte [3]	; MSB
;		Byte [0]	; LSB
;		Byte [1]
;
; ===============================================
; Memory map:
paramstack	.equ	$8000	; top of parameter stack
returnstack	.equ	$9000	; top of return stack
userarea	.equ	$A000	; user area, must be page aligned
tibarea		.equ	$A200	; Terminal Input Buffer
padarea		.equ 	$A400	; User Pad Buffer
leavestack	.equ	$B000	; top of leave stack

reset		.equ	$0000 	; cold start, Forth kernel, dictionary

; ===============================================
; Register usage
codepc		.equ	0	; PC for code words
ip		.equ	1	; Forth interpreter pointer
psp		.equ	2	; Forth parameter stack pointer
rsp		.equ	3	; Forth return stack pointer
nextpc		.equ	4	; PC for Forth inner interpreter
colonpc		.equ	5	; PC for colon definitions
constpc		.equ	6	; PC for CONSTANT definitions
varpc		.equ	7	; PC for VARIABLE and SCREATE definitions
createpc	.equ	8	; PC for CREATE definitions
userpc		.equ	9	; PC for USER definitions

temppc		.equ	15	; temporary registers
temp1		.equ	15
temp2		.equ	14
temp3		.equ	13
temp4		.equ	12

sepcode		.equ	$D0	; opcode for SEP instruction

; ===============================================
; Execution begins here
	.org	reset		; cold start address
				; initialize registers
	ldi paramstack & $0FF
	plo psp
	ldi paramstack >> 8
	phi psp
	ldi returnstack & $0FF
	plo rsp
	ldi returnstack >> 8
	phi rsp
	ldi nextd & $0FF
	plo nextpc
	ldi nextd >> 8
	phi nextpc
	ldi docolon & $0FF
	plo colonpc
	ldi docolon >> 8
	phi colonpc
	ldi doconst & $0FF
	plo constpc
	ldi doconst >> 8
	phi constpc
	ldi dovar & $0FF
	plo varpc
	ldi dovar >> 8
	phi varpc
	ldi docreate & $0FF
	plo createpc
	ldi docreate >> 8
	phi createpc
	ldi douser & $0FF
	plo userpc
	ldi douser >> 8
	phi userpc

	sex psp		; do arithmetic on param stack
	lbr cold

; INTERPRETER LOGIC =============================
; See also "defining words" at end of this file
;

;Z lit      -- x    fetch inline literal to stack
; This is the primitive compiled by LITERAL.
	.word link
	.byte 0
link	.set *
	.byte 3,"lit"
lit:
	lda ip	; high byte
 	dec psp
	stxd
	lda ip	; low byte
	str psp
	sep nextpc



; DEFINING WORDS ================================



;C VARIABLE   --      define a Forth variable
;   SCREATE 1 CELLS ALLOT ;

	.word link
	.byte 0
link	.set *
	.byte 8,"VARIABLE"
VARIABLE:
	sep colonpc
	.word SCREATE,ONE,CELLS,ALLOT,EXIT

; DOVAR, code action of VARIABLE, entered by sep varpc

	sep nextpc
dovar:  		; -- a-addr
	ghi codepc	; high byte
	dec psp
	stxd
	glo codepc	; low byte
	str psp
	br dovar - 1	; reset varpc

; DOCREATE, code action of CREATE'd word
	sep codepc
docreate:
	lda codepc		; high byte of DOES> part
	phi temppc
	lda codepc		; low byte of DOES>
	plo temppc

	ghi codepc		; push PFA to param stack
	dec psp
	stxd
	glo codepc
	str psp

	ghi temppc		; need to enter code field
	phi codepc		; with codepc
	glo temppc
	plo codepc
	br docreate - 1	; reset createpc

;C CONSTANT   n --      define a Forth constant
;   (CREATE) constpc ,CF ,
	.word link
	.byte 0
link	.set *
	.byte 8,"CONSTANT"
CONSTANT:
	sep colonpc
	.word XCREATE,LIT,constpc,COMMACF,COMMA,EXIT

; DOCONST, code action of CONSTANT,
; entered by sep constpc

	sep nextpc
doconst:  ; -- x
	lda codepc		; high byte
	dec psp
	stxd
	lda codepc		; low byte
	str psp
	br doconst - 1	; reset constpc

;Z USER     n --        define user variable 'n'
;   (CREATE) userpc ,CF ,
	.word link
	.byte 0
link	.set *
	.byte 4,"USER"
USER:
	sep colonpc
	.word XCREATE,lit,userpc,COMMACF,COMMA,EXIT

; DOUSER, code action of USER,
; entered by sep userpc

	sep nextpc
douser:  ; -- a-addr	; assumes user area is page-aligned
			; and no more than 256 user variables
	ldi userarea >> 8	; address high byte
	dec psp
	stxd
	inc codepc	; point to LSB of user offset
	lda codepc	; ldn codepc is IDL!
	str psp
	br douser - 1	; reset userpc

; STACK OPERATIONS ==============================


;C ?DUP     x -- 0 | x x    DUP if nonzero
	.word link
	.byte 0
link	.set *
	.byte 4,"?DUP"
QDUP:
	lda psp		; get low byte
	or		; point to high byte
	dec psp
	bnz DUP
	sep nextpc

;C DUP      x -- x x      duplicate top of stack
	.word link
	.byte 0
link	.set *
	.byte 3,"DUP"
DUP:
	lda psp		; lo byte
	plo temp1
	ldn psp		; high byte
	dec psp
	dec psp
	stxd
	glo temp1
	str psp
	sep  nextpc

;C SWAP     x1 x2 -- x2 x1    swap top two items
	.word link
	.byte 0
link	.set *
	.byte 4,"SWAP"
SWAP:
	lda psp		; x2 lo
	plo temp2
	lda psp		; x2 hi
	phi temp2
	lda psp		; x1 lo
	plo temp1
	ldn psp		; x1 hi
	phi temp1

	ghi temp2
	stxd
 	glo temp2
	stxd
	ghi temp1
	stxd
	glo temp1
	str psp
	sep nextpc

;C OVER    x1 x2 -- x1 x2 x1   per stack diagram
	.word link
	.byte 0
link	.set *
	.byte 4,"OVER"
OVER:
	inc psp
	inc psp
	lda psp		; x1 lo
	plo temp1
	ldn psp		; x1 hi

	dec psp
	dec psp
	dec psp
	dec psp
	stxd
	glo temp1
	str psp
	sep nextpc

;C ROT    x1 x2 x3 -- x2 x3 x1  per stack diagram
	.word link
	.byte 0
link	.set *
	.byte 3,"ROT"
ROT:
	lda psp
	plo temp3
	lda psp
	phi temp3
	lda psp
	plo temp2
	lda psp
	phi temp2
	lda psp
	plo temp1
	ldn psp
	phi temp1

	ghi temp2
	stxd
	glo temp2
	stxd
	ghi temp3
	stxd
	glo temp3
	stxd
	ghi temp1
	stxd
	glo temp1
	str psp
	sep nextpc

;X NIP    x1 x2 -- x2           per stack diagram
	.word link
	.byte 0
link	.set *
	.byte 3,"NIP"
NIP:
	lda psp		; x2 lo
	plo temp2
	lda psp		; x2 hi
	inc psp
	stxd
	glo temp2
	str psp
	sep nextpc

;X TUCK   x1 x2 -- x2 x1 x2     per stack diagram
	.word link
	.byte 0
link	.set *
	.byte 4,"TUCK"
TUCK:
	lda psp		; x2 lo
	plo temp2
	lda psp		; x2 hi
	phi temp2
	lda psp		; x1 lo
	plo temp1
	ldn psp		; x1 hi
	phi temp1

	ghi temp2
	stxd
	glo temp2
	stxd
	ghi temp1
	stxd
	glo temp1
	stxd
	ghi temp2
	stxd
	glo temp2
	str psp
	sep nextpc


;C R@    -- x     R: x -- x   fetch from rtn stk
	.word link
	.byte 0
link	.set *
	.byte 2,"R@"
RFETCH:
	lda rsp		; x hi
	dec psp
	stxd
	ldn rsp		; x lo
	str psp
	dec rsp
	sep nextpc

;Z SP@  -- a-addr       get data stack pointer
	.word link
	.byte 0
link	.set *
	.byte 3,"SP@"
SPFETCH:
	glo psp
	plo temp1
	ghi psp
	dec psp
	stxd
	glo temp1
	str psp
	sep nextpc

;Z SP!  a-addr --       set data stack pointer
	.word link
	.byte 0
link	.set *
	.byte 3,"SP!"
SPSTORE:
	lda psp		; a lo
	plo temp1
	ldn psp		; a hi
	phi psp
	glo temp1
	plo psp
	sep nextpc

;Z RP@  -- a-addr       get return stack pointer
	.word link
	.byte 0
link	.set *
	.byte 3,"RP@"
RPFETCH:
	ghi rsp
	dec psp
	stxd
	glo rsp
	str psp
	sep nextpc

;Z RP!  a-addr --       set return stack pointer
	.word link
	.byte 0
link	.set *
	.byte 3,"RP!"
RPSTORE:
	lda psp
	plo rsp
	lda psp
	phi rsp
	sep nextpc

; MEMORY AND I/O OPERATIONS =====================



;C C!      char c-addr --    store char in memory
	.word link
	.byte 0
link	.set *
	.byte 2,"C!"
CSTORE:
	lda psp		; a lo
	plo temp1
	lda psp		; a hi
	phi temp1
	lda psp		; x lo
	str temp1
	inc psp		; toss x hi
	sep nextpc

;C @       a-addr -- x   fetch cell from memory
	.word link
	.byte 0
link	.set *
	.byte 1,"@"
FETCH:
	lda psp		; a lo
	plo temp1
	ldn psp		; a hi
	phi temp1
	lda temp1	; x hi
	stxd
	ldn temp1
	str psp		; x lo
	sep nextpc

;C C@     c-addr -- char   fetch char from memory
	.word link
	.byte 0
link	.set *
	.byte 2,"C@"
CFETCH:
	lda psp		; a lo
	plo temp1
	ldn psp		; a hi
	phi temp1
	ldi 0
	stxd		; zero high byte
	ldn temp1	; c lo
	str psp
	sep nextpc

; ARITHMETIC AND LOGICAL OPERATIONS =============

;C +       n1/u1 n2/u2 -- n3/u3     add n1+n2
	.word link
	.byte 0
link	.set *
	.byte 1,"+"
PLUS:
	lda psp		; n2 lo
	inc psp
	add		; n1 lo
	stxd		; n1+n2 lo
	lda psp		; n2 hi
	inc psp
	adc		; n1 hi
	stxd		; n1+n2 hi
	sep nextpc

;X M+       d n -- d         add single to double
	.word link
	.byte 0
link	.set *
	.byte 2,"M+"
MPLUS:
; Double on stack:  byte[1] byte[0] byte[3] byte[2]

	lda psp		; n lo
	plo temp1
	lda psp		; n hi
	phi temp1

	inc psp
	inc psp		; point to d[0]
	glo temp1
	add
	str psp		; update d[0]
	inc psp		; point to d[1]
	ghi temp1
	adc
	stxd		; update d[1]
	dec psp
	dec psp		; point to d[2]
	ghi temp1	; sign of n
	ani $80
	bnz mp1		; negative ->
	ldi 0		; positive sign extend
	br mp2
mp1:
	ldi $FF	; negative sign extend
mp2:
	phi temp1
	adc
	str psp		; update d[2]
	inc psp		; point to d[3]
	ghi temp1	; get sign extension
	adc
	stxd		; update d[3]
	sep nextpc

;C -      n1/u1 n2/u2 -- n3/u3    subtract n1-n2
	.word link
	.byte 0
link	.set *
	.byte 1,"-"
MINUS:
	lda psp		; n2 lo
	inc psp
	sd		; n1 lo
	stxd		; n1-n2 lo
	lda psp		; n2 hi
	inc psp
	sdb
	stxd		; n1-n2 hi
	sep nextpc


;C NEGATE   x1 -- x2            two's complement
	.word link
	.byte 0
link	.set *
	.byte 6,"NEGATE"
NEGATE:
	ldn psp		; x1 lo
	sdi $0
	str psp
	inc psp
	ldn psp		; x1 hi
	sdbi $0
	stxd
	sep nextpc

;Z ><      x1 -- x2         swap bytes (not ANSI)
	.word link
	.byte 0
link	.set *
	.byte 2,"><"
swapbytes:
	lda psp
	plo temp1
	ldn psp
	phi temp1
	glo temp1
	stxd
	ghi temp1
	str psp
	sep nextpc

;C 2*      x1 -- x2         arithmetic left shift
	.word link
	.byte 0
link	.set *
	.byte 2,"2*"
TWOSTAR:
	ldn psp		; x lo
	shl		; shift in zero
	str psp
	inc psp
	ldn psp		; x hi
	shlc		; shift in carry
	stxd
	sep nextpc

;C 2/      x1 -- x2        arithmetic right shift
	.word link
	.byte 0
link	.set *
	.byte 2,"2/"
TWOSLASH:		; sign extension
	inc psp
	ldn psp		; x hi
	shlc		; get msb to carry
	ldn psp		; x hi again
	shrc		; shift in carry
	stxd
	ldn psp		; xlo
	shrc
	str psp
	sep nextpc

;C LSHIFT  x1 u -- x2    logical L shift u places
	.word link
	.byte 0
link	.set *
	.byte 6,"LSHIFT"
LSHIFT:
	lda psp		; u lo
	plo temp1
	inc psp		; ignore u hi
lshloop:
	bz shdone

	ldn psp		; lo
	shl		; shift in zero
	str psp
	inc psp
	ldn psp		; hi
	shlc		; shift in carry
	stxd

	dec temp1	; count shifts
	glo temp1
	br lshloop

;C RSHIFT  x1 u -- x2    logical R shift u places
	.word link
	.byte 0
link	.set *
	.byte 6,"RSHIFT"
RSHIFT:
	lda psp		; u lo
	plo temp1
	inc psp		; ignore u hi
rshloop:
	bz shdone

	inc psp
	ldn psp		; hi
	shr		; shift in zero
	stxd
	ldn psp		; lo
	shrc		; shift in carry
	str psp

	dec temp1	; count shifts
	glo temp1
	br rshloop
shdone:
	sep nextpc



; COMPARISON OPERATIONS =========================

;C 0=     n/u -- flag    return true if TOS=0
	.word link
	.byte 0
link	.set *
	.byte 2,"0="
ZEROEQUAL:
	lda psp
	bnz xfalse
	ldn psp
	bnz xfalse
xtrue:
	ldi $FF
	stxd
	str psp
	sep nextpc
xfalse:
	ldi $0
	stxd
	str psp
	sep nextpc

;C 0<     n -- flag      true if TOS negative
	.word link
	.byte 0
link	.set *
	.byte 2,"0<"
ZEROLESS:
	inc psp
	ldn psp
	shlc		; sign -> carry
	bdf xtrue
	br xfalse

;C =      x1 x2 -- flag         test x1=x2
	.word link
	.byte 0
link	.set *
	.byte 1,"="
EQUAL:
	lda psp		; low byte x2
	inc psp
	sm		; low byte x1
	inc psp
	bnz xfalse
	dec psp
	dec psp
	lda psp		; high byte x2
	inc psp
	sm
	bnz xfalse
	br xtrue

;X <>     x1 x2 -- flag    test not eq (not ANSI)
	.word link
	.byte 0
link	.set *
	.byte 2,"<>"
NOTEQUAL:
	sep colonpc
	.word EQUAL,ZEROEQUAL,EXIT

;C <      n1 n2 -- flag        test n1<n2, signed
	.word link
	.byte 0
link	.set *
	.byte 1,"<"
LESS:
	lda psp		; n2 lo
	plo temp2
	lda psp		; n2 hi
	phi temp2
	inc psp		; point to n1 hi
	xor		; compare sign of n1 and n2
	shl
	bdf less2	; different signs ->
	ghi temp2	; n2
less4:
	sm		; n2 - n1 hi
	bz less3	; same, go check lo
	bdf xtrue
	br xfalse
less3:
	dec psp		; point to n1 lo
	glo temp2
	sm
	inc psp		; point to n1 hi
	bz xfalse
	bdf xtrue
	br xfalse
less2:			; here if signs are different
	ghi temp2	; n2 hi
	shl
	bnf xtrue	; positive->
	br xfalse

;C >     n1 n2 -- flag         test n1>n2, signed
	.word link
	.byte 0
link	.set *
	.byte 1,">"
GREATER:
	sep colonpc
	.word SWAP,LESS,EXIT

;C U<    u1 u2 -- flag       test u1<u2, unsigned
	.word link
	.byte 0
link	.set *
	.byte 2,"U<"
ULESS:
	lda psp		; u2 lo
	plo temp2
	lda psp		; u2 hi
	phi temp2
	inc psp		; point to u1 hi
	br less4

;X U>    u1 u2 -- flag     u1>u2 unsgd (not ANSI)
	.word link
	.byte 0
link	.set *
	.byte 2,"U>"
UGREATER:
	sep colonpc
	.word SWAP,ULESS,EXIT

; LOOP AND BRANCH OPERATIONS ====================

	.page		; avoid out-of-page branches

;Z branch   --                  branch always
	.word link
	.byte 0
link	.set *
	.byte 6,"branch"
branch:
	lda ip		; dest hi
	phi temp1
	ldn ip		; dest lo
	plo ip
	ghi temp1
	phi ip
	sep nextpc

;Z ?branch   x --              branch if TOS zero
	.word link
	.byte 0
link	.set *
	.byte 7,"?branch"
qbranch:
	lda psp		; TOS lo
	or		; TOS hi
	inc psp
	bz branch
	inc ip		; skip destination
	inc ip
	sep nextpc

;Z (do)    n1|u1 n2|u2 --  R: -- sys1 sys2
;Z                          run-time code for DO
; '83 and ANSI standard loops terminate when the
; boundary of limit-1 and limit is crossed, in
; either direction.  The RCA1802 doesn't have signed
; overflow logic. (index-limit) is stored on the return
; stack, and the carry bit is used to detect crossing.
; For (+LOOP) with a negative increment, the logic
; is slightly different.
; The limit itself is also stored for use by I.

	.word link
	.byte 0
link	.set *
	.byte 4,"(do)"
xdo:
	lda psp		; index lo
	plo temp1
	lda psp		; index hi
	phi temp1

	lda psp		; limit lo
	dec rsp		; push to return stack
	str rsp		; for use by I
	ldn psp		; limit hi
	dec rsp
	str rsp

	dec psp		; point to limit lo
	glo temp1	; index lo
	sm		; index - limit lo
	dec rsp
	str rsp		; push to return stack

	inc psp		; point to limit hi
	ghi temp1
	smb		; index - limit hi
	dec rsp
	str rsp		; push to return stack

	inc psp
	sep nextpc

;Z (loop)   R: sys1 sys2 --  | sys1 sys2
;Z                        run-time code for LOOP
; Add 1 to the loop index.  If loop terminates,
; clean up the return stack and skip the branch.
; Else take the inline branch.  Note that LOOP
; terminates when index=0.
	.word link
	.byte 0
link	.set *
	.byte 6,"(loop)"
xloop:
	sex rsp		; do arithmetic on return stack
	inc rsp		; low byte of index
	ldi 1
	add		; increment
	stxd
	ldi 0
	adc		; high byte
	str rsp
	sex psp		; restore X
	bnf branch	; no carry, continue loop
	br loopdone

;Z (+loop)   n --   R: sys1 sys2 --  | sys1 sys2
;Z                        run-time code for +LOOP
; Add n to the loop index.  If loop terminates,
; clean up the return stack and skip the branch.
; Else take the inline branch.
	.word link
	.byte 0
link	.set *
	.byte 7,"(+loop)"
xplusloop:
	lda psp		; increment lo
	plo temp1
	lda psp		; increment hi
	phi temp1
	sex rsp		; do arithmetic on return stack
	inc rsp		; lo byte of index'
	glo temp1
	add
	stxd		; update low byte
	ghi temp1
	adc
	str rsp		; update high byte
	sex psp		; restore X

	ghi temp1	;
	ani $80	; sign of increment
	bz xloopup	; positive ->
			; counting down
	bdf branch	; continue looping
	br loopdone

xloopup:		; counting up
	bnf branch	; continue looping

loopdone:
	inc ip		; ignore branch destination
	inc ip
	br unloop

;C I        -- n   R: sys1 sys2 -- sys1 sys2
;C                  get the innermost loop index
	.word link
	.byte 0
link	.set *
	.byte 1,"I"
II:
	lda rsp		; index hi
	dec psp		; push to param stack
	stxd
	lda rsp		; index lo
	stxd
	lda rsp		; limit hi
	stxd
	ldn rsp		; limit lo
	str psp

	dec rsp		; restore return stack
	dec rsp
	dec rsp
	lbr PLUS	; add limit back to index

;C J        -- n   R: 4*sys -- 4*sys
;C                  get the second loop index
	.word link
	.byte 0
link	.set *
	.byte 1,"J"
JJ:
	inc rsp		; skip outer loop params
	inc rsp
	inc rsp
	inc rsp

	lda rsp		; index hi
	dec psp		; push to param stack
	stxd
	lda rsp		; index lo
	stxd
	lda rsp		; limit hi
	stxd
	ldn rsp		; limit lo
	str psp

	dec rsp		; restore return stack
	dec rsp
	dec rsp

	dec rsp
	dec rsp
	dec rsp
	dec rsp
	lbr PLUS	; add limit back to index

;C UNLOOP   --   R: sys1 sys2 --  drop loop parms
	.word link
	.byte 0
link	.set *
	.byte 6,"UNLOOP"
UNLOOP:
	inc rsp		; drop loop params
	inc rsp		; from return stack
	inc rsp
	inc rsp
	sep nextpc

; MULTIPLY AND DIVIDE ===========================

	.page		; avoid out-of-page branches

;C UM*     u1 u2 -- ud   unsigned 16x16->32 mult.
	.word link
	.byte 0
link	.set *
	.byte 3,"UM*"
UMSTAR:

	lda psp		; u2 lo
	plo temp2
	lda psp		; u2 hi
	phi temp2
	lda psp		; u1 lo
	plo temp1
	ldn psp		; u1 hi
	phi temp1

	ldi 0
	stxd
	stxd
	stxd
	str psp		; clear double result

	plo temp3
	phi temp3	; extend multiplier

; Result on stack:  byte[1] byte[0] byte[3] byte[2]

	ldi 16
	plo temp4	; bit counter
	inc psp
	inc psp
umloop:			; PSP points to byte[0] of result

	ghi temp1	; shift u1 right
	shr
	phi temp1
	glo temp1
	shrc
	plo temp1
	bnf um_noadd	; if LSB was 1, add in multiplier

	glo temp2	; byte[0]
	add
	str psp
	inc psp
	ghi temp2	; byte[1]
	adc
	stxd
	dec psp
	dec psp
	glo temp3	; byte[2]
	adc
	str psp
	inc psp
	ghi temp3	; byte[3]
	adc
	str psp		; restore PSP
	inc psp

um_noadd:		; shift multiplier left
	glo temp2
	shl
	plo temp2
	ghi temp2
	shlc
	phi temp2
	glo temp3
	shlc
	plo temp3
	ghi temp3
	shlc
	phi temp3

	dec temp4	; count bits
	glo temp4
	bnz umloop

	dec psp
	dec psp		; point to byte[2]

	sep nextpc

;C UM/MOD   ud u1 -- u2 u3   unsigned 32/16->16
	.word link
	.byte 0
link	.set *
	.byte 6,"UM/MOD"
UMSLASHMOD:
	lda psp		; get divisor u1
	plo temp1
	lda psp
	phi temp1

	ldi 0		; extend divisor to 32 bits
	plo temp2
	phi temp2

	plo temp3	; initialize quotient
	phi temp3

; Dividend on stack:  byte[1] byte[0] byte[3] byte[2]

	ldi 16
	plo temp4	; bit counter
	inc psp

ummodloop:		; PSP points to byte[3] of dividend
			; shift divisor right
	ghi temp1
	shr
	phi temp1
	glo temp1
	shrc
	plo temp1
	ghi temp2
	shrc
	phi temp2
	glo temp2
	shrc
	plo temp2

	ghi temp1	; MSB of divisor
	sd		; dividend - divisor
	bnf umm3	; doesn't go ->
	bnz umd3	; goes ->

	dec psp		; byte[2]
	glo temp1
	sd

	inc psp		; byte[3]
	bnf umm3	; doesn't go ->
	bnz umd3	; goes ->

	inc psp
	inc psp		; byte[1]
	ghi temp2
	sd

	dec psp		; byte[0]
	bnf umm0	; doesn't go ->
	bnz umd0	; goes ->

	glo temp2
	sd
	bnf umm0	; doesn't go ->
	br umd0		; goes ->
umd3:
	inc psp
umd0:

; subtract divisor from dividend
; PSP pointing to byte[0] of dividend
	glo temp2
	sd
	str psp
	inc psp		; byte[1]
	ghi temp2
	sdb
	stxd
	dec psp
	dec psp		; byte[2]
	glo temp1
	sdb
	str psp
	inc psp		; byte[3]
	ghi temp1
	sdb
	str psp
	smi 0		; set carry
	br umm3

umm0:	dec psp

umm3:			; PSP pointing to byte[3] of dividend
			; shift carry into quotient
	glo temp3
	shlc
	plo temp3
	ghi temp3
	shlc
	phi temp3

	dec temp4	; count bits
	glo temp4
	bnz ummodloop

; remainder is byte[0] and byte[1] of the dividend

	ghi temp3	; get msb of quotient
	stxd
	glo temp3	; get lsb of quotient
	str psp
	sep nextpc

; BLOCK AND STRING OPERATIONS ===================

;C FILL   c-addr u char --  fill memory with char
	.word link
	.byte 0
link	.set *
	.byte 4,"FILL"
FILL:
	lda psp
	plo temp1	; char
	inc psp
	lda psp
	plo temp2	; count lo
	lda psp
	phi temp2	; count hi
	lda psp
	plo temp3	; dest lo
	lda psp
	phi temp3	; dest hi

fillloop:
	glo temp2	; check for zero
	bnz fillmore
	ghi temp2
	bz filldone	; done->
fillmore:
	glo temp1
	str temp3	; dst byte
	inc temp3
	dec temp2	; count bytes
	br fillloop
filldone:
	sep nextpc

;X CMOVE   c-addr1 c-addr2 u --  move from bottom
; as defined in the ANSI optional String word set
; On byte machines, CMOVE and CMOVE> are logical
; factors of MOVE.  They are easy to implement on
; CPUs which have a block-move instruction.
	.word link
	.byte 0
link	.set *
	.byte 5,"CMOVE"
CMOVE:
	lda psp
	plo temp1	; count lo
	lda psp
	phi temp1	; count hi
	lda psp
	plo temp2	; dest lo
	lda psp
	phi temp2	; dest hi
	lda psp
	plo temp3	; src lo
	lda psp
	phi temp3	; src hi
cmoveloop:
	glo temp1	; check for zero
	bnz cmovemore
	ghi temp1
	bz cmovedone	; done->
cmovemore:
	lda temp3	; src byte
	str temp2	; dest
	inc temp2
	dec temp1	; count bytes
	br cmoveloop
cmovedone:
	sep nextpc


;X CMOVE>  c-addr1 c-addr2 u --  move from top
; as defined in the ANSI optional String word set
	.word link
	.byte 0
link	.set *
	.byte 6,"CMOVE>"
CMOVEUP:
	sep colonpc
	.word TOR			; count to return stack
	.word RFETCH,PLUS		; end of dest + 1
	.word SWAP,RFETCH,PLUS	; end of src + 1
	.word RFROM		; count
	.word xcmoveup,EXIT

xcmoveup:
	lda psp
	plo temp1	; count lo
	lda psp
	phi temp1	; count hi
	lda psp
	plo temp2	; src lo
	lda psp
	phi temp2	; src hi
	dec temp2	; end of src

	lda psp
	plo temp3	; dst lo
	lda psp
	phi temp3	; dst hi
	dec temp3	; end of dst
	sex temp3	; so we can use stxd

xcmoveloop:
	glo temp1	; check for zero
	bnz xcmovemore
	ghi temp1
	bz xcmovedone	; done->
xcmovemore:
	ldn temp2	; src byte
	dec temp2
	stxd		; dest
	dec temp1	; count bytes
	br xcmoveloop
xcmovedone:
	sex psp		; restore X
	sep nextpc

;Z SKIP   c-addr u c -- c-addr' u'
;Z                          skip matching chars
; Although SKIP, SCAN, and S= are perhaps not the
; ideal factors of WORD and FIND, they closely
; follow the string operations available on many
; CPUs, and so are easy to implement and fast.
	.word link
	.byte 0
link	.set *
	.byte 4,"SKIP"
skip:
	lda psp		; char lo
	plo temp1
	inc psp
	lda psp		; count lo
	plo temp2
	lda psp		; count hi
	phi temp2
	lda psp		; addr lo
	plo temp3
	ldn psp		; addr hi
	phi temp3
	sex temp3	; for comparisons

skloop:			; is count zero?
	glo temp2
	bnz sk1
	ghi temp2
	bz skdone
sk1:
	glo temp1	; get char
	sm
	bnz skdone	; not equal ->
	inc temp3	; increment address
	dec temp2	; decrement count
	br skloop
skdone:
	sex psp		; restore X
	ghi temp3	; push pointer
	stxd
	glo temp3
	stxd
	ghi temp2	; push remaining count
	stxd
	glo temp2
	str psp
	sep nextpc

;Z SCAN    c-addr u c -- c-addr' u'
;Z                      find matching char
	.word link
	.byte 0
link	.set *
	.byte 4,"SCAN"
scan:
	lda psp		; char lo
	plo temp1
	inc psp
	lda psp		; count lo
	plo temp2
	lda psp		; count hi
	phi temp2
	lda psp		; addr lo
	plo temp3
	ldn psp		; addr hi
	phi temp3
	sex temp3	; for comparisons

scloop:			; is count zero?
	glo temp2
	bnz sc1
	ghi temp2
	bz skdone
sc1:
	glo temp1	; get char
	sm
	bz skdone	; equal ->
	inc temp3	; increment address
	dec temp2	; decrement count
	br scloop

;Z S=    c-addr1 c-addr2 u -- n   string compare
;Z             n<0: s1<s2, n=0: s1=s2, n>0: s1>s2
	.word link
	.byte 0
link	.set *
	.byte 2,"S="
sequal:
	lda psp		; count lo
	plo temp3
	lda psp		; count hi
	phi temp3
	lda psp		; addr2 lo
	plo temp2
	lda psp		; addr2 hi
	phi temp2
	lda psp		; addr1 lo
	plo temp1
	ldn psp		; addr1 hi
	phi temp1
	sex temp2	; for comparisons

seqloop:
	glo temp3	; is count zero?
	bnz seq1
	ghi temp3
	bz seqdone
seq1:
	lda temp1
	sm		; subtract (addr1) - (addr2)
	bnz seqdone	; not equal ->
	inc temp2
	dec temp3
	br seqloop

seqdone:
	sex psp		; restore X
	stxd		; push result twice
	str psp
	sep nextpc


;-------------------------------------------------------------------------------

; LISTING 3.
;
; ===============================================
; CamelForth for the RCA 1802
; Copyright (c) 1994,1995 Bradford J. Rodriguez
; Copyright (c) 2009 Harold Rabbie
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; Commercial inquiries should be directed to the author at
; 115 First St., #105, Collingwood, Ontario L9Y 4W3 Canada
; or via email to bj@camelforth.com
;
; ===============================================
; CAMEL18D.ASM: CPU and Model Dependencies
;   Source code is for the A180 assembler.
;   Forth words are documented as follows:
;*   NAME     stack -- stack    description
;   Word names in upper case are from the ANS
;   Forth Core word set.  Names in lower case are
;   "internal" implementation words & extensions.
;
; Direct-Threaded Forth model for RCA 1802
;   cell size is   16 bits (2 bytes)
;   char size is    8 bits (1 byte)
;   address unit is 8 bits (1 byte), i.e.,
;       addresses are byte-aligned.
; ===============================================

; ALIGNMENT AND PORTABILITY OPERATORS ===========
; Many of these are synonyms for other words,
; and so are defined as CODE words.


;Z CELL     -- n                 size of one cell
	.word link
	.byte 0
link	.set *
	.byte 4,"CELL"
CELL:
	sep constpc
	.word 2

;C >BODY    xt -- a-addr      adrs of param field
;   3 + ;                     1802 (3 byte code field for CREATE)
; ANSI 6.1.0550 says that >BODY only applies to CREATE'd words
	.word link
	.byte 0
link	.set *
	.byte 5,">BODY"
TOBODY:
	sep colonpc
    	.word LIT,3,PLUS,EXIT


;Z ,CF    PC --       append a 1-byte code field SEP <PC>
;   HERE LIT SEPCODE OR C, ;  1802 VERSION (1 byte)
	.word link
	.byte 0
link	.set *
	.byte 3,",CF"
COMMACF:
	sep colonpc
	.word LIT,sepcode,ORR	; make it a SEP opcode
	.word CCOMMA,EXIT

;Z ,EXIT    --      append hi-level EXIT action
;   ['] EXIT ,XT ;
; This is made a distinct word, because on an STC
; Forth, it appends a RET instruction, not an xt.
	.word link
	.byte 0
link	.set *
	.byte 5,",EXIT"
CEXIT:
	sep colonpc
	.word LIT,EXIT,COMMAXT,EXIT

; CONTROL STRUCTURES ============================
; These words allow Forth control structure words
; to be defined portably.

;Z ,BRANCH   xt --    append a branch instruction
; xt is the branch operator to use, e.g. qbranch
; or (loop).  It does NOT append the destination
; address.  On the RCA1802 this is equivalent to ,XT.
	.word link
	.byte 0
link	.set *
	.byte 7,",BRANCH"
COMMABRANCH:
	lbr COMMA

;Z ,DEST   dest --        append a branch address
; This appends the given destination address to
; the branch instruction.  On the RCA1802 this is ','
; ...other CPUs may use relative addressing.
	.word link
	.byte 0
link	.set *
	.byte 5,",DEST"
COMMADEST:
	lbr COMMA

;Z !DEST   dest adrs --    change a branch dest'n
; Changes the destination address found at 'adrs'
; to the given 'dest'.  On the Z80 this is '!'
; ...other CPUs may need relative addressing.
	.word link
	.byte 0
link	.set *
	.byte 5,"!DEST"
STOREDEST:
	lbr STORE

; HEADER STRUCTURE ==============================
; The structure of the Forth dictionary headers
; (name, link, immediate flag, and "smudge" bit)
; does not necessarily differ across CPUs.  This
; structure is not easily factored into distinct
; "portable" words; instead, it is implicit in
; the definitions of FIND and CREATE, and also in
; NFA>LFA, NFA>CFA, IMMED?, IMMEDIATE, HIDE, and
; REVEAL.  These words must be (substantially)
; rewritten if either the header structure or its
; inherent assumptions are changed.




;-------------------------------------------------------------------------------


; LISTING 2.
;
; ===============================================
; CamelForth for the RCA 1802
; Copyright (c) 1994,1995 Bradford J. Rodriguez
; ; Copyright (c) 2009 Harold Rabbie
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; Commercial inquiries should be directed to the author at
; 115 First St., #105, Collingwood, Ontario L9Y 4W3 Canada
; or via email to bj@camelforth.com
;
; ===============================================
; CAMEL18H.ASM: High Level Words
;   Source code is for the A180 assembler.
;   Forth words are documented as follows:
;*   NAME     stack -- stack    description
;   Word names in upper case are from the ANS
;   Forth Core word set.  Names in lower case are
;   "internal" implementation words & extensions.
; ===============================================

; SYSTEM VARIABLES & CONSTANTS ==================

;C BL      -- char	an ASCII space
	.word link
	.byte 0
link	.set *
	.byte 2,"BL"
BL:
	sep constpc
	.word $20

;Z tibsize  -- n	 size of TIB
	.word link
	.byte 0
link	.set *
	.byte 7,"TIBSIZE"
TIBSIZE:
	sep constpc
	.word 124	  ; 2 chars safety zone

;X tib     -- a-addr	Terminal Input Buffer
	.word link
	.byte 0
link	.set *
	.byte 3,"TIB"
TIB:
	sep constpc
	.word tibarea

;Z u0      -- a-addr	current user area adrs
;  0 USER U0
	.word link
	.byte 0
link	.set *
	.byte 2,"U0"
U0:
	sep userpc
	.word 0


;Z 'source  -- a-addr	two cells: len, adrs
; 10 USER 'SOURCE
	.word link
	.byte 0
link	.set *
	.byte 7,"\'SOURCE"
TICKSOURCE:
	sep userpc
	.word 10


;Z hp       -- a-addr	HOLD pointer
;   16 USER HP
	.word link
	.byte 0
link	.set *
	.byte 2,"HP"
HP:
	sep userpc
	.word 16

;Z LP       -- a-addr	Leave-stack pointer
;   18 USER LP
	.word link
	.byte 0
link	.set *
	.byte 2,"LP"
LP:
	sep userpc
	.word 18

;Z s0       -- a-addr	end of parameter stack
	.word link
	.byte 0
link	.set *
	.byte 2,"S0"
S0:
	sep constpc
	.word paramstack

;X PAD       -- a-addr	user PAD buffer
;			= end of hold area!
	.word link
	.byte 0
link	.set *
	.byte 3,"PAD"
PAD:
	sep constpc
	.word padarea

;Z l0       -- a-addr	bottom of Leave stack
	.word link
	.byte 0
link	.set *
	.byte 2,"L0"
L0:
	sep constpc
	.word leavestack

;Z r0       -- a-addr	end of return stack
	.word link
	.byte 0
link	.set *
	.byte 2,"R0"
R0:
	sep constpc
	.word returnstack

;Z uinit    -- addr	initial values for user area
	.word link
	.byte 0
link	.set *
	.byte 5,"UINIT"
UINIT:
	sep varpc
	.word 0,0,10,0	; reserved,>IN,BASE,STATE
	.word enddict	; DP
	.word 0,0		; SOURCE init'd elsewhere
	.word lastword	; LATEST
	.word 0		; HP init'd elsewhere

;Z #init    -- n	#bytes of user area init data
	.word link
	.byte 0
link	.set *
	.byte 5,"#INIT"
NINIT:
	sep constpc
	.word 18

; ARITHMETIC OPERATORS ==========================

;C S>D    n -- d	single -> double prec.
;   DUP 0< ;
	.word link
	.byte 0
link	.set *
	.byte 3,"S>D"
STOD:
	inc psp
	ldn psp		; n hi
	dec psp
	shlc		; sign to carry
	lbdf MINUSONE
	lbr ZERO

;Z ?NEGATE  n1 n2 -- n3  negate n1 if n2 negative
;   0< IF NEGATE THEN ;	...a common factor
	.word link
	.byte 0
link	.set *
	.byte 7,"?NEGATE"
QNEGATE:
	inc psp
	lda psp		; n2 hi
	shlc		; sign to carry
	lbdf NEGATE
	sep nextpc

;C ABS     n1 -- +n2	absolute value
;   DUP ?NEGATE ;
	.word link
	.byte 0
link	.set *
	.byte 3,"ABS"
ABS:
	inc psp
	ldn psp		; n1 hi
	dec psp
	shlc		; sign to carry
	lbdf NEGATE
	sep nextpc


;Z ?DNEGATE  d1 n -- d2	negate d1 if n negative
;   0< IF DNEGATE THEN ;       ...a common factor
	.word link
	.byte 0
link	.set *
	.byte 8,"?DNEGATE"
QDNEGATE:
	sep colonpc
	.word ZEROLESS,qbranch,DNEG1,DNEGATE
DNEG1:  .word EXIT

;X DABS     d1 -- +d2	absolute value dbl.prec.
;   DUP ?DNEGATE ;
	.word link
	.byte 0
link	.set *
	.byte 4,"DABS"
DABS:
	sep colonpc
	.word DUP,QDNEGATE,EXIT

;C M*     n1 n2 -- d	signed 16*16->32 multiply
;   2DUP XOR >R	carries sign of the result
;   SWAP ABS SWAP ABS UM*
;   R> ?DNEGATE ;
	.word link
	.byte 0
link	.set *
	.byte 2,"M*"
MSTAR:
	sep colonpc
	.word TWODUP,XORR,TOR
	.word SWAP,ABS,SWAP,ABS,UMSTAR
	.word RFROM,QDNEGATE,EXIT

;C SM/REM   d1 n1 -- n2 n3	symmetric signed div
;   2DUP XOR >R			sign of quotient
;   OVER >R			sign of remainder
;   ABS >R DABS R> UM/MOD
;   SWAP R> ?NEGATE
;   SWAP R> ?NEGATE ;
; Ref. dpANS-6 section 3.2.2.1.
	.word link
	.byte 0
link	.set *
	.byte 6,"SM/REM"
SMSLASHREM:
	sep colonpc
	.word TWODUP,XORR,TOR,OVER,TOR
	.word ABS,TOR,DABS,RFROM,UMSLASHMOD
	.word SWAP,RFROM,QNEGATE,SWAP,RFROM,QNEGATE
	.word EXIT

;C FM/MOD   d1 n1 -- n2 n3	floored signed div'n
;   DUP >R	      divisor
;   2DUP XOR >R	 sign of quotient
;   >R		  divisor
;   DABS R@ ABS UM/MOD
;   SWAP R> ?NEGATE SWAP	apply sign to remainder
;   R> 0< IF			if quotient negative,
;       NEGATE
;       OVER IF			if remainder nonzero,
;	R@ ROT - SWAP 1-	adjust rem,quot
;       THEN
;   THEN  R> DROP ;
; Ref. dpANS-6 section 3.2.2.1.
	.word link
	.byte 0
link	.set *
	.byte 6,"FM/MOD"
FMSLASHMOD:
	sep colonpc
	.word DUP,TOR
	.word TWODUP,XORR,TOR
	.word TOR
	.word DABS,RFETCH,ABS,UMSLASHMOD
	.word SWAP,RFROM,QNEGATE,SWAP
	.word RFROM,ZEROLESS,qbranch,FMMOD1
	.word NEGATE
	.word OVER,qbranch,FMMOD1
	.word RFETCH,ROT,MINUS,SWAP,ONEMINUS
FMMOD1:
	.word RFROM,DROP,EXIT

;C *      n1 n2 -- n3		signed multiply
;   M* DROP ;
	.word link
	.byte 0
link	.set *
	.byte 1,"*"
STAR:
	sep colonpc
	.word MSTAR,DROP,EXIT

;C /MOD   n1 n2 -- n3 n4	signed divide/rem'dr
;   >R S>D R> FM/MOD ;
	.word link
	.byte 0
link	.set *
	.byte 4,"/MOD"
SLASHMOD:
	sep colonpc
	.word TOR,STOD,RFROM,FMSLASHMOD,EXIT

;C /      n1 n2 -- n3		signed divide
;   /MOD nip ;
	.word link
	.byte 0
link	.set *
	.byte 1,"/"
SLASH:
	sep colonpc
	.word SLASHMOD,NIP,EXIT

;C MOD    n1 n2 -- n3		signed remainder
;   /MOD DROP ;
	.word link
	.byte 0
link	.set *
	.byte 3,"MOD"
MOD:
	sep colonpc
	.word SLASHMOD,DROP,EXIT

;C */MOD  n1 n2 n3 -- n4 n5	n1*n2/n3, rem&quot
;   >R M* R> FM/MOD ;
	.word link
	.byte 0
link	.set *
	.byte 5,"*/MOD"
SSMOD:
	sep colonpc
	.word TOR,MSTAR,RFROM,FMSLASHMOD,EXIT

;C */     n1 n2 n3 -- n4	n1*n2/n3
;   */MOD nip ;
	.word link
	.byte 0
link	.set *
	.byte 2,"*/"
STARSLASH:
	sep colonpc
	.word SSMOD,NIP,EXIT

;C MAX    n1 n2 -- n3		signed maximum
;   2DUP < IF SWAP THEN DROP ;
	.word link
	.byte 0
link	.set *
	.byte 3,"MAX"
MAX:
	sep colonpc
	.word TWODUP,LESS,qbranch,MAX1,SWAP
MAX1:   .word DROP,EXIT

;C MIN    n1 n2 -- n3		signed minimum
;   2DUP > IF SWAP THEN DROP ;
	.word link
	.byte 0
link	.set *
	.byte 3,"MIN"
MIN:
	sep colonpc
	.word TWODUP,GREATER,qbranch,MIN1,SWAP
MIN1:   .word DROP,EXIT

; DOUBLE OPERATORS ==============================

;C 2@    a-addr -- x1 x2	fetch 2 cells
;   DUP CELL+ @ SWAP @ ;
;   the lower address will appear on top of stack
	.word link
	.byte 0
link	.set *
	.byte 2,"2@"
TWOFETCH:
	sep colonpc
	.word DUP,CELLPLUS,FETCH,SWAP,FETCH,EXIT

;C 2!    x1 x2 a-addr --	store 2 cells
;   SWAP OVER ! CELL+ ! ;
;   the top of stack is stored at the lower adrs
	.word link
	.byte 0
link	.set *
	.byte 2,"2!"
TWOSTORE:
	sep colonpc
	.word SWAP,OVER,STORE,CELLPLUS,STORE,EXIT



;C 2SWAP  x1 x2 x3 x4 -- x3 x4 x1 x2  per diagram
;   ROT >R ROT R> ;
	.word link
	.byte 0
link	.set *
	.byte 5,"2SWAP"
TWOSWAP:
	sep colonpc
	.word ROT,TOR,ROT,RFROM,EXIT

;C 2OVER  x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2
;   >R >R 2DUP R> R> 2SWAP ;
	.word link
	.byte 0
link	.set *
	.byte 5,"2OVER"
TWOOVER:
	sep colonpc
	.word TOR,TOR,TWODUP,RFROM,RFROM
	.word TWOSWAP,EXIT

; INPUT/OUTPUT ==================================

;C COUNT   c-addr1 -- c-addr2 u	counted->adr/len
;   DUP CHAR+ SWAP C@ ;
	.word link
	.byte 0
link	.set *
	.byte 5,"COUNT"
COUNT:
	sep colonpc
	.word DUP,CHARPLUS,SWAP,CFETCH,EXIT

;C CR      --			output newline
;   0D EMIT 0A EMIT ;
	.word link
	.byte 0
link	.set *
	.byte 2,"CR"
CR:
	sep colonpc
	.word lit,$0D,EMIT,lit,$0A,EMIT,EXIT

;C SPACE   --			output a space
;   BL EMIT ;
	.word link
	.byte 0
link	.set *
	.byte 5,"SPACE"
SPACE:
	sep colonpc
	.word BL,EMIT,EXIT

;C SPACES   n --		output n spaces
;   BEGIN DUP WHILE SPACE 1- REPEAT DROP ;
	.word link
	.byte 0
link	.set *
	.byte 6,"SPACES"
SPACES:
	sep colonpc
SPCS1:  .word DUP,qbranch,SPCS2
	.word SPACE,ONEMINUS,branch,SPCS1
SPCS2:  .word DROP,EXIT

;Z umin     u1 u2 -- u		unsigned minimum
;   2DUP U> IF SWAP THEN DROP ;
	.word link
	.byte 0
link	.set *
	.byte 4,"UMIN"
UMIN:
	sep colonpc
	.word TWODUP,UGREATER,QBRANCH,UMIN1,SWAP
UMIN1:  .word DROP,EXIT

;Z umax    u1 u2 -- u		unsigned maximum
;   2DUP U< IF SWAP THEN DROP ;
	.word link
	.byte 0
link	.set *
	.byte 4,"UMAX"
UMAX:
	sep colonpc
	.word TWODUP,ULESS,QBRANCH,UMAX1,SWAP
UMAX1:  .word DROP,EXIT

;C ACCEPT  c-addr +n -- +n'	get line from term'l
	.word link
	.byte 0
link	.set *
	.byte 6,"ACCEPT"
ACCEPT:
	inp 1			; recognized by simulator
	sep nextpc

;C TYPE    c-addr +n --		type line to term'l
;   ?DUP IF
;     OVER + SWAP DO I C@ EMIT LOOP
;   ELSE DROP THEN ;
	.word link
	.byte 0
link	.set *
	.byte 4,"TYPE"
TYPE:
	sep colonpc
	.word QDUP,QBRANCH,TYP4
	.word OVER,PLUS,SWAP,XDO
TYP3:   .word II,CFETCH,EMIT,XLOOP,TYP3
	.word BRANCH,TYP5
TYP4:   .word DROP
TYP5:   .word EXIT

;Z (S")     -- c-addr u		run-time code for S"
;   R> COUNT 2DUP + ALIGNED >R  ;
	.word link
	.byte 0
link	.set *
	.byte 4,"(S\")"
XSQUOTE:
	sep colonpc
	.word RFROM,COUNT,TWODUP,PLUS,ALIGNED,TOR
	.word EXIT

;C S"       --			compile in-line string
;   COMPILE (S")  [ HEX ]
;   22 WORD C@ 1+ ALIGNED ALLOT ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 2,"S\""
SQUOTE:
	sep colonpc
	.word LIT,XSQUOTE,COMMAXT
	.word LIT,$22,WORD,CFETCH,ONEPLUS
	.word ALIGNED,ALLOT,EXIT

;C ."       --			compile string to print
;   POSTPONE S"  POSTPONE TYPE ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 2,".\""
DOTQUOTE:
	sep colonpc
	.word SQUOTE
	.word LIT,TYPE,COMMAXT
	.word EXIT

; NUMERIC OUTPUT ================================
; Numeric conversion is done l.s.digit first, so
; the output buffer is built backwards in memory.

; Some double-precision arithmetic operators are
; needed to implement ANSI numeric conversion.

;Z UD/MOD   ud1 u2 -- u3 ud4	32/16->32 divide
;   >R 0 R@ UM/MOD  ROT ROT R> UM/MOD ROT ;
	.word link
	.byte 0
link	.set *
	.byte 6,"UD/MOD"
UDSLASHMOD:
	sep colonpc
	.word TOR,ZERO,RFETCH,UMSLASHMOD,ROT,ROT
	.word RFROM,UMSLASHMOD,ROT,EXIT

;Z UD*      ud1 d2 -- ud3	32*16->32 multiply
;   DUP >R UM* DROP  SWAP R> UM* ROT + ;
	.word link
	.byte 0
link	.set *
	.byte 3,"UD*"
UDSTAR:
	sep colonpc
	.word DUP,TOR,UMSTAR,DROP
	.word SWAP,RFROM,UMSTAR,ROT,PLUS,EXIT

;C HOLD  char --		add char to output string
;   -1 HP +!  HP @ C! ;
	.word link
	.byte 0
link	.set *
	.byte 4,"HOLD"
HOLD:
	sep colonpc
	.word MINUSONE,HP,PLUSSTORE
	.word HP,FETCH,CSTORE,EXIT

;C <#    --			 begin numeric conversion
;   PAD HP ! ;			(initialize Hold Pointer)
	.word link
	.byte 0
link	.set *
	.byte 2,"<#"
LESSNUM:
	sep colonpc
	.word PAD,HP,STORE,EXIT

;Z >digit   n -- c		convert to 0..9A..Z
;   [ HEX ] DUP 9 > 7 AND + 30 + ;
	.word link
	.byte 0
link	.set *
	.byte 6,">DIGIT"
TODIGIT:
	sep colonpc
	.word DUP,LIT,9,GREATER,LIT,7,ANDD,PLUS
	.word LIT,$30,PLUS,EXIT

;C #     ud1 -- ud2		convert 1 digit of output
;   BASE @ UD/MOD ROT >digit HOLD ;
	.word link
	.byte 0
link	.set *
	.byte 1,"#"
NUM:
	sep colonpc
	.word BASE,FETCH,UDSLASHMOD,ROT,TODIGIT
	.word HOLD,EXIT

;C #S    ud1 -- ud2		convert remaining digits
;   BEGIN # 2DUP OR 0= UNTIL ;
	.word link
	.byte 0
link	.set *
	.byte 2,"#S"
NUMS:
	sep colonpc
NUMS1:  .word NUM,TWODUP,ORR,ZEROEQUAL,qbranch,NUMS1
	.word EXIT

;C #>    ud1 -- c-addr u	end conv., get string
;   2DROP HP @ PAD OVER - ;
	.word link
	.byte 0
link	.set *
	.byte 2,"#>"
NUMGREATER:
	sep colonpc
	.word TWODROP,HP,FETCH,PAD,OVER,MINUS,EXIT

;C SIGN  n --			add minus sign if n<0
;   0< IF 2D HOLD THEN ;
	.word link
	.byte 0
link	.set *
	.byte 4,"SIGN"
SIGN:
	sep colonpc
	.word ZEROLESS,qbranch,SIGN1,LIT,$2D,HOLD
SIGN1:  .word EXIT

;C U.    u --			display u unsigned
;   <# 0 #S #> TYPE SPACE ;
	.word link
	.byte 0
link	.set *
	.byte 2,"U."
UDOT:
	sep colonpc
	.word LESSNUM,ZERO,NUMS,NUMGREATER,TYPE
	.word SPACE,EXIT

;C .     n --			display n signed
;   <# DUP ABS 0 #S ROT SIGN #> TYPE SPACE ;
	.word link
	.byte 0
link	.set *
	.byte 1,"."
DOT:
	sep colonpc
	.word LESSNUM,DUP,ABS,ZERO,NUMS
	.word ROT,SIGN,NUMGREATER,TYPE,SPACE,EXIT
	
; INTERPRETER ===================================
; Note that NFA>LFA, NFA>CFA, IMMED?, and FIND
; are dependent on the structure of the Forth
; header.  This may be common across many CPUs,
; or it may be different.

;C SOURCE   -- adr n	current input buffer
;   'SOURCE 2@ ;	length is at lower adrs
	.word link
	.byte 0
link	.set *
	.byte 6,"SOURCE"
SOURCE:
	sep colonpc
	.word TICKSOURCE,TWOFETCH,EXIT

;X /STRING  a u n -- a+n u-n	trim string
;   ROT OVER + ROT ROT - ;
	.word link
	.byte 0
link	.set *
	.byte 7,"/STRING"
SLASHSTRING:
	sep colonpc
	.word ROT,OVER,PLUS,ROT,ROT,MINUS,EXIT

;Z >counted  src n dst --	copy to counted str
;   2DUP C! CHAR+ SWAP CMOVE ;
	.word link
	.byte 0
link	.set *
	.byte 8,">COUNTED"
TOCOUNTED:
	sep colonpc
	.word TWODUP,CSTORE,CHARPLUS,SWAP,CMOVE,EXIT

;C WORD   char -- c-addr n	word delim'd by char
;   DUP  SOURCE >IN @ /STRING	-- c c adr n
;   DUP >R   ROT SKIP		-- c adr' n'
;   OVER >R  ROT SCAN		-- adr" n"
;   DUP IF CHAR- THEN		skip trailing delim.
;   R> R> ROT -   >IN +!	update >IN offset
;   TUCK -			-- adr' N
;   HERE >counted		--
;   HERE			-- a
;   BL OVER COUNT + C! ;	append trailing blank
	.word link
	.byte 0
link	.set *
	.byte 4,"WORD"
WORD:
	sep colonpc
	.word DUP,SOURCE,TOIN,FETCH,SLASHSTRING
	.word DUP,TOR,ROT,SKIP
	.word OVER,TOR,ROT,SCAN
	.word DUP,qbranch,WORD1,ONEMINUS  ; char-
WORD1:  .word RFROM,RFROM,ROT,MINUS,TOIN,PLUSSTORE
	.word TUCK,MINUS
	.word HERE,TOCOUNTED,HERE
	.word BL,OVER,COUNT,PLUS,CSTORE,EXIT

;Z NFA>LFA   nfa -- lfa		name adr -> link field
;   3 - ;
	.word link
	.byte 0
link	.set *
	.byte 7,"NFA>LFA"
NFATOLFA:
	ldn psp		; lo
	smi $3
	str psp
	inc psp
	ldn psp		; hi
	smbi $0
	stxd
	sep nextpc

;Z NFA>CFA   nfa -- cfa	name adr -> code field
;   COUNT 7F AND + ;	mask off 'smudge' bit
	.word link
	.byte 0
link	.set *
	.byte 7,"NFA>CFA"
NFATOCFA:
	sep colonpc
	.word COUNT,LIT,$07F,ANDD,PLUS,EXIT

;Z IMMED?    nfa -- f	fetch immediate flag
;   1- C@ ;		nonzero if immed
	.word link
	.byte 0
link	.set *
	.byte 6,"IMMED?"
IMMEDQ:
	sep colonpc
	.word ONEMINUS,CFETCH,EXIT

;C FIND   c-addr -- c-addr 0	if not found
;C		  xt  1		if immediate
;C		  xt -1		if "normal"
;   LATEST @ BEGIN		-- a nfa
;       2DUP OVER C@ CHAR+	-- a nfa a nfa n+1
;       S=			-- a nfa f
;       DUP IF
;	   DROP
;	   NFA>LFA @ DUP	-- a link link
;       THEN
;   0= UNTIL			-- a nfa  OR  a 0
;   DUP IF
;       NIP DUP NFA>CFA		-- nfa xt
;       SWAP IMMED?		-- xt iflag
;       0= 1 OR			-- xt 1/-1
;   THEN ;
	.word link
	.byte 0
link	.set *
	.byte 4,"FIND"
FIND:
	sep colonpc
	.word LATEST,FETCH
FIND1:  .word TWODUP,OVER,CFETCH,CHARPLUS
	.word SEQUAL,DUP,qbranch,FIND2
	.word DROP,NFATOLFA,FETCH,DUP
FIND2:  .word ZEROEQUAL,qbranch,FIND1
	.word DUP,qbranch,FIND3
	.word NIP,DUP,NFATOCFA
	.word SWAP,IMMEDQ,ZEROEQUAL,ONE,ORR
FIND3:  .word EXIT


;Z DIGIT?   c -- n -1		if c is a valid digit
;Z	    -- x  0   otherwise
;   [ HEX ] DUP 39 > 100 AND +	silly looking
;   DUP 140 > 107 AND -   30 -	but it works!
;   DUP BASE @ U< ;
	.word link
	.byte 0
link	.set *
	.byte 6,"DIGIT?"
DIGITQ:
	sep colonpc
	.word DUP,LIT,$39,GREATER,LIT,$100,ANDD,PLUS
	.word DUP,LIT,$140,GREATER,LIT,$107,ANDD
	.word MINUS,LIT,$30,MINUS
	.word DUP,BASE,FETCH,ULESS,EXIT

;Z ?SIGN   adr n -- adr' n' f	get optional sign
;Z  advance adr/n if sign;	return NZ if negative
;   OVER C@			-- adr n c
;   2C - DUP ABS 1 = AND	-- +=-1, -=+1, else 0
;   DUP IF 1+			-- +=0, -=+2
;       >R 1 /STRING R>		-- adr' n' f
;   THEN ;
	.word link
	.byte 0
link	.set *
	.byte 5,"?SIGN"
QSIGN:
	sep colonpc
	.word OVER,CFETCH,LIT,$2C,MINUS,DUP,ABS
	.word ONE,EQUAL,ANDD,DUP,qbranch,QSIGN1
	.word ONEPLUS,TOR,ONE,SLASHSTRING,RFROM
QSIGN1: .word EXIT

;C >NUMBER  ud adr u -- ud' adr' u'
;C				convert string to number
;   BEGIN
;   DUP WHILE
;       OVER C@ DIGIT?
;       0= IF DROP EXIT THEN
;       >R 2SWAP BASE @ UD*
;       R> M+ 2SWAP
;       1 /STRING
;   REPEAT ;
	.word link
	.byte 0
link	.set *
	.byte 7,">NUMBER"
TONUMBER:
	sep colonpc
TONUM1: .word DUP,qbranch,TONUM3
	.word OVER,CFETCH,DIGITQ
	.word ZEROEQUAL,qbranch,TONUM2,DROP,EXIT
TONUM2: .word TOR,TWOSWAP,BASE,FETCH,UDSTAR
	.word RFROM,MPLUS,TWOSWAP
	.word ONE,SLASHSTRING,branch,TONUM1
TONUM3: .word EXIT

;Z ?NUMBER  c-addr -- n -1	string->number
;Z		 -- c-addr 0	if convert error
;   DUP  0 0 ROT COUNT		-- ca ud adr n
;   ?SIGN >R  >NUMBER		-- ca ud adr' n'
;   IF   R> 2DROP 2DROP 0	-- ca 0   (error)
;   ELSE 2DROP NIP R>
;       IF NEGATE THEN  -1	-- n -1   (ok)
;   THEN ;
	.word link
	.byte 0
link	.set *
	.byte 7,"?NUMBER"
QNUMBER:
	sep colonpc
	.word DUP,ZERO,DUP,ROT,COUNT
	.word QSIGN,TOR,TONUMBER,qbranch,QNUM1
	.word RFROM,TWODROP,TWODROP,ZERO
	.word branch,QNUM3
QNUM1:  .word TWODROP,NIP,RFROM,qbranch,QNUM2,NEGATE
QNUM2:  .word MINUSONE
QNUM3:  .word EXIT

;Z INTERPRET    i*x c-addr u -- j*x
;Z				interpret given buffer
; This is a common factor of EVALUATE and QUIT.
; ref. dpANS-6, 3.4 The Forth Text Interpreter
;   'SOURCE 2!  0 >IN !
;   BEGIN
;   BL WORD DUP C@ WHILE	-- textadr
;       FIND			-- a 0/1/-1
;       ?DUP IF			-- xt 1/-1
;	   1+ STATE @ 0= OR	immed or interp?
;	   IF EXECUTE ELSE ,XT THEN
;       ELSE			-- textadr
;	   ?NUMBER
;	   IF POSTPONE LITERAL	converted ok
;	   ELSE COUNT TYPE 3F EMIT CR ABORT  err
;	   THEN
;       THEN
;   REPEAT DROP ;
	.word link
	.byte 0
link	.set *
	.byte 9,"INTERPRET"
INTERPRET:
	sep colonpc
	.word TICKSOURCE,TWOSTORE,ZERO,TOIN,STORE
INTER1: .word BL,WORD,DUP,CFETCH,qbranch,INTER9
	.word FIND,QDUP,qbranch,INTER4
	.word ONEPLUS,STATE,FETCH,ZEROEQUAL,ORR
	.word qbranch,INTER2
	.word EXECUTE,branch,INTER3
INTER2: .word COMMAXT
INTER3: .word branch,INTER8
INTER4: .word QNUMBER,qbranch,INTER5
	.word LITERAL,branch,INTER6
INTER5: .word COUNT,TYPE,LIT,$3F,EMIT,CR,ABORT
INTER6:
INTER8: .word branch,INTER1
INTER9: .word DROP,EXIT

;C EVALUATE  i*x c-addr u -- j*x	interpret string
;   'SOURCE 2@ >R >R  >IN @ >R
;   INTERPRET
;   R> >IN !  R> R> 'SOURCE 2! ;
	.word link
	.byte 0
link	.set *
	.byte 8,"EVALUATE"
EVALUATE:
	sep colonpc
	.word TICKSOURCE,TWOFETCH,TOR,TOR
	.word TOIN,FETCH,TOR,INTERPRET
	.word RFROM,TOIN,STORE,RFROM,RFROM
	.word TICKSOURCE,TWOSTORE,EXIT

;C QUIT     --    R: i*x --		interpret from kbd
;   L0 LP !  R0 RP!   0 STATE !
;   BEGIN
;       TIB DUP TIBSIZE ACCEPT  SPACE
;       INTERPRET
;       STATE @ 0= IF CR ." OK" THEN
;   AGAIN ;
	.word link
	.byte 0
link	.set *
	.byte 4,"QUIT"
QUIT:
	sep colonpc
	.word L0,LP,STORE
	.word R0,RPSTORE,ZERO,STATE,STORE
QUIT1:  .word TIB,DUP,TIBSIZE,ACCEPT,SPACE
	.word INTERPRET
	.word STATE,FETCH,ZEROEQUAL,qbranch,QUIT2
	.word CR,XSQUOTE
	.byte 3,"ok "
	.word TYPE
QUIT2:  .word branch,QUIT1

;C ABORT    i*x --   R: j*x --	clear stk & QUIT
;   S0 SP!  QUIT ;
	.word link
	.byte 0
link	.set *
	.byte 5,"ABORT"
ABORT:
	sep colonpc
	.word S0,SPSTORE,QUIT	; QUIT never returns

;Z ?ABORT   f c-addr u --	abort & print msg
;   ROT IF TYPE ABORT THEN 2DROP ;
	.word link
	.byte 0
link	.set *
	.byte 6,"?ABORT"
QABORT:
	sep colonpc
	.word ROT,qbranch,QABO1,TYPE,ABORT
QABO1:  .word TWODROP,EXIT

;C ABORT"  i*x 0  -- i*x   R: j*x -- j*x  x1=0
;C	 i*x x1 --       R: j*x --      x1<>0
;   POSTPONE S" POSTPONE ?ABORT ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 6,"ABORT\""
ABORTQUOTE:
	sep colonpc
	.word SQUOTE
	.word LIT,QABORT,COMMAXT
	.word EXIT

;C '    -- xt		find word in dictionary
;   BL WORD FIND
;   0= ABORT" ?" ;
	.word link
	.byte 0
link	.set *
	.byte 1,"\'"
TICK:   sep colonpc
	.word BL,WORD,FIND,ZEROEQUAL,XSQUOTE
	.byte 1,"?"
	.word QABORT,EXIT

;C CHAR   -- char	parse ASCII character
;   BL WORD 1+ C@ ;
	.word link
	.byte 0
link	.set *
	.byte 4,"CHAR"
CHAR:
	sep colonpc
	.word BL,WORD,ONEPLUS,CFETCH,EXIT

;C [CHAR]   --		compile character literal
;   CHAR  ['] LIT ,XT  , ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 6,"[CHAR]"
BRACCHAR:
	sep colonpc
	.word CHAR
	.word LIT,LIT,COMMAXT
	.word COMMA,EXIT

;C (    --		skip input until )
;   [ HEX ] 29 WORD DROP ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 1,"("
PAREN:
	sep colonpc
	.word LIT,$29,WORD,DROP,EXIT

; COMPILER ======================================

;Z (CREATE)	-- 	create link, immediate, and name fields
;   LATEST @ , 0 C,	link & immed field
;   HERE LATEST !	new "latest" link
;   BL WORD C@ 1+ ALLOT	name field
	.word link
	.byte 0
link	.set *
	.byte 8,"(CREATE)"
XCREATE:
	sep colonpc
	.word LATEST,FETCH,COMMA,ZERO,CCOMMA
	.word HERE,LATEST,STORE
	.word BL,WORD,CFETCH,ONEPLUS,ALLOT
	.word EXIT

;C CREATE   --		create an empty definition with 3-byte code field
;   (CREATE) createpc ,CF noop ,XT	code field
	.word link
	.byte 0
link	.set *
	.byte 6,"CREATE"
CREATE:
	sep colonpc
	.word XCREATE
	.word LIT,createpc,COMMACF
	.word LIT,noop,COMMAXT,EXIT	; default DOES> part

;Z SCREATE   --		create an empty definition with 1-byte code field
;   (CREATE) varpc ,CF
	.word link
	.byte 0
link	.set *
	.byte 7,"SCREATE"
SCREATE:
	sep colonpc
	.word XCREATE
	.word LIT,varpc,COMMACF,EXIT

;Z (DOES>)  --	run-time action of DOES>
;   R>	      adrs of headless DOES> def'n
;   LATEST @ NFA>CFA 1+ !   code field to fix up
	.word link
	.byte 0
link	.set *
	.byte 7,"(DOES>)"
XDOES:
	sep colonpc
	.word RFROM,LATEST,FETCH,NFATOCFA,ONEPLUS,STORE
	.word EXIT

;C DOES>    --		change action of latest def'n
; ANSI 6.1.1250 says that DOES> only applies to CREATE'd
; definitions, which have a 3-byte CFA
;   COMPILE (DOES>)
;   docolon ,CF ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 5,"DOES>"
DOES:
	sep colonpc
	.word LIT,XDOES,COMMAXT
	.word LIT,colonpc,COMMACF,EXIT

;C RECURSE  --		recurse current definition
;   LATEST @ NFA>CFA ,XT ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 7,"RECURSE"
RECURSE:
	sep colonpc
	.word LATEST,FETCH,NFATOCFA,COMMAXT,EXIT

;C [	--		enter interpretive state
;   0 STATE ! ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 1,"["
LEFTBRACKET:
	sep colonpc
	.word ZERO,STATE,STORE,EXIT

;C ]	--		enter compiling state
;   -1 STATE ! ;
	.word link
	.byte 0
link	.set *
	.byte 1,"]"
RIGHTBRACKET:
	sep colonpc
	.word MINUSONE,STATE,STORE,EXIT

;Z HIDE     --		"hide" latest definition
;   LATEST @ DUP C@ 80 OR SWAP C! ;
	.word link
	.byte 0
link	.set *
	.byte 4,"HIDE"
HIDE:
	sep colonpc
	.word LATEST,FETCH,DUP,CFETCH,LIT,$80,ORR
	.word SWAP,CSTORE,EXIT

;Z REVEAL   --		"reveal" latest definition
;   LATEST @ DUP C@ 7F AND SWAP C! ;
	.word link
	.byte 0
link	.set *
	.byte 6,"REVEAL"
REVEAL:
	sep colonpc
	.word LATEST,FETCH,DUP,CFETCH,LIT,$7F,ANDD
	.word SWAP,CSTORE,EXIT

;C IMMEDIATE   --	make last def'n immediate
;   1 LATEST @ 1- C! ;	set immediate flag
	.word link
	.byte 0
link	.set *
	.byte 9,"IMMEDIATE"
IMMEDIATE:
	sep colonpc
	.word ONE,LATEST,FETCH,ONEMINUS,CSTORE
	.word EXIT

;C :	--		begin a colon definition
;   CREATE HIDE ] colonpc ,CF ;
	.word link
	.byte 0
link	.set *
	.byte 1,":"
COLON:
	sep colonpc
	.word XCREATE,HIDE,RIGHTBRACKET,LIT,colonpc,COMMACF
	.word EXIT

;C ;
;   REVEAL  ,EXIT
;   POSTPONE [  ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 1,";"
SEMICOLON:
	sep colonpc
	.word REVEAL,CEXIT
	.word LEFTBRACKET,EXIT

;X :NONAME	-- xt	begin a nameless colon definition
; HERE ] colonpc ,CF ;
	.word link
	.byte 0
link	.set *
	.byte 7,":NONAME"
CONONAME:
	sep colonpc
	.word HERE,RIGHTBRACKET
	.word LIT,colonpc,COMMACF,EXIT

;C [']  --		find word & compile as literal
;   '  ['] LIT ,XT  , ; IMMEDIATE
; When encountered in a colon definition, the
; phrase  ['] xxx  will cause   LIT,xxt  to be
; compiled into the colon definition (where
; (where xxt is the execution token of word xxx).
; When the colon definition executes, xxt will
; be put on the stack.  (All xt's are one cell.)
;    immed BRACTICK,3,['],docolon
	.word link
	.byte 1
link	.set *
	.byte 3,"[\']"     ; tick character
BRACTICK:
	sep colonpc
	.word TICK		; get xt of 'xxx'
	.word LIT,LIT,COMMAXT	; append LIT action
	.word COMMA,EXIT		; append xt literal

;C POSTPONE  --		postpone compile action of word
;   BL WORD FIND
;   DUP 0= ABORT" ?"
;   0< IF   -- xt	non immed: add code to current
;			def'n to compile xt later.
;       ['] LIT ,XT  ,	add "LIT,xt,COMMAXT"
;       ['] ,XT ,XT	to current definition
;   ELSE  ,XT      immed: compile into cur. def'n
;   THEN ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 8,"POSTPONE"
POSTPONE:
	sep colonpc
	.word BL,WORD,FIND,DUP,ZEROEQUAL,XSQUOTE
	.byte 1,"?"
	.word QABORT,ZEROLESS,qbranch,POST1
	.word LIT,LIT,COMMAXT,COMMA
	.word LIT,COMMAXT,COMMAXT,branch,POST2
POST1:  .word COMMAXT
POST2:  .word EXIT

;Z COMPILE   --		append inline execution token
;   R> DUP CELL+ >R @ ,XT ;
; The phrase ['] xxx ,XT appears so often that
; this word was created to combine the actions
; of LIT and ,XT.  It takes an inline literal
; execution token and appends it to the dict.
	.word link
	.byte 0
link	.set *
	.byte 7,"COMPILE"
COMPILE:
	sep colonpc
	.word RFROM,DUP,CELLPLUS,TOR
	.word FETCH,COMMAXT,EXIT
; N.B.: not used in the current implementation

; CONTROL STRUCTURES ============================

;C IF       -- adrs	conditional forward branch
;   ['] qbranch ,BRANCH HERE DUP ,DEST ;
;   IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 2,"IF"
IF:
	sep colonpc
	.word LIT,qbranch,COMMABRANCH
	.word HERE,DUP,COMMADEST,EXIT

;C THEN     adrs --	resolve forward branch
;   HERE SWAP !DEST ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 4,"THEN"
THEN:
	sep colonpc
	.word HERE,SWAP,STOREDEST,EXIT

;C ELSE     adrs1 -- adrs2	branch for IF..ELSE
;   ['] branch ,BRANCH  HERE DUP ,DEST
;   SWAP  POSTPONE THEN ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 4,"ELSE"
ELSE:
	sep colonpc
	.word LIT,branch,COMMABRANCH
	.word HERE,DUP,COMMADEST
	.word SWAP,THEN,EXIT

;C BEGIN    -- adrs		target for bwd. branch
;   HERE ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 5,"BEGIN"
BEGIN:
	lbr HERE

;C UNTIL    adrs --		conditional backward branch
;   ['] qbranch ,BRANCH  ,DEST ; IMMEDIATE
;   conditional backward branch
	.word link
	.byte 1
link	.set *
	.byte 5,"UNTIL"
UNTIL:
	sep colonpc
	.word LIT,qbranch,COMMABRANCH
	.word COMMADEST,EXIT

;X AGAIN    adrs --		uncond'l backward branch
;   ['] branch ,BRANCH  ,DEST ; IMMEDIATE
;   unconditional backward branch
	.word link
	.byte 1
link	.set *
	.byte 5,"AGAIN"
AGAIN:
	sep colonpc
	.word LIT,branch,COMMABRANCH
	.word COMMADEST,EXIT

;C WHILE    -- adrs		branch for WHILE loop
;   POSTPONE IF SWAP ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 5,"WHILE"
WHILE:
	sep colonpc
	.word IF,SWAP,EXIT

;C REPEAT   adrs1 adrs2 --	resolve WHILE loop
;   POSTPONE AGAIN POSTPONE THEN ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 6,"REPEAT"
REPEAT:
	sep colonpc
	.word AGAIN,THEN,EXIT

;Z >L   x --   L: -- x		move to leave stack
;   CELL LP +!  LP @ ! ;	(L stack grows up)
	.word link
	.byte 0
link	.set *
	.byte 2,">L"
TOL:
	sep colonpc
	.word CELL,LP,PLUSSTORE,LP,FETCH,STORE,EXIT

;Z L>   -- x   L: x --		move from leave stack
;   LP @ @  CELL NEGATE LP +! ;
	.word link
	.byte 0
link	.set *
	.byte 2,"L>"
LFROM:
	sep colonpc
	.word LP,FETCH,FETCH
	.word CELL,NEGATE,LP,PLUSSTORE,EXIT

;C DO       -- adrs   L: -- 0
;   ['] xdo ,XT   HERE		target for bwd branch
;   0 >L ; IMMEDIATE		marker for LEAVEs
	.word link
	.byte 1
link	.set *
	.byte 2,"DO"
DO:
	sep colonpc
	.word LIT,xdo,COMMAXT,HERE
	.word ZERO,TOL,EXIT

;Z ENDLOOP   adrs xt --   L: 0 a1 a2 .. aN --
;   ,BRANCH  ,DEST		backward loop
;   BEGIN L> ?DUP WHILE POSTPONE THEN REPEAT ;
;				resolve LEAVEs
; This is a common factor of LOOP and +LOOP.
	.word link
	.byte 0
link	.set *
	.byte 7,"ENDLOOP"
ENDLOOP:
	sep colonpc
	.word COMMABRANCH,COMMADEST
LOOP1:  .word LFROM,QDUP,qbranch,LOOP2
	.word THEN,branch,LOOP1
LOOP2:  .word EXIT

;C LOOP    adrs --   L: 0 a1 a2 .. aN --
;   ['] xloop ENDLOOP ;  IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 4,"LOOP"
LOOP:
	sep colonpc
	.word LIT,xloop,ENDLOOP,EXIT

;C +LOOP   adrs --   L: 0 a1 a2 .. aN --
;   ['] xplusloop ENDLOOP ;  IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 5,"+LOOP"
PLUSLOOP:
	sep colonpc
	.word LIT,xplusloop,ENDLOOP,EXIT

;C LEAVE    --    L: -- adrs
;   ['] UNLOOP ,XT
;   ['] branch ,BRANCH   HERE DUP ,DEST  >L
;   ; IMMEDIATE      unconditional forward branch
	.word link
	.byte 1
link	.set *
	.byte 5,"LEAVE"
LEAVE:
	sep colonpc
	.word LIT,unloop,COMMAXT
	.word LIT,branch,COMMABRANCH
	.word HERE,DUP,COMMADEST,TOL,EXIT

; OTHER OPERATIONS ==============================

;C MOVE    addr1 addr2 u --		smart move
;	     VERSION FOR 1 ADDRESS UNIT = 1 CHAR
;  >R 2DUP SWAP DUP R@ +     -- ... dst src src+n
;  WITHIN IF  R> CMOVE>	src <= dst < src+n
;       ELSE  R> CMOVE  THEN ;	  otherwise
	.word link
	.byte 0
link	.set *
	.byte 4,"MOVE"
MOVE:
	sep colonpc
	.word TOR,TWODUP,SWAP,DUP,RFETCH,PLUS
	.word WITHIN,qbranch,MOVE1
	.word RFROM,CMOVEUP,branch,MOVE2
MOVE1:  .word RFROM,CMOVE
MOVE2:  .word EXIT

;C DEPTH    -- +n		number of items on stack
;   SP@ S0 SWAP - 2/ ;		16-BIT VERSION!
	.word link
	.byte 0
link	.set *
	.byte 5,"DEPTH"
DEPTH:
	sep colonpc
	.word SPFETCH,S0,SWAP,MINUS,TWOSLASH,EXIT

;C ENVIRONMENT?  c-addr u -- false	system query
;		 -- i*x true
;   2DROP 0 ;			the minimal definition!
	.word link
	.byte 0
link	.set *
	.byte 12,"ENVIRONMENT?"
ENVIRONMENTQ:
	sep colonpc
	.word TWODROP,ZERO,EXIT

; UTILITY WORDS AND STARTUP =====================

;X WORDS    --			list all words in dict.
;   LATEST @ BEGIN
;       DUP COUNT TYPE SPACE
;       NFA>LFA @
;   DUP 0= UNTIL
;   DROP ;
	.word link
	.byte 0
link	.set *
	.byte 5,"WORDS"
WORDS:
	sep colonpc
	.word LATEST,FETCH
WDS1:   .word DUP,COUNT,TYPE,SPACE,NFATOLFA,FETCH
	.word DUP,ZEROEQUAL,qbranch,WDS1
	.word DROP,EXIT

;X .S      --			print stack contents
;   SP@ S0 - IF
;       SP@ S0 2 - DO I @ U. -2 +LOOP
;   THEN ;
	.word link
	.byte 0
link	.set *
	.byte 2,".S"
DOTS:
	sep colonpc
	.word SPFETCH,S0,MINUS,qbranch,DOTS2
	.word SPFETCH,S0,LIT,2,MINUS,XDO
DOTS1:  .word II,FETCH
	.word swapbytes		; parameter stack data is little-endian
	.word UDOT,LIT,-2,XPLUSLOOP,DOTS1
DOTS2:  .word EXIT

;X \	--			comment to end of line
; \ 1 WORD DROP ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 1,"\\"
	sep colonpc
	.word ONE,WORD,DROP,EXIT

;X .(	--			print to matching right paren
; [ HEX ] 29 WORD COUNT TYPE ; IMMEDIATE
	.word link
	.byte 1
link	.set *
	.byte 2,".("
	sep colonpc
	.word LIT,$29,WORD,COUNT,TYPE,EXIT

;Z COLD     --			cold start Forth system
;   UINIT U0 #INIT CMOVE      init user area
;   ." RCA1802 CamelForth etc."
;   ABORT ;
	.word link
	.byte 0
link	.set *
	.byte 4,"COLD"
COLD:
	sep colonpc
	.word UINIT,U0,NINIT,CMOVE
	.word XSQUOTE
	.byte 39			; length of sign-on string
	.byte "RCA1802 CamelForth v1.03  19 Feb 2009"
	.byte $0D,$0A
	.word TYPE,ABORT		; ABORT never returns

; COMMON CONSTANTS =========================

;Z -1	-- -1
	.word link
	.byte 0
link	.set *
	.byte 2,"-1"
MINUSONE:
	ldi $FF
m1:
	dec psp
	stxd
	str psp
	sep nextpc


; EPILOGUE =========================

lastword	.equ link	; nfa of last word in dictionary
enddict	.equ *		; user's code starts here

	.end

	.ENDIF

	.END