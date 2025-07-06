section .data
    prompt1 db 'Enter first number (1-99): ', 0
    prompt2 db 'Enter operation (+, -, *, /): ', 0
    prompt3 db 'Enter second number (1-99): ', 0
    result_msg db 'Result: ', 0
    error_msg db 'Error: Division by zero!', 10, 0
    minus_sign db '-', 0

    ; For floating conversion and display
    ten_float dd 10.0               ; float constant for base 10
    zero_float dd 0.0               ; float zero
    one_float dd 1.0                ; float one
    point_one dd 0.1                ; for decimal places
    minus_one_float dd -1.0         ; for negative

    decimal_point db '.',0

section .bss
    input1 resb 4
    operation resb 2
    input2 resb 4
    result_buffer resb 10            ; space for -9999.99 + null
    
    ; Float storage
    input1_float resd 1             ; 32-bit float for first number
    input2_float resd 1             ; 32-bit float for second number
    result_float resd 1             ; 32-bit float for result

section .text
    global _main

_main:
    push rbp
    mov rbp, rsp

    ; Get first number
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

    ; Get operation
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, prompt2
    mov rdx, 30
    syscall

    mov rax, 0x2000003
    mov rdi, 0
    mov rsi, operation
    mov rdx, 2
    syscall

    ; Get second number
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, prompt3
    mov rdx, 29
    syscall

    mov rax, 0x2000003
    mov rdi, 0
    mov rsi, input2
    mov rdx, 3
    syscall

    ; Convert first input to number
    call convert_input1
    mov r8, rax                         ; r8 = first number

    ; Convert second input to number
    call convert_input2
    mov r9, rax                         ; r9 = second number
    
    ; Convert both integers to floats  
    call convert_to_float

    ; Check operation and perform calculation
    mov al, [rel operation]
    cmp al, '+'
    je do_addition_float
    cmp al, '-'
    je do_subtraction_float
    cmp al, '*'
    je do_multiplication_float
    cmp al, '/'
    je do_division_float
    ; If invalid operation, just do addition as default
    jmp do_addition_float

do_addition_float:
    movss xmm0, [rel input1_float]      ; load first number
    movss xmm1, [rel input2_float]      ; load second number
    addss xmm0, xmm1                    ; add them
    movss [rel result_float], xmm0      ; store result
    jmp convert_float_result

do_subtraction_float:
    movss xmm0, [rel input1_float]
    movss xmm1, [rel input2_float]
    subss xmm0, xmm1
    movss [rel result_float], xmm0
    jmp convert_float_result

do_multiplication_float:
    movss xmm0, [rel input1_float]
    movss xmm1, [rel input2_float]
    mulss xmm0, xmm1
    movss [rel result_float], xmm0
    jmp convert_float_result

do_division_float:
    ; Check for division by zero
    movss xmm1, [rel input2_float]
    ucomiss xmm1, [rel zero_float]
    je division_error
    
    movss xmm0, [rel input1_float]
    divss xmm0, xmm1
    movss [rel result_float], xmm0
    jmp convert_float_result

division_error:
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, 25
    syscall
    jmp exit_program

print_final_result:
    ; Print result message
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, 8
    syscall

    ; Calculate actual string length
    lea rdi, [rel result_buffer]
    xor rcx, rcx                        ; counter
strlen_loop:
    mov al, [rdi + rcx]
    test al, al                         ; check for null
    jz strlen_done
    inc rcx
    cmp rcx, 10                         ; safety check
    jb strlen_loop
strlen_done:
    
    ; Print result with calculated length
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, result_buffer
    mov rdx, rcx                        ; use calculated length
    syscall
    
    ; Print newline
    push 10
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    add rsp, 8

exit_program:
    mov rax, 0
    pop rbp
    ret

; Helper function to convert input1 to number
convert_input1:
    mov al, [rel input1]
    sub al, 48
    mov bl, [rel input1 + 1]
    cmp bl, 10
    je single_digit_ret1

    ; Two digits
    mov cl, al
    add al, al                              ; *2
    add al, al                              ; *4
    add al, cl                              ; *5
    add al, al                              ; *10
    sub bl, 48
    add al, bl

single_digit_ret1:
    and rax, 0xFF
    ret

; Helper function to convert input2 to number
convert_input2:
    mov al, [rel input2]
    sub al, 48
    mov bl, [rel input2 + 1]
    cmp bl, 10
    je single_digit_ret2

    ; Two digits
    mov cl, al
    add al, al                              ; *2
    add al, al                              ; *4
    add al, cl                              ; *5
    add al, al                              ; *10
    sub bl, 48
    add al, bl

single_digit_ret2:
    and rax, 0xFF
    ret

; Convert integer input to float
convert_to_float:
    ; After convert_input1, r8 has integer
    cvtsi2ss xmm0, r8                       ; convert int to float
    movss [rel input1_float], xmm0

    ; After convert_input2, r9 has integer
    cvtsi2ss xmm0, r9                       ; convert int to float
    movss [rel input2_float], xmm0
    ret

; Float to string conversion
convert_float_result:
    ; Clear result buffer - PROPERLY
    lea rdi, [rel result_buffer]
    mov rcx, 10
