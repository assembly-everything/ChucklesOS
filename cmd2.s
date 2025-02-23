; ChucklesOS Extended Command Handler
; cmd2.s - Second command set implementation

[org 0x8000]      ; Third sector starts at 0x8000
[bits 16]

command_handler2:
    ; Get buffer address from stack
    push bp
    mov bp, sp
    mov si, [bp+4]  ; First parameter (buffer address)

    ; Compare input with known commands
    mov di, cmd_time
    call strcmp
    jc do_time

    mov si, [bp+4]  ; Reset SI to start of buffer
    mov di, cmd_color
    call strcmp
    jc do_color

    mov si, [bp+4]  ; Reset SI to start of buffer
    mov di, cmd_off
    call strcmp
    jc do_off

    ; If no match found, return without carry flag
    pop bp
    clc
    ret

do_time:
    ; Get system time
    mov ah, 0x02
    int 0x1A        ; BIOS time service

    ; Convert BCD to ASCII and print
    mov al, ch      ; Hours
    call print_bcd
    mov al, ':'
    call print_char
    mov al, cl      ; Minutes
    call print_bcd
    mov al, ':'
    call print_char
    mov al, dh      ; Seconds
    call print_bcd
    mov si, newline
    call print_string

    pop bp
    stc             ; Set carry to indicate command handled
    ret

do_color:
    ; Save registers
    push ax
    push bx
    push cx
    push dx

    ; Clear screen
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Display color blocks
    mov cx, 16      ; 16 colors
    mov bl, 0       ; Start with color 0

color_loop:
    ; Set color attributes
    mov ah, 0x09
    mov al, 'X'     ; Character to display
    mov bh, 0       ; Page number
    mov cx, 5       ; Repeat character 5 times
    int 0x10

    ; Move cursor
    inc bl
    mov ah, 0x02
    mov bh, 0
    int 0x10

    dec cx
    jnz color_loop

    ; Restore registers
    pop dx
    pop cx
    pop bx
    pop ax

    mov si, newline
    call print_string

    pop bp
    stc
    ret

do_off:
    ; APM power off
    mov ax, 0x5300  ; APM Installation check
    xor bx, bx
    int 0x15
    jc power_off_failed

    ; Set APM version (to 1.2)
    mov ax, 0x530E
    xor bx, bx
    mov cx, 0x0102
    int 0x15

    ; Set APM interface to protected mode 32-bit
    mov ax, 0x5303
    xor bx, bx
    int 0x15

    ; Turn off system
    mov ax, 0x5307
    mov bx, 0x0001  ; All devices
    mov cx, 0x0003  ; Power off
    int 0x15

power_off_failed:
    mov si, power_fail_msg
    call print_string
    pop bp
    stc
    ret

; Helper functions
print_bcd:
    push ax
    shr al, 4       ; Get high digit
    add al, '0'
    call print_char
    pop ax
    and al, 0x0F    ; Get low digit
    add al, '0'
    call print_char
    ret

print_char:
    mov ah, 0x0E
    int 0x10
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
cmd_time:    db "time", 0
cmd_color:   db "color", 0
cmd_off:     db "off", 0
newline:     db 0x0D, 0x0A, 0
power_fail_msg: db "Power off failed", 0x0D, 0x0A, 0

times 512-($-$$) db 0   ; Pad to 512 bytes