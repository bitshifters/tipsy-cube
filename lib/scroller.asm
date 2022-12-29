; ============================================================================
; Scroller.
; ============================================================================

.equ Scroller_MaxGlyphs, 96
.equ Scroller_Y_Pos, 216

; Assume glyphs are 8x8 pixels = 1 word per row in MODE 9 = 32 bytes per glyph.

; R0=glyph number.
; R11=screen addr ptr.
; Trashes: R0-R10.
.if 0
plot_gylph:
    mov r10, r11
    adr r9, font_data
    add r9, r9, r0, lsl #5              ; assumes 32 bytes per glyph.

    ldmia r9!, {r0-r3}                  ; 4 words for now.
    ldr r4, [r10]
    bic r4, r4, r0
    orr r4, r4, r0
    str r4, [r10], #Screen_Stride

    ldr r4, [r10]
    bic r4, r4, r1
    orr r4, r4, r1
    str r4, [r10], #Screen_Stride

    ldr r4, [r10]
    bic r4, r4, r2
    orr r4, r4, r2
    str r4, [r10], #Screen_Stride

    ldr r4, [r10]
    bic r4, r4, r3
    orr r4, r4, r3
    str r4, [r10], #Screen_Stride

    ldmia r9!, {r0-r3}                  ; 4 words for now.
    ldr r4, [r10]
    bic r4, r4, r0
    orr r4, r4, r0
    str r4, [r10], #Screen_Stride

    ldr r4, [r10]
    bic r4, r4, r1
    orr r4, r4, r1
    str r4, [r10], #Screen_Stride

    ldr r4, [r10]
    bic r4, r4, r2
    orr r4, r4, r2
    str r4, [r10], #Screen_Stride

    ldr r4, [r10]
    bic r4, r4, r3
    orr r4, r4, r3
    str r4, [r10], #Screen_Stride

    add r11, r11, #4                ; next word
    mov pc, lr
.endif

update_scroller:
    str lr, [sp, #-4]!

    .if _ENABLE_ROCKET && 0
    mov r0, #8
    bl rocket_sync_get_val
    mov r1, r1, lsr #16
    str r1, scroller_y_pos
    .endif

    ldr r0, scroller_column
    ldr r1, scroller_speed
    add r0, r0, r1
    cmp r0, #8
    blt .1

    sub r0, r0, #8
    ldr r12, scroller_text_ptr
    add r12, r12, #1
    ldrb r1, [r12]
    cmp r1, #0
    adreq r12, scroller_message
    str r12, scroller_text_ptr

.1:
    str r0, scroller_column
    ldr pc, [sp], #4


; R11=screen addr ptr.
draw_scroller:
    str lr, [sp, #-4]!

    ldr r0, scroller_y_pos
    add r11, r11, r0, lsl #7
    add r11, r11, r0, lsl #5        ; assume stride is 160.

    ldr r12, scroller_text_ptr
    ldr r8, scroller_column
    mov r8, r8, lsl #2              ; shift for second word.
    rsb r7, r8, #32                 ; shift for first word.
    mov r10, #0                     ; screen column

    ; Character loop.
    .1:
    ldrb r0, [r12], #1
    cmp r0, #0
    adreq r12, scroller_message
    beq .1

    sub r0, r0, #32                 ; ascii space
    adr r9, font_data
    add r9, r9, r0, lsl #5          ; assumes 32 bytes per glyph.

    ; Row loop.
    mov r6, #8

    .2:
    ldr r0, [r9], #4

    mov r1, r0, lsr r8              ; second glyph word shifted.
    mov r0, r0, lsl r7              ; first glyph word shifted.

    cmp r0, #0                      ; if first glyph is empty?
    beq .3                          ; skip.

    ; display first glyph word in prev screen word.
    cmp r10, #0
    beq .3                          ; skip if left hand edge of screen.

    ldr r2, [r11, #-4]              ; load prev screen word.
    bic r2, r2, r0
    orr r2, r2, r0                  ; mask in first glyph word.
    str r2, [r11, #-4]              ; store prev screen word.

    ; drop shadow?
    ldr r2, [r11, #Screen_Stride-4] ; load prev screen word.
    bic r2, r2, r0
    str r2, [r11, #Screen_Stride-4] ; store prev screen word.

    ; display second glyph word in current screen word.
    .3:
    cmp r10, #40
    bge .4                          ; skip if right hand edge of screen.

    ldr r2, [r11]                   ; load current screen word.
    bic r2, r2, r1
    orr r2, r2, r1                  ; mask in second glyph word.
    str r2, [r11]                   ; store prev screen word.

    ; drop shadow?
    ldr r2, [r11, #Screen_Stride]   ; load prev screen word.
    bic r2, r2, r1
    str r2, [r11, #Screen_Stride]   ; store prev screen word.

    .4:
    add r11, r11, #Screen_Stride
    subs r6, r6, #1
    bne .2                          ; next row.
    
    subs r11, r11, #8*Screen_Stride
    add r11, r11, #4                ; next screen word.

    add r10, r10, #1                ; next screen column.
    cmp r10, #41                    ; one extra column for scroll!
    bne .1

    ldr pc, [sp], #4

; font word = 0xabcdefgh
; scroll by 1 pixel = 0x0abcdefg - shift right by 4 for second word.
; scroll by 1 pixel = 0xi0000000 - shift left by 28 for first word.


scroller_text_ptr:
    .long scroller_message

scroller_speed:
    .long 1

scroller_column:
    .long 0

scroller_y_pos:
    .long Scroller_Y_Pos

scroller_message:
; At 1 pixel/frame = 6.4s to traverse the screen.
; Speed = 40 chars/6.4s = 6.25 chars/s
; 16 patterns at 6 ticks/row = 122.88s
; So in 122.88s 122.88s * 6.25 chars/s = 768 chars.
;                                                                                                              
;                    1         2         3         4         5         6         7         8         9         
;          0.........0.........0.........0.........0.........0.........0.........0.........0.........0.........
    .byte "                                                    Is it a terrible twister?  No... this is the first ever rubb"    ; 100
    .byte "er cube intro for the Acorn Archimedes!  Brought to you by Bitshifters & Slipstream for the Silveste"    ; 200
    .byte "r NYE 2022 demoparty.  Inspired by the Gerp 2014 rubber vector challenge, just rocking up 8 years la"
    .byte "te in true Archie fashion.  Credits..  code by kieran -- music by ToBach -- QTM/RasterMan by Phoenix"
    .byte "^Quantum -- special thanks to Progen.  Tipsy NYE greets go out to...  Ate-Bit -- CRTC -- DESiRE -- H"
    .byte "ooy Program -- Inverse Phase -- Logicoma -- Loonies -- Proxima -- Rabenauge -- Rift -- Torment -- YM"
    .byte " Rockerz.  Sending love to Lemon. and Spaceballs for the Amiga inspiration.  Wishing everyone a Happ"
    .byte "y New Year for 2023.  Hope to see you at NOVA in June :)"
    .byte 0
    .align 4


font_data:
    .incbin "data/font.bin"
