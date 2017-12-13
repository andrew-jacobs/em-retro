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

        .include "hardware.inc"

;===============================================================================
; Constants
;-------------------------------------------------------------------------------
        
; ASCII Control characaters

        .equiv  ESC,            0x1b

; SD Card Commands

        .equiv  SD_CMD0,        (0x40|0x00)
        .equiv  SD_CMD1,        (0x40|0x01)
        .equiv  SD_CMD16,       (0x40|0x10)
        .equiv  SD_CMD17,       (0x40|0x11)     ; Read Single block

;===============================================================================
; Device Configuration
;-------------------------------------------------------------------------------

        .ifdef  __24EP512GP202

        config  __FICD, ICS_PGD3 & JTAGEN_OFF
        config  __FPOR, ALTI2C1_OFF & ALTI2C2_OFF & WDTWIN_WIN75
        config  __FWDT, WDTPOST_PS32768 & WDTPRE_PR32 & PLLKEN_OFF & WINDIS_OFF & FWDTEN_OFF
        config  __FOSC, POSCMD_NONE & OSCIOFNC_OFF & IOL1WAY_OFF & FCKSM_CSECMD
        config  __FOSCSEL, FNOSC_FRCPLL & IESO_OFF
        config  __FGS, GWRP_OFF & GCP_OFF

        .endif

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

        .section .nbss,bss,near

; The cycle counter is used to match instruction execution time to a real
; device. It is decremented by a regular Timer1 interrupt.

        .global CYCLE
CYCLE:
        .space  2

        .global INT_ENABLE
INT_ENABLE:
        .space  2

        .global INT_FLAGS
INT_FLAGS:
        .space  2

; The cached block numbers

        .section .nbss,bss,near
LBA0:
        .space  4
LBA1:
        .space  4
LBA2:
        .space  4
LBA3:
        .space  4

; Reserve some memory to hold disk blocks

        .section .blks,bss,align(256)
BLK0:
        .space  512
BLK1:
        .space  512
BLK2:
        .space  512
BLK3:
        .space  512

; Allocate a small stack area in near memory so the emulator can't easily write
; over it.

        .section .stack,bss
STACK:
        .space  128
STACK_LIMIT:
        .space  0

;===============================================================================
; Power On Reset
;-------------------------------------------------------------------------------

        .text
        .global __reset
        .extern EM_SCMP
        .extern EM_6800
        .extern EM_6502
        .extern EM_1802
        .extern EM_65C02
        .extern EM_6809
        .extern EM_8080
        .extern EM_Z80
__reset:
        mov     #STACK,w15
        mov     #STACK_LIMIT,w0
        mov     w0,SPLIM

;-------------------------------------------------------------------------------

        setm    PMD1                    ; Turn off all the peripherals
        setm    PMD2
        setm    PMD3
        setm    PMD4
        setm    PMD6
        setm    PMD7

        bclr    PMD1,#T1MD              ; Enable Timer 1 & 2
        bclr    PMD1,#T2MD
        bclr    PMD1,#U1MD              ; .. UART 1
        .if     REV_1502
        bclr    PMD1,#SPI2MD            ; .. SPI 2
        .endif
        bclr    PMD3,#CRCMD             ; .. CRC

;-------------------------------------------------------------------------------
; Change Oscillator settings

        .ifdef  PLLPOST
        .if     PLLPOST == 2
        .equiv  CLKDIV_BITS,    ((PLLPRE-2)<<PLLPRE0)|(0<<PLLPOST1)|(0<<PLLPOST0)
        .elseif PLLPOST == 4
        .equiv  CLKDIV_BITS,    ((PLLPRE-2)<<PLLPRE0)|(0<<PLLPOST1)|(1<<PLLPOST0)
        .elseif PLLPOST == 8
        .equiv  CLKDIV_BITS,    ((PLLPRE-2)<<PLLPRE0)|(1<<PLLPOST1)|(1<<PLLPOST0)
        .else
        .fail   "Invalid PLLPOST value"
        .endif
        .equiv  CLKDIV_MASK,    ((33-2)<<PLLPRE0)|(1<<PLLPOST1)|(1<<PLLPOST0)

        mov     #CLKDIV_BITS,w0
        xor     CLKDIV,WREG
        and     #CLKDIV_MASK,w0
        xor     CLKDIV

        mov     #PLLDIV-2,w0
        mov     w0,PLLFBD
        .endif

