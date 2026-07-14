[bits 16]
[org 0x7e00]

stage2_start:
    ; 1. Explicitly set DS and ES to 0x0000 so all variables align perfectly
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; mov ax, 0x0013      ; AH=0x00 (Set Video Mode), AL=0x13 (320x200 256-color)
    ; int 0x10            ; Only when the time comes

    ; 2. Preserve the boot drive number
    mov [boot_drive], dl

    ; 3. Print signature
    mov si, msg_sig
    call print_string

    ; 4. Enable A20 Line
    in al, 0x92
    or al, 2
    out 0x92, al

    ; 5. Read the Primary Volume Descriptor (PVD is Sector 16)
    mov dword [dap_lba], 16
    mov word [dap_segment], 0x0000
    mov word [dap_offset], 0x9000   ; Low bounce buffer
    mov word [dap_sectors], 1       ; Read 1 CD sector (2048 bytes)
    call read_sectors

    ; Extract Root Directory LBA from PVD (offset 156 + 2)
    mov eax, [0x9000 + 158]
    mov [root_dir_lba], eax

    ; 6. Read Root Directory Sector
    mov dword [dap_lba], eax
    mov word [dap_segment], 0x0000
    mov word [dap_offset], 0x9000
    mov word [dap_sectors], 1
    call read_sectors

    ; 7. Parse Directory Records for "NSAKKRNL.BIN;1"
    mov si, 0x9000
.parse_record:
    mov al, [si]                ; Record size
    cmp al, 0
    je .file_not_found

    mov cl, [si + 32]           ; Filename length
    cmp cl, 14
    jne .next_record

    ; Compare filename strings
    push si
    add si, 33                  ; Filename offset inside record
    mov di, filename
    mov cx, 14
.compare_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .mismatch
    inc si
    inc di
    loop .compare_loop
    pop si
    jmp .file_found

.mismatch:
    pop si
.next_record:
    xor ax, ax
    mov al, [si]
    add si, ax                  ; Jump to next record offset
    jmp .parse_record

.file_found:
    ; Preserve SI because we need to read file info from it
    mov [file_record_ptr], si
    mov si, msg_found
    call print_string
    mov si, [file_record_ptr]

    ; Read file's starting LBA (offset 2) and file size (offset 10)
    mov eax, [si + 2]
    mov [kernel_lba], eax
    mov ecx, [si + 10]          ; File size in bytes

    ; Convert size to CD sectors (rounding up)
    add ecx, 2047
    shr ecx, 11
    mov [kernel_sectors], cx

    ; 8. LOAD KERNEL SECTOR-BY-SECTOR ABOVE 1 MB (0x100000)
.load_loop:
    cmp word [kernel_sectors], 0
    je .loading_done

    ; Fetch next CD sector using memory variables
    mov eax, [kernel_lba]
    mov [dap_lba], eax
    mov word [dap_segment], 0x0000
    mov word [dap_offset], 0x9000
    mov word [dap_sectors], 1
    call read_sectors

    ; --- Unreal mode ---
    cli                         ; Disable interrupts
    push ds
    push es
    
    lgdt [gdt_descriptor]       ; Load GDT

    mov eax, cr0
    or al, 1
    mov cr0, eax                ; Turn on PM briefly
    jmp $+2                     ; Flush pipeline

    mov ax, 0x10
    mov fs, ax                  ; Unlock FS limit to 4GB

    mov eax, cr0
    and al, 0xFE
    mov cr0, eax                ; Turn PM off (back to Real Mode)
    
    pop es
    pop ds
    sti                         ; Re-enable interrupts

    ; Copy 2048 bytes using unlocked FS override (restoring used registers)
    push esi
    push ecx
    push edi
    
    mov esi, 0x9000             ; Source address (DS:ESI)
    mov edi, [kernel_dest]      ; Destination address (FS:EDI)
    mov ecx, 512                ; 512 dwords = 2048 bytes
    
.copy_sector:
    mov eax, [esi]              ; Load dword from DS:ESI
    mov [fs:edi], eax           ; Store dword to FS:EDI (High memory)
    add esi, 4
    add edi, 4
    loop .copy_sector
    
    mov [kernel_dest], edi      ; Save the updated destination pointer
    
    pop edi
    pop ecx
    pop esi
    ; ------------

    ; Safely increment LBA and decrement sectors left in memory
    inc dword [kernel_lba]
    dec word [kernel_sectors]
    jmp .load_loop

.loading_done:
    ; 9. Switch permanently to Protected Mode
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:init_pm

.file_not_found:
    mov si, msg_err
    call print_string
    cli
.halt_not_found:
    hlt
    jmp .halt_not_found

; --- HELPERS ---
print_string:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

read_sectors:
    mov ah, 0x42
    mov dl, [boot_drive]        ; Use dynamic preserved boot drive ID
    mov si, dap
    int 0x13
    jc .error
    ret
.error:
    mov si, msg_err
    call print_string
    cli
.halt_error:
    hlt
    jmp .halt_error

; --- DATA ---
boot_drive:      db 0
root_dir_lba:    dd 0
kernel_lba:      dd 0
kernel_sectors:  dw 0
kernel_dest:     dd 0x100000 ; Track destination pointer in RAM
file_record_ptr: dw 0
filename:        db "NSAKKRNL.BIN;1"
msg_sig:         db "NSAKB", 13, 10, 0
msg_found:       db "Loading kernel...", 13, 10, 0
msg_err:         db "FS Error!", 13, 10, 0

align 4
dap:
    db 0x10, 0
dap_sectors:
    dw 0
dap_offset:
    dw 0
dap_segment:
    dw 0
dap_lba:
    dq 0

; --- GDT ---
align 4
gdt_start:
    dd 0, 0
gdt_code:
    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00
gdt_data:
    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

[bits 32]
init_pm:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000            ; Configure high-PM stack pointer

    jmp 0x100000                ; Jump straight into our kernel