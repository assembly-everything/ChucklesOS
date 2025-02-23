; ChucklesOS System Command Handler
; cmd3.s - System information and control commands

[org 0x8200]      ; Fourth sector starts at 0x8200
[bits 16]

command_handler3:
    ; Get buffer address from stack
    push bp
    mov bp, sp
    mov si, [bp+4]  ; First parameter (buffer address)

    ; Compare input with known commands
    mov di, cmd_reboot
    call strcmp
    jc do_reboot

    mov si, [bp+4]  ; Reset SI to start of buffer
    mov di, cmd_pcinfo
    call strcmp
    jc do_pcinfo

    ; If no match found, return without carry flag
    pop bp
    clc
    ret

do_reboot:
    ; Jump to reset vector
    jmp 0FFFFh:0    ; Jump to system reset
    pop bp          ; (This won't execute due to reboot)
    stc
    ret

do_pcinfo:
    ; Print CPU info header
    mov si, cpu_msg
    call print_string

    ; Get CPU type using INT 12h for memory
    int 0x12        ; Get conventional memory size in KB
    push ax         ; Save memory size

    ; Print memory size
    mov si, ram_msg
    call print_string
    pop ax
    call print_dec  ; Print memory size
    mov si, kb_msg
    call print_string

    ; Print newline
    mov si, newline
    call print_string

    pop bp
    stc
    ret

; Helper functions
print_dec:
    push ax
    push bx
    push cx
    push dx

    mov bx, 10      ; Divisor
    mov cx, 0       ; Counter for digits

convert_loop:
    xor dx, dx      ; Clear high word for division
    div bx          ; Divide by 10
    push dx         ; Save remainder
    inc cx          ; Increment digit counter
    test ax, ax     ; Check if quotient is zero
    jnz convert_loop

print_digits:
    pop dx          ; Get digit
    add dl, '0'     ; Convert to ASCII
    mov ah, 0x0E    ; BIOS teletype
    mov al, dl
    int 0x10
    loop print_digits

    pop dx
    pop cx
    pop bx
    pop ax
    ret

strcmp:
    push si
    push di
compare_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne not_equal
    cmp al, 0
    je equal
    inc si
    inc di
    jmp compare_loop
not_equal:
    pop di
    pop si
    clc
    ret
equal:
    pop di
    pop si
    stc
    ret

print_string:
    lodsb
    or al, al
    jz print_done
    mov ah, 0x0E
    int 0x10
    jmp print_string
print_done:
    ret

; Data section
cmd_reboot:  db "reboot", 0
cmd_pcinfo:  db "pc-info", 0
cpu_msg:     db "System Information:", 0x0D, 0x0A, 0
ram_msg:     db "Conventional Memory: ", 0
kb_msg:      db " KB", 0x0D, 0x0A, 0
newline:     db 0x0D, 0x0A, 0

times 512-($-$$) db 0   ; Pad to 512 bytes