;-------------------------------------------------------------------------------
; Configure I/O Pins for normal operation

        clr     ANSELA                  ; Make all pins digital
        clr     ANSELB

        clr     LATA                    ; Set I/O direction
        mov     #(1<<JP1_PIN)|(1<<JP2_PIN),w0
        mov     w0,TRISA

        clr     LATB
        mov     #(1<<IN1_PIN)|(1<<SW_PIN)|(1<<IN2_PIN)|(1<<RXD_PIN)|(1<<SDI_PIN),w0
        mov     w0,TRISB

        mov     #(1<<JP1_PIN)|(1<<JP2_PIN),w0
        mov     w0,CNPUA
        mov     #(1<<IN1_PIN)|(1<<IN2_PIN)|(1<<SDI_PIN),w0
        mov     w0,CNPDB
        mov     #(1<<SW_PIN),w0
        mov     w0,CNPUB

;-------------------------------------------------------------------------------
; Remap I/O pins to make required peripherals accessable

        mov     #OSCCON,w1              ; Unlock pin change registers
        mov     #0x46,w2
        mov     #0x57,w3
        mov.b   w2,[w1]
        mov.b   w3,[w1]
        bclr    OSCCON,#6

        mov     #RXD_RP,w2              ; Assign UART RX
        mov     #RPINR18+0,w3
        mov.b   w2,[w3]

        mov     #0x01,w2                ; Assign UART TX
        mov     #RPOR2+0,w3
        mov.b   w2,[w3]

        .if     REV_1502
        mov     #0x09,w2                ; Assign SCK
        mov     #RPOR+,w3
        mov.b   w2,[w3]

; Assign SDI

        mov     #0x08,w2                ; Assign SDO
        mov     #RPOR+,w3
        mov.b   w2,[w3]
        .endif

        mov     #0x46,w2                ; Relock pin change registers
        mov     #0x57,w3
        mov.b   w2,[w1]
        mov.b   w3,[w1]
        bset    OSCCON,#6

;-------------------------------------------------------------------------------

        clr     INT_ENABLE              ; Clear interrupt flags
        clr     INT_FLAGS

        bset    CNENB,#IN1_PIN          ; Detect changes on IN1 pin

        bset    IPC4,#CNIP0             ; Set priority (3)
        bset    IPC4,#CNIP1
        bclr    IPC4,#CNIP2

        bset    IEC1,#CNIE              ; And enable

;-------------------------------------------------------------------------------

        mov     #BRG_57600,w0           ; Configure the UART
        mov     w0,U1BRG
        clr     U1STA
        mov     #(1<<UARTEN)|(1<<BRGH),w0
        mov     w0,U1MODE
        bset    U1STA,#UTXEN
 
        bset    IPC2,#U1RXIP0           ; Set priority (3)
        bset    IPC2,#U1RXIP1
        bclr    IPC2,#U1RXIP2
        bset    IPC3,#U1TXIP0
        bset    IPC3,#U1TXIP1
        bclr    IPC3,#U1TXIP2

        bset    IEC0,#U1RXIE            ; Enable receive
        bset    IEC0,#U1TXIE            ; .. and transmit interrupts

;-------------------------------------------------------------------------------

        rcall   SpiSetHi

        .if     REV_1502
        .endif

;-------------------------------------------------------------------------------

        mov     #(1<<CRCEN),w0          ; Enable CRC module
        mov     w0,CRCCON1
        mov     #0x070f,w0              ; Set data and polynomial sizes
        mov     w0,CRCCON2
        mov     #(1<<7)|(1<<3),w0       ; Set polynomial x7 + x3 + 1
        mov     w0,CRCXORL
        clr     CRCXORH
        clr     CRCWDATL                ; Clear last CRC value
        clr     CRCWDATH
        bset    CRCCON1,#CRCGO          ; And start processing

;-------------------------------------------------------------------------------

        clr     TMR1                    ; Configure the CYCLE Timer
        mov     #TMR1_1MHZ,w0
        mov     w0,PR1
        mov     #(1<<TON),w0
        mov     w0,T1CON

        bclr    IPC0,#T1IP0             ; Set priority (6)
        bset    IPC0,#T1IP1
        bset    IPC0,#T1IP2

        bset    IEC0,#T1IE              ; Enable timer interrupt

