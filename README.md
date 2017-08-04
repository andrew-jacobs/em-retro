# EM-RETRO - A Retro Microprocessor Emulator

EM-RETRO is a emulator for eight early 8-bit microprocessors based on a modern
16-bit micro-controller. Currently the emulations for the SC/MP, CDP 1802, 6800,
6502, 65C02 and 8080 are complete and working. The code for the Z80 and 6809
is not yet fully functional.

All you need to play with EM-RETRO is a PIC24EP512GP202 micro-controller, three
capacitors (2x 100nF and 1x 10uF tantalum), a 10K resistor, a USB serial adapter
and a PICKit 3 programmer.

## The Emulations

### National Semiconductor SC/MP

Released in 1974 the SC/MP is a stackless 8-bit microprocessor with four 16-bit
registers. In the UK Sir Clive Sinclair's Science of Cambridge company used the SC/MP
processor in its MK14 computer.

National Semiconductor released a version of the BASIC programming language for
its processor and this is used by the emulator as its boot ROM at startup.

#### Memory Map

The SC/MP processor naturally addresses memory as 4K pages. The emulator
initialises its memory map as shown below. This arrangement provides 44K
of RAM -- more than any real SC/MP system would ever have had. 

| From | To   | Contents       |
| ---- | ---- | -------------- |
| 0000 | 0fff | NIBL ROM       |
| 1000 | 1fff | RAM            |
| 2000 | 2fff | RAM            |
| 3000 | 3fff | RAM            |
| 4000 | 4fff | RAM            |
| 5000 | 5fff | RAM            |
| 6000 | 6fff | RAM            |
| 7000 | 7fff | RAM            |
| 8000 | 8fff | RAM            |
| 9000 | 9fff | RAM            |
| a000 | afff | RAM            |
| b000 | bfff | RAM            |
| c000 | cfff | ROM (Reserved) |
| d000 | dfff | ROM (Reserved) |
| e000 | efff | ROM (Reserved) |
| f000 | ffff | ROM (Reserved) |

The last four pages are reserved for ROM images.

#### Pseudo Instructions

The SC/MP emulator provides two pseudo instructions for sending and
recieving characters via the hosts UART. Both of these operations are
blocking waiting space in the UART to transmit or for a data byte to
arrive.

| Hex | Opcode | Description            |
| --- | ------ | ---------------------- |
| 20  | TXD    | Transmit the character |
| 21  | RXD    | Receive a characater   |

### RCA CDP 1802

#### Pseudo Ports

The CDP 1802 emulation uses pseudo port address in conjunction with
the INP and OUT instructions to access the host processor.

| Port | Function           |
|:----:| ------------------ |
| 1    | Interrupt Flags    |
| 2    | Interrupt Enables  |
| 3    | UART               |

### Motorola 6800

#### Memory Map

The layout of the 6800's memory has been arranged to support the FLEX operating
system although this not available yet.

| From | To   | Contents        |
| ---- | ---- | --------------- |
| 0000 | 7fff | RAM             |
| 8000 | 9fff | Not Implemented |
| a000 | cfff | RAM             |
| d000 | dfff | Not Implemented |
| e000 | ffff | Boot ROM        |

#### Pseudo Instructions

| Hex   | Opcode    | Description            |
| ----- | --------- | ---------------------- |
| 8f nn | SYS A #nn | Invoke System Function |
| cf nn | SYS B #nn | Invoke System Function |

### MOS 6502

The 6502 emulator has been configured to boot as a virtual BBC Microcomputer
and contains a copy of BBC BASIC along with a simulation of enough of the
Acorn Machine Operating System (MOS) to persude it to work.

#### Memory Map

| From | To   | Contents        |
| ---- | ---- | --------------- |
| 0000 | 00ff | Zero Page RAM   |
| 0100 | 01ff | Stack           |
| 0200 | 7fff | RAM             |
| 8000 | bfff | Banked ROM Area |
| c000 | ffff | OS ROM          |

#### Pseudo Instructions

The 6502 emulator adds a COP instruction ($02 nn -- COP #$nn) to the procesors.
The immediate value indicates which operation is required and the A register
is used to pass data.

| Operation | Description                  |
|:---------:| ---------------------------- |
| 00        | Read Interrupt Flags         |
| 01        | Write Interrupt Flags        |
| 02        | Read Interrupt Enable Flags  |
| 03        | Write Interrupt Enable Flags |
| 04        | UART Transmit                |
| 05        | UART Recieve                 |
| 06        | Clear Interrupt Flag Bit     |

An additional instruction ($bb -- BNK) is reserved to switch the 16K banked
ROM area. This isn't currently implemented so the FORTH and LISP images in
the host firmware cannot be accessed yet.

### Western Design Center 65C02

The Western Design Center's 65C02 is an enhanced version of the MOS 6502
processor that fixes the 6502's bugs and adds some addition instructions
(and an additional addressing mode).

#### Memory Map

| From | To   | Contents        |
| ---- | ---- | --------------- |
| 0000 | 00ff | Zero Page RAM   |
| 0100 | 01ff | Stack           |
| 0200 | afff | RAM             |
| b000 | ffff | Boot ROM        |

#### Pseudo Instructions

The 65C02 emulator also adds a COP instruction ($02 nn -- COP #$nn) to the processor.
The immediate value indicates which operation is required and the A register
is used to pass data.

| Operation | Description                  |
|:---------:| ---------------------------- |
| 00        | Read Interrupt Flags         |
| 01        | Write Interrupt Flags        |
| 02        | Read Interrupt Enable Flags  |
| 03        | Write Interrupt Enable Flags |
| 04        | UART Transmit                |
| 05        | UART Recieve                 |
| 06        | Clear Interrupt Flag Bit     |

### Intel 8080

### Zilog Z80

### Motorola 6809

