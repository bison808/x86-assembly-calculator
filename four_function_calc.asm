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
    format_buffer resb 20           ; buffer for float->string conversion

section .bss
    input1 resb 4
    operation resb 2
    input2 resb 4
    result_buffer resb 10            ; space for -9999 + null
    
    ; Float storage
    input1_float resd 1             ; 32-bit float for first number
    input2_float resd 1             ; 32-bit float for second number
    result_float resd 1              ; 32-bit float for result

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
; NEW: Convert both integers to floats  
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
    movss [rel result_float], xmm0       ; store result
    jmp convert_float_result
do_subtraction_float:
do_multiplication_float:
do_division_float:
    ; Temporary - not implemented yet
    jmp exit_program
do_subtraction:
    sub r8, r9                          ; r8 = first - second
    mov r10, 0                          ; r10 = assume positive
    cmp r8, 0
    jge convert_result
    ; Handle negative result
    neg r8                              ; make positive
    mov r10, 1                          ; r10 = 1 means negative
    jmp convert_result

do_multiplication:
    mov rax, r8
    mul r9                              ; rax = r8 * r9
    mov r8, rax
    mov r10, 0                          ; multiplication of positives is positive
    jmp convert_result

do_division:
    ; check for division by zero
    cmp r9, 0
    je division_error

    mov rax, r8                         
    xor rdx, rdx                        ; clear rdx for division
    div r9                              ; rax = quotient, rdx = remainder
    mov r8, rax                         ; store quotient
    mov r10, 0                          ; division result is positive
    ; Note: We're ignoring remainder for now
    jmp convert_result

division_error:
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, 25
    syscall
    jmp exit_program

convert_result:
; Clear result buffer first
    mov byte [rel result_buffer], 0
    mov byte [rel result_buffer + 1], 0
    mov byte [rel result_buffer + 2], 0
    mov byte [rel result_buffer + 3], 0
    mov byte [rel result_buffer + 4], 0
    ; r8 contains the absolute value of result
    ; r10 contains sign (0=positive, 1=negative)

    ; Handle sign
    mov r11, 0                          ; offset in result_buffer
    cmp r10, 1
    jne check_magnitude
    ; Add minus sign
    mov byte [rel result_buffer], '-'
    mov r11, 1                          ; start digits at offset 1

check_magnitude:
    ; Check if result is >= 1000 (4 digits)
    cmp r8, 1000
    jge four_digit_result
    ; Check if result is >= 100 (3 digits)
    cmp r8, 100
    jge three_digit_result
    cmp r8, 10
    jge two_digit_result

    ; Single digit result
    add r8, 48
    lea rax, [rel result_buffer]
    mov [rax + r11], r8b
    inc r11
    jmp print_final_result

two_digit_result:
    mov rax, r8
    mov rbx, 10
    xor rdx, rdx
    div rbx                                 ; rax = tens, rdx = ones
    add rax, 48
    lea rbx, [rel result_buffer]
    mov [rbx + r11], al
    add rdx, 48
    mov [rbx + r11 + 1], dl
    add r11, 2
    jmp print_final_result

three_digit_result:
    mov rax, r8
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
    jmp print_final_result

four_digit_result:
    mov rax, r8
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
    jmp print_final_result

print_final_result:
    ; Print result message
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, 8
    syscall

    ; Print result
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, result_buffer
    mov rdx, r11                            ; number of characters to print
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
; Step 3: Convert integer input to float
convert_to_float:
    ; After convert_input1, r8 has integer
    cvtsi2ss xmm0, r8                       ; convert int to float
    movss [rel input1_float], xmm0

    ; After convert_input2, r9 has integer
    cvtsi2ss xmm0, r9                       ; convert int to float
    movss [rel input2_float], xmm0
    ret
; Step 4: Basic float to string conversion
; This is simplified - shows integer part and 2 decimal places

convert_float_result:
    ; Clear result buffer
    mov rcx, 10
    lea rdi, [rel result_buffer]
    xor al, al
    rep stosb

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

    ; Convert integer part to string (reuse your existing logic)
    ; Check magnitude and convert (adapt your existing code)
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
    lea rcx, [rel result_buffer]  ; Load buffer address first
    mov rbx, 10
    xor rdx, rdx
    div rbx                       ; rax = tens, rdx = ones
    add rax, 48
    mov [rcx + r11], al           ; Use rcx for buffer
    add rdx, 48
    mov [rcx + r11 + 1], dl       ; Use rcx for buffer
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
    jmp add_decimal_point

add_decimal_point:
    ; Continue with decimal point and fractional part
    ; Add decimal point
    lea rbx, [rel result_buffer]
    mov byte [rbx + r11], '.'
    inc r11

    ; Get fractional part
    movss xmm0, [rel result_float]          ; RELOAD the original float!
    cvtsi2ss xmm1, r12                      ; convert integer part back to float
    subss xmm0, xmm1                        ; xmm0 now has fractional part

    ; First decimal place
    lea rbx, [rel result_buffer]
    mulss xmm0, [rel ten_float]
    cvttss2si rax, xmm0
    mov rdx, rax
    add al, '0'
    mov [rbx + r11], al
    inc r11
    cvtsi2ss xmm1, rdx
    subss xmm0, xmm1

    ; Second decimal place  
    mulss xmm0, [rel ten_float]
    cvttss2si rax, xmm0
    add al, '0'
    mov [rbx + r11], al
    inc r11
    
    mov byte [rbx + r11], 0
    print_final_result:
    ; DEBUG: Print r11 value
    push r11
    mov rax, r11
    add rax, '0'
    push rax
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rax
    pop r11
    jmp print_final_result