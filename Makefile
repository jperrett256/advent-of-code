ASM_FILE = part1.asm
OBJ_FILE = $(patsubst %.asm, %.o, $(ASM_FILE))

all: elf64

elf64:
	nasm -felf64 $(ASM_FILE)
	ld $(OBJ_FILE) -o output
	rm $(OBJ_FILE)

