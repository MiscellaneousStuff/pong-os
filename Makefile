AS = nasm
ASFLAGS = -O0 -w+orphan-labels -f bin 

all: pong.img

run: pong.img
	qemu-system-i386.exe -drive format=raw,file=pong.img

pong.img: pong.asm
	$(AS) $(ASFLAGS) -o pong.img pong.asm

# NOTE: This does include null bytes used by code/data as well
# roughly calculates remaining bytes (out of 510)
space: pong.img
	xxd -b pong.img | grep -o "00000000" | wc -l

clean:
	rm *.o pong.img

.PHONY: clean pong.img run all space