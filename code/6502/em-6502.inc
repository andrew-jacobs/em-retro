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
; Copyright (C)2015 HandCoded Software Ltd.
; All rights reserved.
;
; This software is the confidential and proprietary information of HandCoded
; Software Ltd. ("Confidential Information").  You shall not disclose such
; Confidential Information and shall use it only in accordance with the terms
; of the license agreement you entered into with HandCoded Software.
;
; HANDCODED SOFTWARE MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE
; SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
; LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
; PARTICULAR PURPOSE, OR NON-INFRINGEMENT. HANDCODED SOFTWARE SHALL NOT BE
; LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING
; OR DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES.
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

;-------------------------------------------------------------------------------

; Select ROM bank specified by A<3:0>

IO_BNK		.macro
		.byte	$BB
		.endm