clear_loop:
    mov byte [rdi], 0
    inc rdi
    loop clear_loop

    movss xmm0, [rel result_float]

    ; Check if negative
    xorps xmm1, xmm1                        ; xmm1 = 0.0
    ucomiss xmm0, xmm1                      ; compare result with 0
    jae not_negative_float

    ; Handle negative: negate and add minus sign
    mov byte [rel result_buffer], '-'
    mulss xmm0, [rel minus_one_float]       ; negate
    mov r11, 1                              ; start digits at position 1
    jmp extract_integer_part

not_negative_float:
    mov r11, 0                              ; start at position 0
    
extract_integer_part:
    ; Convert to integer to get whole number part
    cvttss2si rax, xmm0                      ; truncate float to int
    mov r12, rax                            ; save integer part

    ; Check magnitude and convert
check_float_magnitude:
    ; Check if result is >= 1000 (4 digits)
    lea rbx, [rel result_buffer]
    cmp rax, 1000
    jge convert_four_digit_part
    ; Check if result is >= 100 (3 digits)
    cmp rax, 100
    jge convert_three_digit_part
    cmp rax, 10
    jge convert_two_digit_part

    ; Single digit result
    add al, 48
    mov [rbx + r11], al
    inc r11
    jmp add_decimal_point

convert_two_digit_part:
    lea rcx, [rel result_buffer]            ; Load buffer address first
    mov rbx, 10
    xor rdx, rdx
    div rbx                                 ; rax = tens, rdx = ones
    add rax, 48
    mov [rcx + r11], al                     ; Use rcx for buffer
    add rdx, 48
    mov [rcx + r11 + 1], dl                 ; Use rcx for buffer
    add r11, 2
    jmp add_decimal_point

convert_three_digit_part:
    mov rbx, 100
    xor rdx, rdx
    div rbx                                 ; rax = hundreds, rdx = remainder
    add rax, 48
    lea rcx, [rel result_buffer]            ; Use RCX for buffer address
    mov [rcx + r11], al

    mov rax, rdx                            ; work with remainder
    mov rbx, 10
    xor rdx, rdx
    div rbx                                 ; rax = tens, rdx = ones
    add rax, 48
    mov [rcx + r11 + 1], al                 ; RCX still has buffer address
    add rdx, 48
    mov [rcx + r11 + 2], dl                 ; RCX still has buffer address
    add r11, 3
    jmp add_decimal_point

convert_four_digit_part:
    mov rbx, 1000
    xor rdx, rdx
    div rbx                                 ; rax = thousands, rdx = remainder
    add rax, 48
    lea rcx, [rel result_buffer]
    mov [rcx + r11], al                     ; store thousands digit
    
    mov rax, rdx                            ; work with remainder (0-999)
    mov rbx, 100
    xor rdx, rdx
    div rbx                                 ; rax = hundreds, rdx = remainder
    add rax, 48
    mov [rcx + r11 + 1], al                 ; store hundreds digit
    
    mov rax, rdx                            ; work with remainder (0-99)
    mov rbx, 10
    xor rdx, rdx
    div rbx                                 ; rax = tens, rdx = ones
    add rax, 48
    mov [rcx + r11 + 2], al                 ; store tens digit
    add rdx, 48
    mov [rcx + r11 + 3], dl                 ; store ones digit
    add r11, 4

add_decimal_point:
    ; Add decimal point
    lea rbx, [rel result_buffer]
    mov byte [rbx + r11], '.'
    inc r11

    ; For division, we might have actual decimal places
    mov al, [rel operation]
    cmp al, '/'
    je handle_division_decimals
    
    ; For +, -, * with integer inputs, just add .00
    mov byte [rbx + r11], '0'
    inc r11
    mov byte [rbx + r11], '0'
    inc r11
    mov byte [rbx + r11], 0                 ; null terminate
    jmp print_final_result

handle_division_decimals:
    ; Get fractional part for division
    movss xmm0, [rel result_float]          ; reload original float
    
    ; If original was negative, negate it to work with positive
    cmp byte [rel result_buffer], '-'
    jne skip_negate
    mulss xmm0, [rel minus_one_float]       ; negate to positive
skip_negate:
    
    cvtsi2ss xmm1, r12                      ; convert integer part to float
    subss xmm0, xmm1                        ; get fractional part
    
    ; First decimal place
    mulss xmm0, [rel ten_float]
    cvttss2si rax, xmm0                     ; truncate to get digit
    
    ; Clamp to 0-9
    and rax, 0xF                            ; keep only lower 4 bits
    cmp rax, 9
    jle first_digit_valid
    mov rax, 0                              ; default to 0 if invalid
first_digit_valid:
    mov rdx, rax                            ; save for subtraction
    add al, '0'
    mov [rbx + r11], al
    inc r11
    
    ; Subtract what we just extracted
    cvtsi2ss xmm1, rdx
    subss xmm0, xmm1

    ; Second decimal place  
    mulss xmm0, [rel ten_float]
    cvttss2si rax, xmm0
    
    ; Clamp to 0-9
    and rax, 0xF
    cmp rax, 9
    jle second_digit_valid
    mov rax, 0
second_digit_valid:
    add al, '0'
    mov [rbx + r11], al
    inc r11
    
    ; Null terminate
    mov byte [rbx + r11], 0
    jmp print_final_result