;-------------------------------------------------------------------------------

        clr     TMR2                    ; Configure the 100Hz Timer
        mov     #TMR2_100HZ,w0
        mov     w0,PR2
        .if     TMR2_PS == 1
        mov     #(1<<TON)|(0x00<<TCKPS0),w0
        .elseif TMR2_PS == 8
        mov     #(1<<TON)|(0x01<<TCKPS0),w0
        .elseif TMR2_PS == 64
        mov     #(1<<TON)|(0x02<<TCKPS0),w0
        .elseif TMR2_PS == 256
        mov     #(1<<TON)|(0x03<<TCKPS0),w0
        .else
        .error  "Invalid Timer2 prescaler value"
        .endif
        mov     w0,T2CON

        bclr    IPC0,#T2IP0             ; Set priority (4)
        bclr    IPC0,#T2IP1
        bset    IPC0,#T2IP2

        bset    IEC0,#T2IE              ; Enable timer interrupt

;-------------------------------------------------------------------------------

        rcall   ClearScreen             ; Clear the terminal
        rcall   ClearScreen
        rcall   GotoHome

        rcall   AttrBold                ; Show the banner
        rcall   PutStr
        .asciz  "  _____ __  __       ____      _\r\n"
        rcall   PutStr
        .asciz  " | ____|  \\/  |     |  _ \\ ___| |_ _ __ ___\r\n"
        rcall   PutStr
        .asciz  " |  _| | |\\/| |_____| |_) / _ \\ __| '__/ _ \\\r\n"
        rcall   PutStr
        .asciz  " | |___| |  | |_____|  _ <  __/ |_| | | (_) |\r\n"
        rcall   PutStr
        .asciz  " |_____|_|  |_|     |_| \\_\\___|\\__|_|  \\___/   [17.08]\r\n"
        rcall   PutStr
        .asciz  "\r\n Copyright (C),2014-2017 HandCoded Software Ltd.\r\n All rights reserved.\r\n\n"
        rcall   AttrNorm
   
        btsc    SW_PORT,#SW_PIN         ; Is the user switch pressed?
        bra     ReadJumpers             ; No, boot default emulation

        rcall   PutStr
        .asciz  " Select an emulation:"

        clr     w8                      ; Start with item 0
        mov     #9,w9                   ; .. of 9
ShowMenu:
        add     w8,#12,w0               ; Work out where it will be displayed
        mov     #4,w1
        rcall   GotoRowCol
        mov     #'-',w0                 ; Output a marker
        rcall   UartTx
        mov     #' ',w0
        rcall   UartTx
        mov     w8,w0                   ; The display the item text
        rcall   ShowItem
        add     w8,#12,w0               ; Reposition for the description
        mov     #22,w1
        rcall   GotoRowCol
        mov     w8,w0
        rcall   ShowDesc
        inc     w8,w8                   ; And repeat for all items
        cp      w8,w9
        bra     nz,ShowMenu

        clr     w8                      ; Assume item 0 selected
LiteItem:
        add     w8,#12,w0               ; Work out where it will be displayed
        mov     #6,w1
        rcall   GotoRowCol
        rcall   AttrInverse             ; And highlight the entry
        mov     w8,w0
        rcall   ShowItem
        rcall   AttrNorm
        add     w8,#12,w0               ; Reposition to the marker
        mov     #4,w1
        rcall   GotoRowCol

ReadKeys:
        rcall   UartRx                  ; Wait for user entry
        mov     #'\r',w1
        cpsne   w0,w1                   ; ENTER?
        bra     ReadDone                ; Yes.

        mov     #ESC,w1                 ; Cursor up or down?
        cp      w0,w1
        bra     nz,ReadKeys
        rcall   UartRx
        mov     #'[',w1
        cp      w0,w1
        bra     nz,ReadKeys
        rcall   UartRx
        mov     #'A',w1
        cp      w0,w1
        bra     z,MoveUp
        mov     #'B',w1
        cp      w0,w1
        bra     nz,ReadKeys
MoveDown:
        inc     w8,w7                   ; Work out the next item
        cpsne   w7,w9
        clr     w7
        bra     NormItem

MoveUp:
        dec     w8,w7                   ; Work out the prev item
        bra     nn,NormItem
        add     w7,w9,w7

