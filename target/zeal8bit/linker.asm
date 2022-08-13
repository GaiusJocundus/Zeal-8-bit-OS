; SPDX-FileCopyrightText: 2022 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

        ; Code and read-only data
        SECTION RST_VECTORS
        ORG 0
        SECTION SYSCALL_ROUTINES
        SECTION SYSCALL_TABLE
        SECTION KERNEL_TEXT
        SECTION KERNEL_STRLIB
        SECTION KERNEL_RODATA
        SECTION KERNEL_DRV_TEXT
        SECTION KERNEL_DRV_VECTORS

        ; RAM data
        SECTION KERNEL_BSS
        ORG 0xC000
        SECTION DRIVER_BSS