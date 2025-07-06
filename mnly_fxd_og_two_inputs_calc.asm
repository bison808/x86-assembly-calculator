section .data
    prompt1 db 'Enter first number (1-99): ', 0
    prompt2 db 'Enter second number (1-99): ', 0
    result_msg db 'Result: ', 0

section .bss
    input1 resb 4
    input2 resb 4
    result_buffer resb 4        ; space for 3 digits + null

section .text
    global _main

_main:
    push rbp
    mov rbp, rsp

    ; get first digit
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, prompt1
    mov rdx, 28
    syscall

    mov rax, 0x2000003
    mov rdi, 0
    mov rsi, input1
    mov rdx, 3
    syscall

    ; Get second number
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, prompt2
    mov rdx, 29
    syscall

    mov rax, 0x2000003
    mov rdi, 0
    mov rsi, input2
    mov rdx, 3
    syscall

; Step 3: Convert first input
    mov al, [rel input1]              
    sub al, 48              
    mov bl, [rel input1 +1]
    cmp bl, 10
    je single_digit1

    ; Two digits: al*10 + second digit
    mov cl, al
    add al, al                  ; *2
    add al, al                  ; *4
    add al, cl                  ; *5
    add al, al                  ; *10
    sub bl, 48
    add al, bl

single_digit1:
    mov r8, rax
    and r8, 0xFF

    ; Convert second input
    mov al, [rel input2]
    sub al, 48
    mov bl, [rel input2 + 1]
    cmp bl, 10
    je single_digit2

    ; Two digits: al*10 + second digit
    mov cl, al
    add al, al
    add al, al
    add al, cl
    add al, al
    sub bl, 48
    add al, bl

single_digit2:
    and rax, 0xFF

    ; add the numbers
    add r8, rax                     ; r8 = sum (could be up to 198)

    ; Convert result to digits (handle up to 3 digits)
    mov rax, r8                     ; rax = sum

    ; Check if it's 3 digits (>= 100)
    cmp rax, 100
    jge three_digits

    ; two digits
    mov rbx, 10
    xor rdx, rdx
    div rbx                         ; rax = tens, rdx = ones
    add rax, 48
    mov [rel result_buffer], al
    add rdx, 48
    mov [rel result_buffer + 1], dl
    mov byte [rel result_buffer + 2], 0
    mov r9, 2                       ; print 2 chars
    jmp print_result

three_digits:
    ; Handle hundreds
    mov rbx, 100
    xor rdx, rdx
    div rbx                         ; rax = hundreds, rdx = remainder
    add rax, 48
    mov [rel result_buffer], al      ; store hundreds digit

    ; Handle tens and ones from remainder
    mov rax, rdx                    ; remainder (tens and ones)
    mov rbx, 10
    xor rdx, rdx
    div rbx                         ; rax = tens, rdx = ones
    add rax, 48
    mov [rel result_buffer + 1], al ; store tens digit
    add rdx, 48
    mov [rel result_buffer + 2], dl ; store ones digit
    mov byte [rel result_buffer + 3], 0
    mov r9, 3                       ; print 3 chars

print_result:
    ; Print result message
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, 8
    syscall

    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, result_buffer
    mov rdx, r9                     ; 2 or 3 chars
    syscall

    ; Add newline
    push 10
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    add rsp, 8

    mov rax, 0
    pop rbp
    ret