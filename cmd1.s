; ChucklesOS Command Handler
; cmd1.s - First command set implementation

[org 0x7E00]      ; Second sector starts at 0x7E00
[bits 16]

command_handler:
    ; Get buffer address from stack
    push bp
    mov bp, sp
    mov si, [bp+4]  ; First parameter (buffer address)
    
    ; Compare input with known commands
    mov di, cmd_help
    call strcmp
    jc do_help

    mov si, [bp+4]  ; Reset SI to start of buffer
    mov di, cmd_ver
    call strcmp
    jc do_ver

    mov si, [bp+4]  ; Reset SI to start of buffer
    mov di, cmd_clear
    call strcmp
    jc do_clear

    ; If no match found, print error
    mov si, error_msg
    call print_string
    
    pop bp
    ret

do_help:
    mov si, help_msg
    call print_string
    pop bp
    ret

do_ver:
    mov si, ver_msg
    call print_string
    pop bp
    ret

do_clear:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    pop bp
    ret

; String comparison routine
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
    clc         ; Clear carry flag (no match)
    ret
equal:
    pop di
    pop si
    stc         ; Set carry flag (match found)
    ret
; Print string routine
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
cmd_help:    db "help", 0
cmd_ver:     db "ver", 0
cmd_clear:   db "clear", 0
help_msg:    db "Available commands:", 0x0D, 0x0A
            db "  help    - Show this help message", 0x0D, 0x0A
            db "  ver     - Show OS version", 0x0D, 0x0A
            db "  clear   - Clear screen", 0x0D, 0x0A
            db "  time    - Display current time", 0x0D, 0x0A
            db "  color   - Display color test", 0x0D, 0x0A
            db "  off     - Power off system", 0x0D, 0x0A
            db "  reboot  - Restart system", 0x0D, 0x0A
            db "  pc-info - Show system information", 0x0D, 0x0A, 0
ver_msg:     db "ChucklesOS 1.08", 0x0D, 0x0A, 0
error_msg:   db "Unknown command", 0x0D, 0x0A, 0

times 512-($-$$) db 0   ; Pad to 512 bytes