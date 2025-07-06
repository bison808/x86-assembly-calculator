section .text
	global _main

_main:
	push rbp
	mov rbp, rsp

	mov rbx, 2		    ; start counter at 2

loop_start:
	cmp rbx, 21
	jge print_end

	cmp rbx, 10
	jge print_two_digit

	;Print single digit (2, 4, 6, 8)
	mov rax, rbx		; copy counter to rax
	add rax, 48		    ; convert to ASCII
	push rax
	mov rax, 0x2000004	; sys_write
	mov rdi, 1		    ; stdout
	mov rsi, rsp		; pointer to character
	mov rdx, 1		    ; one character
	syscall
    pop rax

	jmp print_space

print_two_digit:
    mov rax, rbx        ; copy number to rax
    mov rcx, 10         ; divisor
    xor rdx, rdx
    div rcx             ; rax = tens digit, rdx = ones digit

    ; Save BOTH digits immediately
    mov r8, rax         ; save tens digit in r8
    mov r9, rdx         ; save ones digit in r9
    
    ; Print tens digit
    mov rax, r8         ; get tens digit
    add rax, 48
    push rax
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rax

    ; Print ones digit
    mov rax, r9         ; get ones digit from r9 (not r8!)
    add rax, 48
    push rax
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rax

    jmp print_space

print_space:
	push 32
	mov rax, 0x2000004	
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
    pop rax

	; Increment counter and check if done
    add rbx, 2
	jmp loop_start	    ; jump back to loop_start

print_end:
	; Print newline at the end
	push 10
	mov rax, 0x2000004
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
    pop rax

	mov rax, 0
	pop rbp
	ret