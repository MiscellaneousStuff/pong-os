; ==============================================================================
; PREPROCESSOR DIRECTIVES
; ==============================================================================

ORG 0x7C00 ; originate offsets from segmente 0x7C00 (boot segment) 
BITS 16 ; 16-bit real mode code

; ==============================================================================
; CONSTANTS
; ==============================================================================

WIDTH  equ 320
HEIGHT equ 200
BPP    equ 8

WHITE  equ 0x0F
BLACK  equ 0x00

; ==============================================================================
; MAIN CODE
; ==============================================================================

main_init:
    ; safely setup segment and stack registers
    cli
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, main_init
    sti

    ; switch to mode 13h graphics (300x200x8)
    mov ax, 0x13
    int 0x10

    ; plot a rect
    mov ch, 10
    mov cl, 10
    mov dh, 100
    mov dl, 100
    call rect

main_done:
    ; disable interrupts and loop (safely stops operation of a PC)
    cli
    hlt
    jmp main_done ; Shouldn't be needed, but you never know

; ==============================================================================
; UTILITY FUNCTIONS
; ==============================================================================

; ------------------------------------------------------------------------------
; NOTE: 0xA000 is memory segment for graphics segment
; Plots a filled rectangle to the screen
; IN = CH(X) + CL(Y) + DH(WIDTH) + DL(HEIGHT) | OUT = Nothing
rect:
    pusha

    mov ax, 0xA000
    mov es, ax
    xor bx, bx
    mov al, WHITE
    stosb

.done:
    popa
    ret

; ==============================================================================
; BOOTSECTOR PADDING AND BOOT DEVICE SIGNATURE (WON'T BOOT OTHERWISE!)
; ==============================================================================

times 510 - ($ - $$) db 0x00 ; pad bootsector to 510 bytes
boot_signature dw 0xAA55     ; 0xAA55 tells the bios this device is bootable

; ==============================================================================
; EOF
; ==============================================================================