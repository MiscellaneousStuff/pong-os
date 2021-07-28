ORG 0x7C00
BITS 16

start:
    cli
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, start
    sti

    mov si, txt
    call prt_str

done:
    cli
    hlt
    jmp done ; Shouldn't be needed, but you never know


prt_str:
    pusha
    mov ah, 0x0E

.more:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .more

.done:
    popa
    ret


txt db "Hello, World!", 13, 10, 0

times 510 - ($ - $$) db 0x00
boot_signature dw 0xAA55