section .text
	global _main

_main:
	push rbp
	mov rbp, rsp

	mov rbx, 1		; start counter at 1

loop_start:
	cmp rbx, 11
	jge print_end

	cmp rbx, 10
	je print_ten

	;First, print the current number (in rbx)
	; Convert Single digit to ASCII
	mov rax, rbx		; copy counter to rax
	add rax, 48		; convert to ASCII

	; Print the digit
	push rax
	mov rax, 0x2000004	; sys_write
	mov rdi, 1		; stdout
	mov rsi, rsp		; pointer to character
	mov rdx, 1		; one character
	syscall
	pop rax			; clean stack
	jmp print_space

print_ten:
	; Print "1" for tens digit	
	push 49
	mov rax, 0x2000004
	mov rdi, 1
	mov rsi, rsp	
	mov rdx, 1
	syscall	
	add rsp, 8

	; Print "0" for ones digit
	push 48
	mov rax, 0x2000004
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
	add rsp, 8

print_space:
	; Print a space after each number
	push 32			; ASCII space character
	mov rax, 0x2000004	
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
	add rsp, 8

	; Increment counter and check if done
	inc rbx			; increment counter
	cmp rbx, 10		; compare with 11 (we want to stop after 10)
	jle loop_start		; if rbx <= 10, jump back to loop_start

print_end:
	; Print newline at the end
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