NormItem:
        add     w8,#12,w0               ; Work out where it will be displayed
        mov     #6,w1
        rcall   GotoRowCol
        mov     w8,w0
        rcall   ShowItem                ; Unhighlight the current item
        mov     w7,w8                   ; Then select the new one
        bra     LiteItem

ReadDone:
        mov     #10,w0                  ; Erase the menu
        mov     #1,w1
        rcall   GotoRowCol
        rcall   EmitCSI
        mov     #'J',w0
        rcall   UartTx

        add     w8,w8,w0                ; And start the emulation
        bra     BootDevice

; Output the text that describes a particual menu item.

ShowItem:
        bra     w0

        bra     0f
        bra     1f
        bra     2f
        bra     3f
        bra     4f
        bra     5f
        bra     6f
        bra     7f
	bra	8f

0:      rcall   PutStr
        .asciz  "NS SC/MP II"
        return

1:      rcall   PutStr
        .asciz  "Motorola 6800"
        return

2:      rcall   PutStr
        .asciz  "MOS 6502"
        return

3:      rcall   PutStr
        .asciz  "RCA CDP 1802"
        return

4:      rcall   PutStr
        .asciz  "WDC 65C02"
        return

5:      rcall   PutStr
        .asciz  "Motorola 6809"
        return

6:      rcall   PutStr
        .asciz  "INTEL 8080"
        return

7:      rcall   PutStr
        .asciz  "Zilog Z80"
        return
	
8:	rcall	PutStr
	.asciz	"SD/MMC"
	return

; Output an extended description for each item

ShowDesc:
        bra     w0

        bra     0f
        bra     1f
        bra     2f
        bra     3f
        bra     4f
        bra     5f
        bra     6f
        bra     7f
	bra	8f

0:      rcall   PutStr
        .asciz  "[44K RAM + NIBL @ 4MHz]"
        return

1:      rcall   PutStr
        .asciz  "[32+12K RAM @ 1MHz]"
        return

2:      rcall   PutStr
        .asciz  "[32K RAM + 16/16K ROM @ 2MHz]"
        return

3:      rcall   PutStr
        .asciz  "[44K RAM + 20K ROM @ 8MHz]"
        return

4:      rcall   PutStr
        .asciz  "[44K RAM + 20K ROM @ 2MHz]"
        return

5:      rcall   PutStr
        .asciz  "[32+12K RAM @ 1MHz]"
        return

6:      rcall   PutStr
        .asciz  "[44K RAM @ 1MHz]"
        return

7:      rcall   PutStr
        .asciz  "[44K RAM @ 1MHz]"
        return
	
8:	rcall   PutStr
        .asciz  "Virtual Disk Manager"
        return

;-------------------------------------------------------------------------------

; Read the state of the jumpers and form a jump index (0, 2, 4, ...) that will
; be used to start an emulation.

ReadJumpers:
        clr     w0                      ; Read the jumper settings
        btsc    JP1_PORT,#JP1_PIN
        bset    w0,#1
        btsc    JP2_PORT,#JP2_PIN
        bset    w0,#2
        .if     REV_1502
        btsc    JP3_PORT,#JP3_PIN
        bset    w0,#4
        .endif

; Use the jump index in W0 to start the required emulation.

BootDevice:
        bra     w0                      ; Branch into jump table

        goto    EM_SCMP
        goto    EM_6800
        goto    EM_6502
        goto    EM_1802

        goto    EM_65C02
        goto    EM_6809
        goto    EM_8080
        goto    EM_Z80
	
	goto	DiskManager

;===============================================================================
; VT200 Control Sequences
;-------------------------------------------------------------------------------

; Emit the control sequence to clear the entire screen.
        
        .text
        .global ClearScreen
ClearScreen:
        rcall   EmitCSI
        mov     #'2',w0
        rcall   UartTx
        mov     #'J',w0
        bra     UartTx
        
; Emit the control sequence to move the cursor to home (1,1)

        .global GotoHome
GotoHome:
        mov     #1,w0                   ; Goto row 1
        mov     #1,w1                   ; .. column 1

; Emit the control sequence to move the cursor to a row,col
        .global GotoRowCol
