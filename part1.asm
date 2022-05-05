    global _start

; CODE
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
first_line__read_char:
    mov rax, 0 ; sys_read(input_file, rbx -> buffer, 1)
    mov rdi, r12
    mov rsi, rbx
    mov rdx, 1
    syscall

    cmp rax, 1 ; check we read a byte in
    je first_line__no_error

    mov rax, 1
    mov rdi, 1
    mov rsi, read_line_error_msg
    mov rdx, read_line_error_msg_len
    syscall

    mov rdi, 1
    jmp exit
first_line__no_error:
    ; move on if read a newline
    cmp byte [rbx], 0xa
    je first_line__done

    ; no need to ever convert from ascii

    ; go back and read next character
    inc rbx
    jmp first_line__read_char

first_line__done:

    sub rbx, read_buf ; rbx = number of digits
    mov [prev_line_length], bx ; save to compare later

    ; DEBUG printing first line out
    mov rax, 1
    mov rdi, 1
    mov rsi, read_buf
    lea rdx, [rbx + 1] ; include additional newline we read in
    syscall

next_line:
    ; read next line in byte at a time
    ; start off assuming same number of digits
    ; assume current line will be larger than previous line
    mov rbx, read_buf ; rbx = (char *) read_buf
    mov r14, 0 ; current_larger = false
determine_larger__read_byte:
    mov r13, [rbx] ; r13 = previous line char

    ; read in a byte
    mov rax, 0
    mov rdi, r12
    mov rsi, rbx
    mov rdx, 1
    syscall

    ; check we successfully read a byte
    cmp rax, 1
    je determine_larger__success

    ; check is first byte of line
    cmp rbx, read_buf
    mov rdi, 1 ; exit code
    jne exit ; exit(1)
    ; check we read no bytes (no error code)
    cmp rax, 0
    jne exit ; exit(1)

    jmp all_lines_read ; finished, jump to end

determine_larger__success:

    ; reached end of word, implies the words are identical (current_larger = false)
    cmp byte [rbx], 0xa
    je determine_larger__done

    inc rbx ; update pointer to buffer

    ; compare byte read to corresponding byte in last line (again assuming they are of equal length)
    cmp [rbx - 1], r13
    jg determine_larger__larger ; set current_larger = true
    jl determine_larger__done   ; current_larger should be left false

    ; inconclusive, wrap around
    jmp determine_larger__read_byte

determine_larger__larger:
    mov r14, 1 ; if greater, set current_larger = true
determine_larger__done:

    ; read in remaining bytes (until newline)
read_rest__read_byte:
    ; read in a byte
    mov rax, 0
    mov rdi, r12
    mov rsi, rbx
    mov rdx, 1
    syscall

    cmp rax, 1 ; check byte read
    mov rdi, 1 ; exit code
    jne exit ; exit(1) if no byte read

    cmp byte [rbx], 0xa
    je read_rest__done

    inc rbx
    jmp read_rest__read_byte

read_rest__done:

    sub rbx, read_buf ; rbx = new line length

    ; previously assumed current line and previous line were same length, this is where we check
    ; if length is different to previously saved value, update current_larger correspondingly
    cmp rbx, [prev_line_length]
    jg check_length__larger ; if current line is longer, the value is larger
    jl check_length__smaller ; if current line is shorter, the value is smaller
    jmp check_length__done

check_length__larger:
    mov r14, 1 ; set current_larger = true
    jmp check_length__done

check_length__smaller:
    mov r14, 0 ; set current_larger = false

check_length__done:

    ; increment increased_count based on current_larger
    add [increased_count], r14w

    jmp next_line ; try reading next line

all_lines_read:

    movzx rbx, word [increased_count]
    ; TODO
    ; output increased_count

    mov rax, 3 ; sys_close(input_file)
    mov rdi, r12

    mov rax, 1 ; sys_write(stdout, done_msg, done_msg_len)
    mov rdi, 1
    mov rsi, done_msg
    mov rdx, done_msg_len
    syscall

    xor rdi, rdi
exit:
    mov rax, 60 ; sys_exit(rdi)
    syscall


; UNINITIALISED DATA
    section .bss
read_buf:
    resb 32
prev_line_length:
    resw 1


; INITIALISED DATA
    section .data
increased_count:
    dw 0x0

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

