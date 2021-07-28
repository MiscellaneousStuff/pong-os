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

; ------------------------------------------------------------------------------
; Initialize graphics
; IN = Nothing | OUT = Nothing
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
    mov bh, 20 ; x
    mov bl, 5 ; y
    mov dh, 5  ; width (originally 100)
    mov dl, 100  ; height (originally 100)
    call rect  ; rect(x, y, width, height)

main_loop:
    ; Handle user input first
    call main_input

    ; Render afterwards
    call main_render
    jmp main_loop

; ------------------------------------------------------------------------------
; Handle user input
; IN = Nothing | OUT = Nothing
main_input:
    xor ax, ax
    int 0x16

; ------------------------------------------------------------------------------
; Render game objects and UI
; IN = Nothing | OUT = Nothing
main_render:
    ret

; ------------------------------------------------------------------------------
; Game termination
; IN = Nothing | OUT = Nothing
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
    mov al, dl ; save HEIGHT in AL
    mov ah, dh ; save WIDTH in AH

    xor dl, dl ; clear DL so (SI - DX) := (WIDTH - rect_width) only
    xchg dl, dh ; so DX = (0x00 << 8) + WIDTH
    mov si, WIDTH
    sub si, dx ; SI = (WIDTH - rect_width)
    
    mov dh, ah ; restore WIDTH from DL
    mov dl, al ; restore HEIGHT from AL

    ; calculate start offset (y * WIDTH + x)
    push dx
    push bx

    ; AL := WIDTH
    xor ax, ax
    mov ax, WIDTH

    ; CL := y
    xor cx, cx
    mov cl, bl

    ; AL = AL(WIDTH) * CL(y)
    mul cx

    ; BL := x
    mov bl, bh
    xor bh, bh

    ; AL = AL(WIDTH * y) + BL(x)
    add ax, bx ; AX = (width * y) + x

    ; DI = (WIDTH * y) + x
    mov di, ax

    pop bx
    pop dx

.row:
    xor cx, cx
    mov cl, dh ; CX = width

    mov al, PRIMARY
    repe stosb

    ; we're done if we've plotted all rows
    add di, si ; DI += row_offset
    dec dl
    jz .done
    jmp .row

.done:
    popa
    ret

; ==============================================================================
; GAME VARIABLES
; ==============================================================================

; ------------------------------------------------------------------------------
; PLAYER 1 VARIABLES
; ------------------------------------------------------------------------------

player_1_y     db 0
player_1_score db 0

; ------------------------------------------------------------------------------
; PLAYER 2 VARIABLES
; ------------------------------------------------------------------------------

player_2_y     db 0
player_2_score db 0

; ------------------------------------------------------------------------------
; BALL VARIABLES
; ------------------------------------------------------------------------------

ball_x db 0
ball_y db 0
ball_velocity_x db 0
ball_velocity_y db 0

; ------------------------------------------------------------------------------
; GAME STATE VARIABLES
; ------------------------------------------------------------------------------

game_state db 0 ; 0 = Start screen, 1 = Ready (Press key to start), 2 = Playing

; ==============================================================================
; BOOTSECTOR PADDING AND BOOT DEVICE SIGNATURE (WON'T BOOT OTHERWISE!)
; ==============================================================================

times 510 - ($ - $$) db 0x00 ; pad bootsector to 510 bytes
boot_signature dw 0xAA55     ; 0xAA55 tells the bios this device is bootable

; ==============================================================================
; EOF
; ==============================================================================