GotoRowCol:
        push    w1                      ; Save colum
        push    w0                      ; Save row
        rcall   EmitCSI                 ; Start a CSI sequence
        pop     w0                      ; Then the row number
        rcall   EmitDecimal
        mov     #';',w0                 ; A ';' separator
        rcall   UartTx
        pop     w0                      ; The column number
        rcall   EmitDecimal
        mov     #'H',w0                 ; And finally the command
        bra     UartTx

; Convert the binary value in w0 into a one or two digit decimal number in
; ASCII and send to the terminal.

EmitDecimal:
        mov     #10,w2                  ; Divide w0 by 10
        repeat  #17
        div.uw  w0,w2
        mov     #'0',w2                 ; Convert the first digit to ASCII
        ior     w0,w2,w0
        cpseq   w0,w2                   ; Suppress leading zero
        rcall   UartTx                  ; Otherwise output it
        ior     w1,w2,w0                ; Convert the second digit
        bra     UartTx                  ; And always display

; Emit the control sequence to make text appear in bold
        
        .global AttrBold
AttrBold:
        rcall   EmitCSI
        mov     #'1',w0
        rcall   UartTx
        mov     #'m',w0
        bra     UartTx

; Emit the control sequence to make text appear normal
        
        .global AttrNorm
AttrNorm:
        rcall   EmitCSI
        mov     #'0',w0
        rcall   UartTx
        mov     #'m',w0
        bra     UartTx

; Emit the control sequence to make text appear inverse.

        .global AttrInverse
AttrInverse:
        rcall   EmitCSI
        mov     #'7',w0
        rcall   UartTx
        mov     #'m',w0
        bra     UartTx
        
; Emit the initial part of a control code sequence.

        .global EmitCSI
EmitCSI:
        mov     #0x1b,w0                ; Emit ESC
        rcall   UartTx
        mov     #'[',w0                 ; Followed by [
        bra     UartTx

;-------------------------------------------------------------------------------

; Print a zero terminated string that immediately follows the call instruction
; that enters this routine.
        
        .global PutStr
PutStr:
        push.s
        pop.d   w2                      ; Pull the return address
        mov     w3,TBLPAG               ; .. and setup for table read
1:
        tblrdl  [w2++],w1               ; Fetch next two characters

        ze      w1,w0                   ; Extract first character
        bra     z,2f                    ; And check for end of string
        rcall   UartTx                  ; Output if not end

        swap    w1                      ; Extract second character
        ze      w1,w0
        bra     z,2f                    ; And check for end of string
        rcall   UartTx                  ; Output if not end
        bra     1b
2:
        push.d  w2                      ; Pestore the return address
        pop.s
        return
        
; Output the value in W0 as four hex characters.

        .global PutHex4
PutHex4:
        push    w0
        swap    w0
        rcall   PutHex2
        pop     w0

; Output the value in W2 as two hex characters.

        .global PutHex2
PutHex2:
        push    w0
        swap.b  w0
        rcall   PutHex
        pop     w0

; Output the lo nybble of W0 as a hex characters.

PutHex:
        rcall   ToHex
        bra     UartTx

; Convert the lo nybble of W0 to a hex character.

ToHex:
        and     w0,#0x0f,w0
        bra     w0
        retlw   #'0',w0
        retlw   #'1',w0
        retlw   #'2',w0
        retlw   #'3',w0
        retlw   #'4',w0
        retlw   #'5',w0
        retlw   #'6',w0
        retlw   #'7',w0
        retlw   #'8',w0
        retlw   #'9',w0
        retlw   #'A',w0
        retlw   #'B',w0
        retlw   #'C',w0
        retlw   #'D',w0
        retlw   #'E',w0
        retlw   #'F',w0

;===============================================================================
; Uart
;-------------------------------------------------------------------------------

; When the UART has received a character clear the interrupt and update the
; software flags to indicate data is available.

        .global __U1RXInterrupt
__U1RXInterrupt:
        bclr    IFS0,#U1RXIF            ; Clear the interrupt flag
        bset    INT_FLAGS,#INT_UART_RX
        retfie

; When the UART can transmit a character update the software flags and then
; clear the condition and disable the interrupt.

        .global __U1TXInterrupt
__U1TXInterrupt:
        bset    INT_FLAGS,#INT_UART_TX
        bclr    IFS0,#U1TXIF
        bclr    IEC0,#U1TXIE
        retfie

