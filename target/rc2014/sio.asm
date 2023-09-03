; SPDX-FileCopyrightText: 2023 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0
DEFC SIO_PORTA_CTRL = 0x80
DEFC SIO_PORTA_DATA = 0x81
DEFC SIO_PORTB_CTRL = 0x82
DEFC SIO_PORTB_DATA = 0x83

    ; Make sure the following is aligned on 2!
rc2014_int_vector:
    DEFW sio_int_handler
    ; In theory we need to empty the next 254 bytes, but in practice we only have one device that triggers interrupts

sio_int_handler:
    ; Handle the received character here by putting them inside a ringbuffer
    ei
    reti

sio_init:
    ; Set Z80 CPU vector address
    ld a, sio_int_handler >> 8
    ld i, a

    ; Configure register 1 to have a single interrupt vector for all status, enable Rx Interrupts
    ld a, 1  ; reg to configure
    out (SIO_PORTA_CTRL), a
    ld a, 0x19
    out (SIO_PORTA_CTRL), a
    
    ; Configure reset vector (register 2) to 0
    ld a, 2
    out (SIO_PORTA_CTRL), a
    xor a
    out (SIO_PORTA_CTRL), a
    
    ; Configure register 3 to accept 8-bits/char, enable Rx
    ld a, 3
    out (SIO_PORTA_CTRL), a
    ld a, 0xc1
    out (SIO_PORTA_CTRL), a

    ; Configure register 4 to have no parity, no sync mode, 1 stop bit and clock mode x1 (not sure how this works?)
    ld a, 4
    out (SIO_PORTA_CTRL), a
    ; A is already 4... send it again
    out (SIO_PORTA_CTRL), a

    ; Configure register 5 to have 8 bits per Tx byte
    ld a, 5
    out (SIO_PORTA_CTRL), a
    ld a, 0x68
    out (SIO_PORTA_CTRL), a

    ret
