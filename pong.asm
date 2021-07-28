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

; Mode 13h screen settings (320x200x8bpp)
SCREEN_WIDTH      equ 320
SCREEN_HEIGHT     equ 200
MID_SCREEN_X      equ SCREEN_WIDTH / 2
MID_SCREEN_y      equ SCREEN_HEIGHT / 2

; Colors   
BLACK      equ 0x00
GREEN      equ 0x02
CYAN       equ 0x03
LIGHT_GRAY equ 0x07
DARK_GRAY  equ 0x08
YELLOW     equ 0x0E
WHITE      equ 0x0F

; Theme
PRIMARY    equ WHITE ; paddle, ball, fonts
BACKGROUND equ BLACK 

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

    ; render background
    mov al, BACKGROUND
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    repe stosb


main_loop:
    ; Handle user input first
    ; call main_input

    ; Render afterwards
    call main_render

    ; Infinite loop
    jmp main_loop

; ------------------------------------------------------------------------------
; Handle user input
; IN = Nothing | OUT = Nothing
main_input:
    xor ax, ax
    int 0x16
    ret

; ------------------------------------------------------------------------------
; Render game objects and UI
; IN = Nothing | OUT = Nothing
main_render:
    ; Plot player 1 paddle
    mov ax, 4                   ; x
    mov bx, [player_1_y]        ; y
    mov cx, 4                   ; width (originally 100)
    mov dx, 100                 ; height (originally 100)
    call rect                   ; rect(x, y, width, height)

    ; Plot player 2 paddle
    mov ax, SCREEN_WIDTH - 8    ; x
    mov bx, [player_2_y]        ; y
    mov cx, 4                   ; width (originally 100)
    mov dx, 100                 ; height (originally 100)
    call rect                   ; rect(x, y, width, height)

    ; Plot mid line
    call main_render_line

    ; Plot scores
    mov ax, MID_SCREEN_X - \
    (2 + 6*4)                ; x
    mov bx, 4     ; y
    mov cx, [player_1_score] ; player 2 score
    call main_render_score   ; render_score(x, y, score)

    mov ax, MID_SCREEN_X + \
    (2 + 2*4)                ; x
    mov bx, 4     ; y
    mov cx, [player_2_score] ; player 2 score
    call main_render_score   ; render_score(x, y, score)

    ; Plot ball
    mov ax, [ball_x]
    mov bx, [ball_y]
    mov cx, 4
    mov dx, 4
    call rect

.done:
    ret

; ------------------------------------------------------------------------------
; Render a players score
; IN = AX(X) + BX(Y) + CX(Score) | OUT = Nothing
main_render_score:
    pusha

    mov cx, 4
    mov dx, 4
    call rect

    add ax, 4*3
    call rect

    add bx, 7*3
    call rect

    sub ax, 4*3
    call rect
    
.done:
    popa
    ret

; ------------------------------------------------------------------------------
; Render middle split
; IN = Nothing | OUT = Nothing
main_render_line:
    pusha
    mov di, 24 ; 200 height / 4 dot height = 25 dots - 1 offset = 24 dots

    mov ax, MID_SCREEN_X - 2 ; x
    mov bx, 4                ; y
    mov cx, 4                ; width (originally 100)
    mov dx, 4                ; height (originally 100)

.dot:
    call rect

    add bx, 8
    dec di
    jz .done
    jmp .dot

.done:
    popa
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
; IN = AX(X) + BX(Y) + CX(WIDTH) + DX(HEIGHT) | OUT = Nothing
; SI = PER ROW OFFSET, DI = CUR ROW OFFSET
rect:
    pusha

    ; calc per row offset
    mov si, SCREEN_WIDTH
    sub si, cx

    ; calculate start offset (y * SCREEN_WIDTH + x)
    push dx
    push ax
    xor ax, ax
    mov ax, SCREEN_WIDTH
    mul bx
    pop bx
    add ax, bx
    mov di, ax
    pop dx

    ; save width into bx
    mov bx, cx

.row:
    ; restore width each time
    mov cx, bx

    ; plot row
    mov al, PRIMARY
    repe stosb

    ; we're done if we've plotted all rows
    add di, si ; DI += row_offset
    dec dx
    jz .done
    jmp .row

.done:
    popa
    ret

; ==============================================================================
; GAME VARIABLES AND DATA
; ==============================================================================

; ------------------------------------------------------------------------------
; NUMBER DATA
; ------------------------------------------------------------------------------

digit_0_1:
db 11110001b
db 10010001b
db 10010001b
db 10010001b
db 10010001b
db 10010001b
db 10010001b
db 11110001b

digit_2_3:
db 11111111b
db 00010001b
db 00010001b
db 11111111b
db 10000001b
db 10000001b
db 10000001b
db 11111111b

digit_4_5:
db 10011111b
db 10011000b
db 10011000b
db 11111111b
db 00010001b
db 00010001b
db 00010001b
db 00011111b

digit_6_7:
db 10001111b
db 10000001b
db 10000001b
db 10000001b
db 11110001b
db 10010001b
db 10010001b
db 11110001b

digit_8_9:
db 11111111b
db 10011001b
db 10011001b
db 11111111b
db 10010001b
db 10010001b
db 10010001b
db 11110001b

; ------------------------------------------------------------------------------
; PLAYER 1 VARIABLES
; ------------------------------------------------------------------------------

player_1_y     db 5
player_1_score db 0

; ------------------------------------------------------------------------------
; PLAYER 2 VARIABLES
; ------------------------------------------------------------------------------

player_2_y     db 5
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