; Wait for the software flags to indicate that a character is available and
; then read it into W0

        .global UartRx
UartRx:
        btss    INT_FLAGS,#INT_UART_RX  ; Wait for data to be received
        bra     UartRx
        bclr    INT_FLAGS,#INT_UART_RX  ; Then take the data
        mov     U1RXREG,w0
        return                          ; Done

; Wait until the software flags show that the UART can transmit another
; character and then send the data in W0.

        .global UartTx
UartTx:
        btss    INT_FLAGS,#INT_UART_TX
        bra     UartTx
        bclr    INT_FLAGS,#INT_UART_TX
        mov     w0,U1TXREG
        bset    IEC0,#U1TXIE            ; Ensure TX enabled
        return

;-------------------------------------------------------------------------------

        .global __U1ErrInterrupt
__U1ErrInterrupt:
        retfie

;===============================================================================
; SPI Interface
;-------------------------------------------------------------------------------

; Set the I/O pin used to control the SPI slave low.

        .global SpiSetLo
SpiSetLo:
        bclr    SPI_LAT,#SEL_PIN        ; Set slave select low
        return

; Set the I/O pin used to control the SPI slave high.

        .global SpiSetHi
SpiSetHi:
        bset    SPI_LAT,#SEL_PIN        ; Set slave select high
        return

; Transmit the byte of data in w0 to the SPI slave and return the data that was
; received at the same time. Suspend cycle counting during the data exchange.

        .global SpiFast
SpiFast:
        mov     w0,CRCDATL              ; Add byte to CRC
        .if     REV_1412
        bclr    T1CON,#TON              ; Pause cycle timer
        push.d  w2                      ; Save callers registers
        push    w4
        mov     #SPI_LAT,w2             ; Load port access values
        mov     #SDO_PIN,w3
        .rept   8
        sl.b    w14,w14                 ; Shift CRC7 one bit
        xor     w14,w0,w4
        sl.b    w0,w0                   ; Shift MSB into carry flag
        bsw.c   [w2],w3                 ; And write to port
        bset    SPI_LAT,#SCK_PIN        ; Set clock high
        btsc    w4,#7
        xor     #0x09,w14
        repeat  #SPI_FAST_DELAY/2       ; Wait for slave to latch
        nop
        bclr    SPI_LAT,#SCK_PIN        ; Set clock low
        btsc    SPI_PORT,#SDI_PIN       ; Did slave output a high?
        bset    w0,#0                   ; Yes, copy into result
        repeat  #SPI_FAST_DELAY/2
        nop
        .endr
        nop
        nop
        pop     w4
        pop.d   w2                      ; Restore callers registers
        bset    T1CON,#TON              ; Restart cycle timer
        return
        .endif

        .if     REV_1502
        ; TODO Set SPI speed
        mov     w0,SPI1BUF              ; Initiate an SPI transmit
        ; Do CRC7 calculation
        bclr    T1CON,#TON              ; Stop cycle timer
1:      btss    SPI1STAT,#SPIRBF        ; Wait for completion
        bra     1b
        bset    T1CON,#TON              ; Restart cycle timer
        mov     SPI1BUF,w0              ; Read the SPI input
        return
        .endif

; Transmit the byte of data in w0 to the SPI slave and return the data that was
; received at the same time. Suspend cycle counting during the data exchange.

        .global SpiSlow
SpiSlow:
        mov     w0,CRCDATL              ; Add byte to CRC16

        .if     REV_1412
        push.d  w2                      ; Save callers registers
        push    w4
        mov     #SPI_LAT,w2             ; Load port access values
        mov     #SDO_PIN,w3
        .rept   8
        sl.b    w14,w14                 ; Shift CRC7 one bit
        xor     w14,w0,w4
        sl.b    w0,w0                   ; Shift MSB into carry flag
        bsw.c   [w2],w3                 ; And write to port
        bset    SPI_LAT,#SCK_PIN        ; Set clock high
        btsc    w4,#7
        xor     #0x09,w14
        repeat  #SPI_SLOW_DELAY/2       ; Wait for slave to latch
        nop
        bclr    SPI_LAT,#SCK_PIN        ; Set clock low
        btsc    SPI_PORT,#SDI_PIN       ; Did slave output a high
        bset    w0,#0                   ; Yes, copy into result
        repeat  #SPI_SLOW_DELAY/2
        nop
        .endr
        nop
        nop
        pop     w4                      ; Restore callers registers
        pop.d   w2
        return
        .endif

        .if     REV_1502
        ; TODO Set SPI speed
        mov     w0,SPI1BUF              ; Initiate an SPI transmit

        ; Do CRC7 Calculation

        bclr    T1CON,#TON              ; Stop cycle timer
