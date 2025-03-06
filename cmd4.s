; ChucklesOS Memory Reader Command
; cmd4.s - Memory reading command implementation

[org 0x8400]      ; Fifth sector starts at 0x8400
[bits 16]

command_handler4:
    ; Get buffer address from stack
    push bp
    mov bp, sp
    mov si, [bp+4]  ; First parameter (buffer address)

    ; Compare input with known commands
    mov di, cmd_rmem
    call strcmp
    jc do_rmem

    ; If no match found, return without carry flag
    pop bp
    clc
    ret

do_rmem:
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

    ; Now read bytes from that address (assume near pointer - just use AX)
    mov bx, ax        ; Address to read from

    ; Print address header
    mov si, reading_msg
    call print_string

    ; Print formatted address
    mov dx, [memory_address+2]
    mov ax, [memory_address]
    call print_hex_long

    mov si, colon_msg
    call print_string

    ; Read and display memory values (16 bytes)
    mov cx, 16        ; Number of bytes to read

memory_read_loop:
    ; Read a byte
    mov al, [bx]

    ; Print a space before each byte
    push ax
    mov al, ' '
    call print_char
    pop ax

    ; Print byte in hex
    call print_hex_byte

    ; Move to next byte
    inc bx
    dec cx
    jnz memory_read_loop

    ; Print newline
    mov si, newline
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

    cmp cx, 8       ; Limit input to 8 chars (4 bytes address)
    je input_loop

    ; Check if character is valid hex (0-9, A-F, a-f)
    call is_hex
    jnc input_loop  ; Skip if not valid hex

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

; Check if character in AL is a valid hex digit
; Returns with carry set if valid, clear if invalid
is_hex:
    cmp al, '0'
    jb not_hex
    cmp al, '9'
    jbe valid_hex

    ; Convert to uppercase if lowercase
    cmp al, 'a'
    jb check_upper
    cmp al, 'f'
    ja not_hex
    sub al, 32      ; Convert to uppercase
    jmp valid_hex

check_upper:
    cmp al, 'A'
    jb not_hex
    cmp al, 'F'
    ja not_hex

valid_hex:
    stc             ; Set carry flag for valid
    ret
not_hex:
    clc             ; Clear carry flag for invalid
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
    sub bl, 'A'-10  ; Convert A-F to 10-15
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

; Print a byte in hexadecimal
; Input: AL contains the byte to print
print_hex_byte:
    push ax
    push bx

    mov bx, ax      ; Save the byte

    ; Print high nibble
    shr al, 4
    call print_hex_digit

    ; Print low nibble
    mov al, bl
    and al, 0x0F
    call print_hex_digit

    pop bx
    pop ax
    ret

; Print a 32-bit value in hexadecimal
; Input: DX:AX contains the value
print_hex_long:
    push ax
    push dx

    ; Print "0x" prefix
    mov al, '0'
    call print_char
    mov al, 'x'
    call print_char

    ; Print high word (DX)
    mov al, dh
    call print_hex_byte
    mov al, dl
    call print_hex_byte

    ; Print low word (AX)
    mov al, ah
    call print_hex_byte
    mov al, al
    call print_hex_byte

    pop dx
    pop ax
    ret

; Print a hexadecimal digit
; Input: AL contains the digit (0-15)
print_hex_digit:
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jbe print_digit
    add al, 'A'-'0'-10
print_digit:
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
cmd_rmem:       db "rmem", 0
address_prompt: db "Enter memory address (hex): ", 0
reading_msg:    db "Reading from address ", 0
colon_msg:      db ":", 0
newline:        db 0x0D, 0x0A, 0

; Buffers and variables
address_buffer: times 9 db 0    ; Space for up to 8 hex digits plus null
memory_address: dd 0            ; 32-bit memory address storage

times 512-($-$$) db 0   ; Pad to 512 bytes
