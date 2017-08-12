		.nolist
;===============================================================================
;  _____ __  __        __  ____   ____ ___ ____
; | ____|  \/  |      / /_| ___| / ___/ _ \___ \
; |  _| | |\/| |_____| '_ \___ \| |  | | | |__) |
; | |___| |  | |_____| (_) |__) | |__| |_| / __/
; |_____|_|  |_|      \___/____/ \____\___/_____|
;
; WDC 65C02 Emulation Host Interface Macros
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
;===============================================================================
;-------------------------------------------------------------------------------

; Pseudo Operations

CMD_IFR		.equ	0
CMD_IFW		.equ	1
CMD_IER		.equ	2
CMD_IEW		.equ	3
CMD_TXD		.equ	4
CMD_RXD		.equ	5
CMD_CLR		.equ	6

; Interrupt flag masks

INT_100HZ	.equ	1<<0
INT_UART_RX	.equ	1<<1
INT_UART_TX	.equ	1<<2

;===============================================================================
;-------------------------------------------------------------------------------

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