1:      btss    SPI1STAT,#SPIRBF        ; Wait for completion
        bra     1b
        bset    T1CON,#TON              ; Restart cycle timer
        mov     SPI1BUF,w0              ; Read the SPI input
        return
        .endif

;===============================================================================
; SD/MMC Card Interface
;-------------------------------------------------------------------------------

; Send the SD/MMC initialisation sequence to the card via SPI.

SdInit:
        push    w14
        rcall   SpiSetHi                ; Do at least 74 clock cycles
        rcall   SdIdleSlow
        rcall   SdIdleSlow
        rcall   SdIdleSlow
        rcall   SdIdleSlow
        rcall   SdIdleSlow
        rcall   SdIdleSlow
        rcall   SdIdleSlow
        rcall   SdIdleSlow
        rcall   SdIdleSlow
        rcall   SdIdleSlow

        rcall   SpiSetLo                ; Send CMD0 (RESET)
        mov     #SD_CMD0,w0
        mov     #0x0000,w1
        mov     #0x0000,w2
        rcall   SdCmndSlow
        mov     #0x01,w1                ; Wait for response
        rcall   SdWaitSlow
        rcall   SpiSetHi
        ; Handle timeout
        
        nop
        nop
        nop
        nop
        
        rcall   SdIdleSlow              ; Send dummy clock pulses

        rcall   SpiSetLo
        mov     #0x00ff,w3              ; Set attempt counter
1:      mov     #SD_CMD1,w0             ; Send CMD1 (SEND_OP_COND)
        mov     #0x0000,w1
        mov     #0x0000,w2
        rcall   SdCmndSlow   
        mov     #0x00,w1                ; Wait for response
        rcall   SdWaitSlow
        
        nop
        nop
        nop
        nop
        
        bra     z,2f                    ; Command succeeded?   
        dec     w3,w3                   ; No, try again
        bra     nz,1b
        ; Complete failure
    
2:      rcall   SpiSetHi
        nop
        nop
        nop
        nop
        
        rcall   SdIdleSlow              ; Send dummy clock pulses

        rcall   SpiSetLo
        mov     #SD_CMD16,w0            ; Send CMD16 (SET_BLOCKLEN)
        mov     #0x0000,w1              ; 512 bytes
        mov     #0x0200,w2
        rcall   SdCmndSlow
        mov     #0x00,w1                ; Wait for response
        rcall   SdWaitSlow
        rcall   SpiSetHi
        ; Handle timeout
        
        nop
        nop
        nop
        nop
        
        rcall   SdIdleSlow

        pop     w14
        return
        
        
; Read a block from an SD card. The target memory address should be specified in
; w1 and the LBA in w2:w3 (lo:hi)
        
SdRead:
        push    w1                      ; Save memory address
        rcall   SpiSetLo
        mov     #SD_CMD17,w0            ; Send read command and LBA
        mov     w3,w1
        rcall   SdCmndFast
        mov     #0x00,w1                ; Wait for response
        rcall   SdWaitFast
        mov     #0xfe,w1                ; Wait for response
        rcall   SdWaitFast
        
        pop     w1                      ; Recover buffer address
        mov     #512,w2                 ; Set block size
        clr     CRCWDATL                ; Clear CRC generator
        
 1:     rcall   SdIdleFast              ; Read abyte
        mov.b   w0,[w1++]
        dec     w2,w2
        bra     nz,1b
        
        rcall   SdIdleFast              ; Discard CRC
        rcall   SdIdleFast
        
        rcall   SpiSetHi
        bra     SdIdleFast
        
SdWrite:
        
        
        
        return

; Set a command to the SD card

SdCmndSlow:
        clr     w14                     ; Clear CRC values
        clr     CRCWDATL
        rcall   SpiSlow                 ; Send command byte
        lsr     w1,#8,w0
        rcall   SpiSlow                 ; Send MSB of argument
        ze      w1,w0
        rcall   SpiSlow
        lsr     w2,#8,w0
        rcall   SpiSlow
        ze      w2,w0
        rcall   SpiSlow                 ; Send LSB of argument
        bset    SR,#C                   ; Form CRC7 byte
        addc.b  w14,w14,w0
        bra     SpiSlow                 ; And send it

