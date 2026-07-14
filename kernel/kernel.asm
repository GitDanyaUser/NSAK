[bits 32]
[org 0x100000]

KERNEL_BG    equ 0x1F        ; White on Blue
ROWS         equ 25
COLS         equ 80
VIDEO_MEMORY equ 0xB8000

start:

    mov edi, VIDEO_MEMORY
    mov ax, 0x1F20           ; Space with blue background
    mov ecx, ROWS * COLS

.clear:
    stosw
    loop .clear

    ; Print "NSAK" centered

    mov esi, title
    mov edi, VIDEO_MEMORY + ((12 * COLS + 38) * 2)

.print_title:
    lodsb
    test al, al
    jz .footer
    mov ah, KERNEL_BG
    stosw
    jmp .print_title

.footer:

    ; Print footer

    mov esi, copyright
    ; Footer length = 31 chars
    ; Start column = (80-31)/2 = 24
    mov edi, VIDEO_MEMORY + ((24 * COLS + 24) * 2)

.print_footer:
    lodsb
    test al, al
    jz .halt
    mov ah, KERNEL_BG
    stosw
    jmp .print_footer

.halt:
    cli

.forever:
    hlt
    jmp .forever

title:
    db "NSAK",0

copyright:
    db "Copyright (C) 2026 GitDanyaUser",0