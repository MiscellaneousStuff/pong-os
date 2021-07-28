AS = nasm
ASFLAGS = -O0 -w+orphan-labels -f bin 

all: pong.img

run: pong.img
	qemu-system-i386.exe -drive format=raw,file=pong.img

pong.img: pong.asm
	$(AS) $(ASFLAGS) -o pong.img pong.asm

clean:
	rm *.o pong.img

.PHONY: clean pong.img