SdCmndFast:
        clr     w14                     ; Clear CRC values
        clr     CRCWDATL
        rcall   SpiFast                 ; Send command byte
        lsr     w1,#8,w0
        rcall   SpiFast                 ; Send MSB of argument
        ze      w1,w0
        rcall   SpiFast
        lsr     w2,#8,w0
        rcall   SpiFast
        ze      w2,w0
        rcall   SpiFast                 ; Send LSB of argument
        bset    SR,#C                   ; Form CRC7 byte
        addc.b  w14,w14,w0
        bra     SpiFast                 ; And send it

; Send an dummy byte to the card and check if the result byte matches w1 or a
; timeout is reached. Return with Z=1 if a match is found.

SdWaitSlow:
        mov     #0xff,w2                ; Set timeout counter
1:      rcall   SdIdleSlow              ; Send a dummy byte
        cp.b    w0,w1                   ; Result matches?
        bra     nz,2f
        return                          ; Yes, Z=1
2:      dec     w2,w2                   ; Reduce counter
        bra     nz,1b
        bclr    SR,#Z                   ; Force Z=0
        return
        
SdWaitFast:
        mov     #0xff,w2                ; Set timeout counter
1:      rcall   SdIdleFast              ; Send a dummy byte
        cp.b    w0,w1                   ; Result matches?
        bra     nz,2f
        return                          ; Yes, Z=1
2:      dec     w2,w2                   ; Reduce counter
        bra     nz,1b
        bclr    SR,#Z                   ; Force Z=0
        return
        
; Send an all HI dummy byte to the SD card and return the byte it send back.
        
SdIdleSlow:
        mov     #0xff,w0
        bra     SpiSlow
        
SdIdleFast:
        mov     #0xff,w0
        bra     SpiFast
	
;===============================================================================
; SD/MMC Manager
;-------------------------------------------------------------------------------
	
DiskManager:
        rcall   ClearScreen
        
        rcall   SdInit
        
        
        
        mov     #BLK0,w1
        clr     w2
        clr     w3
        rcall   SdRead
        
        
        nop
        nop
        nop
        nop
	
	reset

;===============================================================================
; Micro-Cycle Timer Interrupt
;-------------------------------------------------------------------------------

; Every Timer1 interrupt subtract one from the micro-cycle count used to make
; the emulated instruction timing exact.

        .global __T1Interrupt
__T1Interrupt:
        dec     CYCLE                   ; Decrement cycle counter
        bclr    IFS0,#T1IF              ; Reset the interrupt flag
        retfie

;===============================================================================
; 100Hz Timer Interrupt
;-------------------------------------------------------------------------------

; Every Timer2 interrupt mark the flags bits to show that

        .global __T2Interrupt
__T2Interrupt:
        bclr    IFS0,#T2IF              ; Reset the interrupt flag
        bset    INT_FLAGS,#INT_100HZ    ; Flag the interrupt
        retfie

;===============================================================================
; Pin Change Interrupt
;-------------------------------------------------------------------------------

; If IN1 changes from high to low then register an NMI for devices that support
; it.

        .global __CNInterrupt
__CNInterrupt:
        btss    IN1_PORT,#IN1_PIN       ; If the pin is now low
        bset    INT_FLAGS,#INT_NMI      ; .. then record an NMI
        bclr    IFS1,#CNIF              ; Reset the interrupt flag
        retfie

;===============================================================================
; Error Traps
;-------------------------------------------------------------------------------

; Catch errors when creating a debugable build. Look at the last address on the
; stack to find the location where the error occured.

        .ifdef  __DEBUG

        .global __OscillatorFail
__OscillatorFail:
        pop.d   w6
        bra     $

        .global __AddressError
__AddressError:
        pop.d   w6
        bra     $

        .global __HardTrapError
__HardTrapError:
        pop.d   w6
        bra     $

        .global __StackError
__StackError:
        pop.d   w6
        bra     $

        .global __SoftTrapError
__SoftTrapError:
        pop.d   w6
        bra     $

        .endif
        .end
