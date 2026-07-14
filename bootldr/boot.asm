[bits 16]
[org 0x7c00]

; --- THE BOOT INFO TABLE (Injected by xorriso) ---
times 8 db 0            ; Padding
boot_lba: dd 0          ; xorriso puts the sector LBA here!
; --------------------------------------------------

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Preserve boot drive index in DL passed by BIOS
    mov [boot_drive], dl

    ; Read the address from the El Torito Table
    mov eax, [boot_lba]
    add eax, 1          ; Sector immediately following the boot sector

    ; Update DAP with correct LBA
    mov [dap_lba], eax

    ; Read 16 sectors (8 KB) to fully load Stage 2 into 0x7E00
    mov ah, 0x42
    mov dl, [boot_drive]
    mov si, dap
    int 0x13
    jc disk_error
    
    ; Pass boot drive back to Stage 2 and jump
    mov dl, [boot_drive]
    jmp 0x7e00

disk_error:
    mov ax, 0xB800
    mov es, ax
    mov byte [es:0], 'E'
    mov byte [es:1], 0x0C
    hlt

boot_drive: db 0

align 4
dap:
    db 0x10, 0          ; DAP size
    dw 16               ; Read 16 sectors
    dw 0x7e00           ; Target offset
    dw 0x0000           ; Target segment
dap_lba:
    dq 0

times 510-($-$$) db 0
dw 0xAA55