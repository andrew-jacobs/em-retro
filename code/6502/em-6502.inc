		.nolist
;===============================================================================
;  _____ __  __        __  ____   ___ ____
; | ____|  \/  |      / /_| ___| / _ \___ \
; |  _| | |\/| |_____| '_ \___ \| | | |__) |
; | |___| |  | |_____| (_) |__) | |_| / __/
; |_____|_|  |_|      \___/____/ \___/_____|
;
; MOS 6502 Emulation Host Interface Macros
;-------------------------------------------------------------------------------
; Copyright (C)2014-2016 HandCoded Software Ltd.
; All rights reserved.
;
; This work is made available under the terms of the Creative Commons
; Attribution-NonCommercial-ShareAlike 4.0 International license. Open the
; following URL to see the details.
;
; http://creativecommons.org/licenses/by-nc-sa/4.0/
;-------------------------------------------------------------------------------
;
; Notes:
;
;===============================================================================
; Revision History:
;
; 2015-02-11 AJ Initial version
;-------------------------------------------------------------------------------

		.list
		
; Interrupt flag masks

INT_100HZ	.equ	1<<0
INT_UART_RX	.equ	1<<1
INT_UART_TX	.equ	1<<2

;  Read the interrupt flags into A

IO_IFR		.macro
		.byte	$02,$00
		.endm

; Write the interrupt flags from A

IO_IFW		.macro
		.byte	$02,$01
		.endm

; Clear interrupt flags specified by A

IO_IFC		.macro
		.byte	$02,$06
		.endm

; Read the interrupt enables into A

IO_IER		.macro
		.byte	$02,$02
		.endm

; Write the interrupt enables from A

IO_IEW		.macro
		.byte	$02,$03
		.endm

; Transmit the character in A

IO_TXD		.macro
		.byte	$02,$04
		.endm

; Receive a characters into A

IO_RXD		.macro
		.byte	$02,$05
		.endm

;-------------------------------------------------------------------------------

; Select ROM bank specified by A<3:0>

IO_BNK		.macro
		.byte	$BB
		.endm
