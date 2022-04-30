    global _start

    section .text
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, message
    mov rdx, message_len
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall

    section .data
message:
    db "Hello, world", 0x21, 0xa
message_len equ $ - message

