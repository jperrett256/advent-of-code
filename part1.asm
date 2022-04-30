    global _start

    section .text
_start:
    mov rax, 2 ; sys_open(input_file, O_RDONLY, 0)
    mov rdi, input_filename
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall

    mov r12, rax ; r12 = (FILE *) input_file

    ; read first line in
    mov rbx, read_buf ; rbx = (char *) read_buf
first_line_read_char:
    mov rax, 0 ; sys_read(input_file, rbx -> buffer, 1)
    mov rdi, r12
    mov rsi, rbx
    mov rdx, 1
    syscall

    cmp rax, 1 ; check we read a byte in
    je first_line_no_error

    mov rax, 1
    mov rdi, 1
    mov rsi, read_line_error_msg
    mov rdx, read_line_error_msg_len
    syscall

    mov rdi, 1
    jmp exit
first_line_no_error:
    ; move on if read a newline
    cmp byte [rbx], 0xa
    je first_line_done

    ; no need to ever convert from ascii

    ; go back and read next character
    inc rbx
    jmp first_line_read_char

first_line_done:

    sub rbx, read_buf ; rbx = number of digits

    ; DEBUG printing first line out
    mov rax, 1
    mov rdi, 1
    mov rsi, read_buf
    lea rdx, [rbx + 1] ; include additional newline we read in
    syscall

    ; TODO read later lines in
    ; idea was to compare one character at a time for later lines
    ; but that might be difficult to do since different lines have
    ; different numbers of digits

    mov rax, 3 ; sys_close(input_file)
    mov rdi, rbx

    mov rax, 1 ; sys_write(stdout, done_msg, done_msg_len)
    mov rdi, 1
    mov rsi, done_msg
    mov rdx, done_msg_len
    syscall

    xor rdi, rdi
exit:
    mov rax, 60 ; sys_exit(rdi)
    syscall


    section .bss
read_buf:
    resb 64


    section .data
done_msg:
    db "Completed execution.", 0xa
done_msg_len equ $ - done_msg

input_filename:
    db "input.txt", 0x0

O_RDONLY equ    0x0
O_WRONLY equ    0x1
O_RDWR   equ    0x2

read_line_error_msg:
    db "Could not read in first line.", 0xa
read_line_error_msg_len equ $ - read_line_error_msg

