; ==============================================================================
; LICENSE AND SUMMARY
; ==============================================================================
;
; The MIT License (MIT)
; 
; Copyright (c) 2021 MiscellaneousStuff
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
; THE SOFTWARE.
;
; ------------------------------------------------------------------------------
; Pong implemented in 512-byte bootsector, 16-bit, real-mode
; ==============================================================================


; ==============================================================================
; PREPROCESSOR DIRECTIVES
; ==============================================================================

ORG 0x7C00 ; originate offsets from segmente 0x7C00 (boot segment)
BITS 16 ; 16-bit real mode code

; ==============================================================================
; CONSTANTS
; ==============================================================================

WIDTH   equ 320
HEIGHT  equ 200
BPP     equ 8

WHITE   equ 0x0F
BLACK   equ 0x00

PRIMARY equ WHITE

; ==============================================================================
; MAIN CODE
; ==============================================================================

main_init:
    ; safely setup segment and stack registers
    cli
    mov ax, 0xA000
    mov es, ax
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, main_init
    sti

    ; switch to mode 13h graphics (300x200x8)
    mov ax, 0x13
    int 0x10

    ; plot a rect
    mov bh, 10  ; x
    mov bl, 10  ; y
    mov dh, 1 ; width (originally 100)
    mov dl, 1 ; height (originally 100)
    call rect   ; rect(x, y, width, height)

main_done:
    ; disable interrupts and loop (safely stops operation of the CPU)
    cli
    hlt
    jmp $ ; Shouldn't be needed, but you never know

; ==============================================================================
; UTILITY FUNCTIONS
; ==============================================================================

; ------------------------------------------------------------------------------
; NOTE: 0xA000 is memory segment for graphics segment
; Plots a filled rectangle to the screen
; IN = BH(X) + BL(Y) + DH(WIDTH) + DL(HEIGHT) | OUT = Nothing
rect:
    pusha

    ; calc per row width offset
    mov al, dl ; save HEIGHT in AH
    xor dl, dl ; clear DL so (SI - DX) := (WIDTH - rect_width) only
    xchg dl, dh ; so DX = (0x00 << 8) + WIDTH
    mov si, WIDTH
    sub si, dx ; SI = (WIDTH - rect_width)
    mov dl, al ; restore HEIGHT from AH ; NOTE: 

    ; calculate start offset (y * width + x)
    xor ax, ax
    mov al, dh ; AX := width
    xor cx, cx
    mov cl, bl
    mul cx ; AX = width * y
    mov cl, bh
    add ax, bx ; AX = (width * y) + x
    mov di, ax

    ; putpixel(row_1)
    mov al, PRIMARY
    stosb

    ; putpixel(row_2)
    add di, si
    stosb

;.row:
;   ; plot WIDTH number of pixels in a row
;   xor cx, cx
;   mov cl, dh ; CX := width
;   mov al, PRIMARY ; color
;   repe stosb      ; es(0xA000):di(y*width+x) := color
;   dec dl
;   or dl, dl
;   jz .done
;   jmp .row

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