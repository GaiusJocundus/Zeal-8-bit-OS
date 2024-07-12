; SPDX-FileCopyrightText: 2023 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0
    INCLUDE "osconfig.asm"
    INCLUDE "errors_h.asm"
    INCLUDE "drivers_h.asm"
    INCLUDE "utils_h.asm"
    INCLUDE "stdout_h.asm"
    INCLUDE "interrupt_vect.asm"

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

    EXTERN zos_vfs_set_stdout

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

    ld hl, this_struct
    call zos_vfs_set_stdout

    INTERRUPTS_ENABLE()

    PUBLIC interrupt_default_handler
    PUBLIC interrupt_sio_handler
interrupt_default_handler:
interrupt_sio_handler:
    ENTER_CRITICAL()
    push af
;Check if buffer is full
    ld a,(RBUFHD)
    ld b,a
    ld a,(RBUFTL)
    dec a
    and RBUF_SIZE
    cp b
    jr nz,sio_read
    in a,(SIO_PORTA_DATA)
    jr _sio_read_exit
sio_read:
    in a,(SIO_PORTA_DATA)
    ld hl,RBUF
    ld l,b
    ld (hl),a
_sio_read_exit:
    pop af
    EXIT_CRITICAL()
    reti

sio_write:
    ENTER_CRITICAL()
    push af
    ld a,(RBUFTL)
    ld b,a
    ld a,(RBUFHD)
    cp b
    jr nz,_sio_write_okay
;Buffer is empty, set carry flag and exit
    scf
    jp _sio_write_exit
_sio_write_okay:
    ld hl,RBUF
    ld l,b
    ld a,(hl)
    out (SIO_PORTA_DATA),a
    ld a,l
    inc a
    and RBUF_SIZE
    ld (RBUFTL),a
    or a
_sio_write_exit:
    pop af
    EXIT_CRITICAL()
    reti

sio_open:
sio_close:
sio_seek:
sio_ioctl:
sio_deinit:
    xor a
    ret

    ; Size of the ringbuffer
    DEFC RBUF_SIZE = 0xF

    SECTION DRIVER_BSS
RBUFHD: DEFS 1 ; allocate 1 byte
RBUFTL: DEFS 1 ; allocate 1 byte
RBUF: DEFS RBUF_SIZE ; Allocate RBUF_SIZE bytes for the buffer itself

    SECTION KERNEL_DRV_VECTOR
this_struct:
NEW_DRIVER_STRUCT("SER0", \
                  sio_init, \
                  sio_read, sio_write, \
                  sio_open, sio_close, \
                  sio_seek, sio_ioctl, \
                  sio_deinit)
