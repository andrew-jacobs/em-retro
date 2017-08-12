		.nolist
;===============================================================================
;  _____ __  __        __    ___   ___   ___
; | ____|  \/  |      / /_  ( _ ) / _ \ / _ \
; |  _| | |\/| |_____| '_ \ / _ \| | | | | | |
; | |___| |  | |_____| (_) | (_) | |_| | |_| |
; |_____|_|  |_|      \___/ \___/ \___/ \___/
;
; A Motorola 6800 Emulator
;-------------------------------------------------------------------------------
; Copyright (C)2014-2015 HandCoded Software Ltd.
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
; 2015-01-04 AJ Initial version
;-------------------------------------------------------------------------------

		.list
;===============================================================================
; Pseudo Operations and Flags
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
; Macros for Pseudo Instructions
;-------------------------------------------------------------------------------

SYS_A		.macro	CMD
		.byte	$8F,CMD
		.endm
		
SYS_B		.macro	CMD
		.byte	$CF,CMD
		.endm
