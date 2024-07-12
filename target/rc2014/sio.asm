; SPDX-FileCopyrightText: 2023 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0
    INCLUDE "osconfig.asm"
    INCLUDE "errors_h.asm"
    INCLUDE "drivers_h.asm"
    INCLUDE "utils_h.asm"
    INCLUDE "stdout_h.asm"

    DEFC SIO_PORTA_CTRL = 0x80
    DEFC SIO_PORTA_DATA = 0x81
    DEFC SIO_PORTB_CTRL = 0x82
    DEFC SIO_PORTB_DATA = 0x83

    SECTION KERNEL_DRV_TEXT

sio_init:
    ; Initialize the ring buffer now
    xor a
    ld hl, RBUFHD
    ld (hl), a
    ld hl, RBUFTL
    ld (hl), a

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

    ; Configure register 4 to have no parity, no sync mode, 1 stop bit and clock mode x1
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

sio_read:
sio_write:
sio_open:
sio_close:
sio_seek:
sio_ioctl:
sio_deinit:

    ; Size of the ringbuffer
    DEFC RING_BUF_SIZE = 0xF

    SECTION DRIVER_BSS
RBUFHD: DEFS 1 ; allocate 1 byte
RBUFTL: DEFS 1 ; allocate 1 byte
RBUF: DEFS RING_BUF_SIZE ; Allocate RING_BUF_SIZE bytes for the buffer itself

    SECTION KERNEL_DRV_VECTOR
this_struct:
NEW_DRIVER_STRUCT("SER0", \
                  sio_init, \
                  sio_read, sio_write, \
                  sio_open, sio_close, \
                  sio_seek, sio_ioctl, \
                  sio_deinit)
