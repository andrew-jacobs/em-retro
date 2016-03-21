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
; $Id$
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