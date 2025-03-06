; ChucklesOS Memory Writer Command
; cmd5.s - Memory writing command implementation

[org 0x8600]      ; Sixth sector starts at 0x8600
[bits 16]

command_handler5:
    ; Get buffer address from stack
    push bp
    mov bp, sp
    mov si, [bp+4]  ; First parameter (buffer address)

    ; Compare input with known commands
    mov di, cmd_mwri
    call strcmp
    jc do_mwri

    ; If no match found, return without carry flag
    pop bp
    clc
    ret

do_mwri:
    ; Ask for address
    mov si, address_prompt
    call print_string

    ; Get keyboard input for address
    mov di, address_buffer
    call get_input

    ; Convert hex string to number
    mov si, address_buffer
    call hex_to_int   ; Result in DX:AX

    ; Store the converted address for access
    mov [memory_address], ax
    mov [memory_address+2], dx

    ; Ask for byte values
    mov si, bytes_prompt
    call print_string

    ; Get keyboard input for bytes
    mov di, byte_buffer
    call get_input

    ; Parse and write the bytes
    mov ax, byte_buffer
    push ax
    mov ax, [memory_address]
    push ax
    mov ax, [memory_address+2]
    push ax
    call 0x8800        ; Call byte parsing and writing routine in cmd6.s
    add sp, 6

    ; Print success message
    mov si, write_success
    call print_string
    
    pop bp
    stc             ; Set carry to indicate command handled
    ret

; Helper Functions
; Get input from keyboard
get_input:
    push cx
    mov cx, 0       ; Character counter

input_loop:
    xor ax, ax
    int 0x16        ; Wait for keypress

    cmp al, 0x0D    ; Check if Enter key
    je input_done

    cmp al, 0x08    ; Check if Backspace
    je handle_backspace

    cmp cx, 63      ; Limit input length
    je input_loop
    
    ; Echo character and store it
    mov ah, 0x0E
    int 0x10

    stosb           ; Store character in buffer
    inc cx
    jmp input_loop

handle_backspace:
    cmp cx, 0           ; Check if buffer is empty
    je input_loop

    dec di              ; Remove last character
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp input_loop

input_done:
    mov byte [di], 0    ; Null terminate input
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    
    pop cx
    ret

; Convert hex string to integer
; Input: SI points to null-terminated hex string
; Output: DX:AX contains the 32-bit value
hex_to_int:
    push bx
    push cx
    
    xor dx, dx      ; Clear DX (high word)
    xor ax, ax      ; Clear AX (low word)
    xor bx, bx      ; Clear BX for digit value
    
hex_convert_loop:
    mov bl, [si]    ; Get character
    test bl, bl     ; Check for null terminator
    jz hex_convert_done
    
    ; Shift result left by 4 bits (multiply by 16)
    shl ax, 4
    rcl dx, 4       ; Rotate with carry for overflow into DX
    
    ; Convert ASCII to value
    cmp bl, '9'
    jbe decimal_digit
    
    ; Convert A-F, a-f to 10-15
    or bl, 0x20     ; Convert to lowercase
    sub bl, 'a'-10
    jmp add_digit
    
decimal_digit:
    sub bl, '0'     ; Convert 0-9
    
add_digit:
    add ax, bx      ; Add digit value
    adc dx, 0       ; Add carry to high word if needed
    
    inc si          ; Move to next character
    jmp hex_convert_loop
    
hex_convert_done:
    pop cx
    pop bx
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
cmd_mwri:       db "mwri", 0
address_prompt: db "Enter memory address (hex): ", 0
bytes_prompt:   db "Enter bytes to write (hex, separated by spaces): ", 0
write_success:  db "Memory write complete", 0x0D, 0x0A, 0

; Buffers and variables
address_buffer: times 9 db 0     ; Space for up to 8 hex digits plus null
byte_buffer:    times 64 db 0    ; Space for byte values
memory_address: dd 0             ; 32-bit memory address storage

times 512-($-$$) db 0   ; Pad to 512 bytes
