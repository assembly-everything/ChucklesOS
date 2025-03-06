; ChucklesOS Byte Parser and Writer
; cmd6.s - Byte parsing and writing routine

[org 0x8800]      ; Seventh sector starts at 0x8800
[bits 16]

; Parse and write bytes
; Parameters:
; - [bp+8]: Pointer to byte string
; - [bp+6]: Target address (low word)
; - [bp+4]: Target address (high word)
byte_parser:
    push bp
    mov bp, sp

    ; Save registers
    push es
    push di
    push si

    ; Set up target address
    mov ax, ds
    mov es, ax
    mov di, [bp+6]      ; Low word of target address
    mov si, [bp+8]      ; Byte string pointer

    ; Main parsing loop
    call skip_spaces     ; Skip any leading spaces

parse_loop:
    cmp byte [si], 0    ; Check for end of string
    je parsing_done

    ; Parse a byte
    call parse_byte     ; Result in AL

    ; Write the byte to memory
    stosb               ; Write AL to [ES:DI] and increment DI

    ; Skip spaces to next byte
    call skip_spaces

    jmp parse_loop

parsing_done:
    ; Restore registers
    pop si
    pop di
    pop es

    pop bp
    ret

; Skip spaces in the string
; Input: SI points to string
; Output: SI points to next non-space character
skip_spaces:
    cmp byte [si], ' '
    jne skip_done
    inc si
    jmp skip_spaces
skip_done:
    ret

; Parse a byte from hexadecimal string
; Input: SI points to hex digit(s)
; Output: AL contains the byte value, SI incremented past the byte
parse_byte:
    push bx

    ; Parse first digit
    mov al, [si]
    call hex_digit_value    ; Convert to value in AL
    mov bl, al              ; Save first digit value
    inc si

    ; Check if there's a second digit
    cmp byte [si], ' '
    je single_digit
    cmp byte [si], 0
    je single_digit

    ; Parse second digit
    shl bl, 4               ; Shift first digit to high nibble
    mov al, [si]
    call hex_digit_value    ; Convert to value in AL
    add al, bl              ; Combine digits
    inc si

    jmp parse_byte_done

single_digit:
    mov al, bl              ; Just use the single digit

parse_byte_done:
    pop bx
    ret

; Convert hex character to value
; Input: AL contains ASCII hex character
; Output: AL contains value (0-15)
hex_digit_value:
    ; Convert from ASCII to value
    cmp al, '9'
    jbe decimal_digit

    ; Handle A-F or a-f
    or al, 0x20     ; Convert to lowercase
    sub al, 'a'-10
    jmp digit_done

decimal_digit:
    sub al, '0'     ; Convert 0-9

digit_done:
    ret

; Debug print functions (not used in final code)
print_char:
    mov ah, 0x0E
    int 0x10
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

times 512-($-$$) db 0   ; Pad to 512 bytes
