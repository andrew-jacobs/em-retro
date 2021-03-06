;===============================================================================
;  _____ __  __       ____      _
; | ____|  \/  |     |  _ \ ___| |_ _ __ ___
; |  _| | |\/| |_____| |_) / _ \ __| '__/ _ \
; | |___| |  | |_____|  _ <  __/ |_| | | (_) |
; |_____|_|  |_|     |_| \_\___|\__|_|  \___/
;
; A Retro Device Emulator
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
; 2014-10-11 AJ Initial version
;-------------------------------------------------------------------------------

        .equiv  REV_1412,       1               ; Prototype board
        .equiv  REV_1502,       0

;===============================================================================
; Device Definitions
;-------------------------------------------------------------------------------

        .ifdef  __24EP256GP202
        .include "P24EP256GP202.inc"
 
        .equiv  OSC,            7370000         ; 7.37Mhz
        .equiv  PLLPRE,         3
        .equiv  PLLDIV,         113
        .equiv  PLLPOST,        2
        .equiv  FCPU,           (OSC * PLLDIV)/(PLLPRE * PLLPOST)

        .endif

;-------------------------------------------------------------------------------

        .ifdef  __24EP512GP202
        .include "P24EP512GP202.inc"

        .equiv  OSC,            7370000         ; 7.37Mhz
        .equiv  PLLPRE,         3
        .equiv  PLLDIV,         113
        .equiv  PLLPOST,        2
        .equiv  FCPU,           (OSC * PLLDIV)/(PLLPRE * PLLPOST)

        .endif

;===============================================================================
; Perpherial Settings
;-------------------------------------------------------------------------------

; Micro-Cycle Timer

        .equiv  TMR1_PS,        1
        .equiv  TMR1_1MHZ,      FCPU / (2 * 1000000 * TMR1_PS) - 1
        .equiv  TMR1_2MHZ,      FCPU / (2 * 2000000 * TMR1_PS) - 1
        .equiv  TMR1_3_7MHZ,    FCPU / (2 * 3700000 * TMR1_PS) - 1

        .if     TMR1_1MHZ & 0xffff0000
        .error  "Timer 1 1MHz count does not fit in 16-bits"
        .endif
        .if     TMR1_2MHZ & 0xffff0000
        .error  "Timer 1 2MHz count does not fit in 16-bits"
        .endif

; 100Hz Timer

        .equiv  TMR2_PS,        64
        .equiv  TMR2_100HZ,     FCPU / (2 * 100 * TMR2_PS) - 1

        .if     TMR2_100HZ & 0xffff0000
        .error  "Timer 2 100Hz count does not fit in 16-bits"
        .endif

; UART

        .equiv  RXD_TRIS,       TRISB
        .equiv  RXD_PIN,        5
        .equiv  RXD_RP,         37

        .equiv  TXD_TRIS,       TRISB
        .equiv  TXD_PIN,        6
        .equiv  TXD_RP,         38

        .equiv  BRG_57600,      FCPU / (2 * 4 * 57600) - 1
        .equiv  FIFO_SIZE,      128

; SPI
	
	.equiv	SPI_FAST_HZ,	4000000
	.equiv	SPI_SLOW_HZ,	125000

        .equiv  SPI_TRIS,       TRISB
        .equiv  SPI_LAT,        LATB
        .equiv  SPI_PORT,       PORTB

        .if     REV_1412
        .equiv  SEL_PIN,        9
        .equiv  SCK_PIN,        12
        .equiv  SDO_PIN,        2
        .equiv  SDI_PIN,        11
        .equiv  SDI_RP,         43

        .equiv  SPI_FAST_DELAY, FCPU / (2 * SPI_FAST_HZ)
        .equiv  SPI_SLOW_DELAY, FCPU / (2 * SPI_SLOW_HZ)
        .endif

        .if     REV_1502
        ; TODO Fix pin mappings
        .equiv  SEL_PIN,        9
        .equiv  SCK_PIN,        12
        .equiv  SCK_RP,         44
        .equiv  SDO_PIN,        2
        .equiv  SDO_RP,         34
        .equiv  SDI_PIN,        11
        .equiv  SDI_RP,         43
        .endif

; Jumpers

        .if     REV_1412
        .equiv  JP1_TRIS,       TRISA
        .equiv  JP1_PORT,       PORTA
        .equiv  JP1_PIN,        3

        .equiv  JP2_TRIS,       TRISA
        .equiv  JP2_PORT,       PORTA
        .equiv  JP2_PIN,        4
        .endif

        .if     REV_1502
        ; TODO update pins
        .equiv  JP1_TRIS,       TRISA
        .equiv  JP1_PORT,       PORTA
        .equiv  JP1_PIN,        3

        .equiv  JP2_TRIS,       TRISA
        .equiv  JP2_PORT,       PORTA
        .equiv  JP2_PIN,        4

        .equiv  JP3_TRIS,       TRISA
        .equiv  JP3_PORT,       PORTA
        .equiv  JP3_PIN,        4
        .endif

; Inputs Pins & Switches

        .equiv  IN1_PORT,       PORTB   ; Pulled high by default
        .equiv  IN1_PIN,        7

        .equiv  IN2_PORT,       PORTB
        .equiv  IN2_PIN,        4

        .equiv  SW_PORT,        PORTB   ; Pulled low by default
        .equiv  SW_PIN,         10

; Output Pins & LEDs

        .equiv  OUT1_LAT,       LATB
        .equiv  OUT1_PIN,       8

        .equiv  LED1_LAT,       LATB
        .equiv  LED1_PIN,       13

        .equiv  LED2_LAT,       LATB
        .equiv  LED2_PIN,       14

        .equiv  LED3_LAT,       LATB
        .equiv  LED3_PIN,       15

;===============================================================================
; Logical Interrupt Flags
;-------------------------------------------------------------------------------

        .equiv  INT_100HZ,      0               ; 100Hz Timer
        .equiv  INT_UART_RX,    1
        .equiv  INT_UART_TX,    2

        .equiv  INT_NMI,        8		; Falling edge on IN1
	.equiv	INT_WAITING,	14		; Waiting for interrupt
	.equiv	INT_DETECTED,	15		; Interrupt detected
