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

    PUBLIC stdout_op_start
stdout_op_start:
    ret
stdout_op_end:
    ret

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
    push af ; save AF
    ;Check if buffer is full
    ld a, (RBUFHD) ;Get the buffer head pointer
    ld b, a ;Save it in B
    ld a, (RBUFTL) ;Get the butter tail pointer
    dec a ;Decrement by one
    cp b ;Is HEAD == (TAIL - 1)?
    jr nz, _read_okay
;Buffer is full, flush it
    in a, (SIO_PORTA_DATA) ;Read the overflow byte, clearing the interrupt
    jr _read_exit

_read_okay:
    in a, (SIO_PORTA_DATA)
    ld hl, RBUF
    ld l, b
    ld (hl), a
    ld a, l
    inc a
    and RING_BUF_SIZE
    ld (RBUFHD), a

_read_exit:
    pop af
    ei
    reti

    PUBLIC stdout_print_buffer
stdout_print_buffer:
sio_write:
    push af
    call _write_byte
    jr nc, _write_exit
    ld a, 0x28
    out (SIO_PORTA_CTRL), a

_write_byte:
    di
    ld a, (RBUFTL)
    ld b, a
    ld a, (RBUFHD)
    cp b
    jr nz, _write_okay

    scf
    jr _write_exit

_write_okay:
    ld hl, RBUF
    ld l, b
    ld a, (hl)
    out (SIO_PORTA_DATA), a
    ld a, l
    inc a
    and RING_BUF_SIZE
    ld (RBUFTL), a
    or a

_write_exit:
    pop af
    ei
    reti

sio_open:
sio_close:
sio_seek:
sio_ioctl:
sio_deinit:
    xor a ; Success
    ret

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
