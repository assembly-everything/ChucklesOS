; ChucklesOS Bootloader
; boot.s - Complete bootloader with multiple sector support

[org 0x7c00]
[bits 16]

start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Load second, third, and fourth sectors
    mov ah, 0x02    ; BIOS read sector function
    mov al, 3       ; Number of sectors to read (3 sectors for all command sets)
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Start from Sector 2
    mov dh, 0       ; Head 0
    mov dl, 0x80    ; First hard drive
    mov bx, 0x7E00  ; Load to 0x7E00
    int 0x13
    jc disk_error   ; Jump if carry flag set (error)

    ; Clear screen
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Print welcome message
    mov si, welcome_msg
    call print_string

shell_loop:
    mov si, prompt
    call print_string
    
    ; Get keyboard input
    mov di, input_buffer
    mov cx, 0       ; Character counter
    
input_loop:
    xor ax, ax
    int 0x16        ; Wait for keypress
    
    cmp al, 0x0D    ; Check if Enter key
    je handle_enter
    
    cmp al, 0x08    ; Check if Backspace
    je handle_backspace
    
    cmp cx, 63      ; Check buffer limit
    je input_loop
    
    ; Echo character and store it
    mov ah, 0x0E
    int 0x10
    
    stosb           ; Store character in buffer
    inc cx
    jmp input_loop

handle_enter:
    mov byte [di], 0    ; Null terminate input
    mov al, 0x0D
    mov ah, 0x0E
    int 0x10
    mov al, 0x0A
    int 0x10
    
    ; Try first command set
    mov ax, input_buffer
    push ax
    call 0x7E00         ; Call first command handler
    add sp, 2
    jc shell_loop       ; If command was handled, continue
    
    ; Try second command set if first one didn't handle it
    mov ax, input_buffer
    push ax
    call 0x8000         ; Call second command handler
    add sp, 2
    jc shell_loop       ; If command was handled, continue
    
    ; Try third command set if second one didn't handle it
    mov ax, input_buffer
    push ax
    call 0x8200         ; Call third command handler
    add sp, 2
    jmp shell_loop      ; Continue regardless of result

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

disk_error:
    mov si, disk_error_msg
    call print_string
    jmp $               ; Hang system

print_string:
    lodsb
    or al, al
    jz done
    mov ah, 0x0E
    int 0x10
    jmp print_string
done:
    ret

; Data section
welcome_msg:    db "This is a test build of ChucklesOS-1.08", 0x0D, 0x0A
                db "Build: 25222-1027", 0x0D, 0x0A
                db "Ver: 1.08", 0x0D, 0x0A, 0
prompt:         db "#>", 0
disk_error_msg: db "Error loading command handler", 0x0D, 0x0A, 0

; Shared input buffer at known location
input_buffer:   times 64 db 0

times 510-($-$$) db 0
dw 0xAA55