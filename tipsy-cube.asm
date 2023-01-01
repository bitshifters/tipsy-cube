; ============================================================================
; Prototype Framework - stripped back from stniccc-archie.
; ============================================================================

.equ _DEBUG, 0
.equ _ENABLE_RASTERMAN, 1
.equ _ENABLE_MUSIC, 1
.equ _ENABLE_ROCKET, 1
.equ _SYNC_EDITOR, (_ENABLE_ROCKET && 0)
.equ _FIX_FRAME_RATE, 1					; useful for !DDT breakpoints

.equ _DEBUG_RASTERS, (_DEBUG && !_ENABLE_RASTERMAN && 1)

.equ _RUBBER_CUBE, 1
.equ _DRAW_LOGO, 0
.equ _LEMON_LOGOS, 1

.equ Screen_Banks, 3
.equ Screen_Mode, 9
.equ Screen_Width, 320
.equ Screen_Height, 256
.equ Mode_Height, 256
.equ Screen_PixelsPerByte, 2
.equ Screen_Stride, Screen_Width/Screen_PixelsPerByte
.equ Screen_Bytes, Screen_Stride*Screen_Height
.equ Mode_Bytes, Screen_Stride*Mode_Height

.equ Logo_Y_Pos, 16

.include "lib/swis.h.asm"
.include "lib/config.h.asm"

.macro SET_BORDER rgb
	.if _DEBUG_RASTERS
	mov r4, #\rgb
	bl palette_set_border
	.endif
.endm

.org 0x8000

; ============================================================================
; Stack
; ============================================================================

Start:
    ldr sp, stack_p
	B main

stack_p:
	.long stack_base

; ============================================================================
; Main
; ============================================================================

main:
	SWI OS_WriteI + 22		; Set base MODE
	SWI OS_WriteI + Screen_Mode

	SWI OS_WriteI + 23		; Disable cursor
	SWI OS_WriteI + 1
	MOV r0,#0
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC

	; Set screen size for number of buffers
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	MOV r0, #DynArea_Screen
	MOV r2, #Mode_Bytes * Screen_Banks
	SUBS r1, r2, r1
	SWI OS_ChangeDynamicArea
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	CMP r1, #Mode_Bytes * Screen_Banks
	ADRCC r0, error_noscreenmem
	SWICC OS_GenerateError

	; LOAD STUFF HERE!

.if _ENABLE_MUSIC
	; QTM Init.
	; Required to make QTM play nicely with RasterMan.
	mov r0, #4
	mov r1, #-1
	mov r2, #-1
	swi QTM_SoundControl

	; Load module
	mov r0, #0
	adr r1, music_data
	swi QTM_Load
.endif

	; Clear all screen buffers
	mov r1, #1
.1:
	str r1, scr_bank

	; CLS bank N
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte
	mov r0, #12
	SWI OS_WriteC

	ldr r1, scr_bank
	add r1, r1, #1
	cmp r1, #Screen_Banks
	ble .1

	; EARLY INITIALISATION HERE! (Tables etc.)
	.if _ENABLE_RASTERMAN
	bl rasters_init
	.endif
	bl maths_init
	; bl initialise_span_buffer

	.if _ENABLE_ROCKET
	bl rocket_init
	.endif

	; Start with bank 1
	mov r1, #1
	str r1, scr_bank
	
	; Claim the Error vector
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Claim

	; Claim the Event vector
	.if !_ENABLE_RASTERMAN
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_AddToVector
	.endif

	; LATE INITALISATION HERE!
	bl init_3d_scene
	.if _RUBBER_CUBE
	bl init_rubber_cube
	.endif

	adr r2, grey_palette
	bl palette_set_block

	; Sync tracker.
	.if _ENABLE_ROCKET
	bl rocket_start		; handles music.
	.else
	.IF _ENABLE_MUSIC
	swi QTM_Start
	.endif
	.endif

	; Fire up the RasterMan!
	.if _ENABLE_RASTERMAN
	swi RasterMan_Install
	.else
	; Enable Vsync 
	mov r0, #OSByte_EventEnable
	mov r1, #Event_VSync
	SWI OS_Byte
	.endif

main_loop:

	; R0 = vsync delta since last frame.
	.if _ENABLE_ROCKET
	ldr r0, vsync_delta
	bl rocket_update
	.endif

	SET_BORDER 0x0000ff	; red
	.if _RUBBER_CUBE
	bl update_rubber_cube
	.else
	bl update_3d_scene
	.endif

	SET_BORDER 0xffff00	; cyan
	bl update_scroller

	SET_BORDER 0x000000	; black
	; Really we need something more sophisticated here.
	; Block only if there's no free buffer to write to.

	.if _ENABLE_RASTERMAN
	swi RasterMan_Wait
	mov r0, #1				; TODO: Ask Steve for RasterMan_GetVsyncCounter.
	.else

	; Block if we've not even had a vsync since last time - we're >50Hz!
	.if (Screen_Banks == 2 && 0)
	; Block if there's a buffer pending to be displayed when double buffered.
	; This means that we overran the previous frame. Triple buffering may
	; help here. Or not. ;)
	.2:
	ldr r1, buffer_pending
	cmp r1, #0
	bne .2	
	.endif

	ldr r1, last_vsync
.1:
	ldr r2, vsync_count
	cmp r1, r2
	beq .1
	.if _FIX_FRAME_RATE
	mov r0, #1
	.else
	sub r0, r2, r1
	.endif
	str r2, last_vsync
	.endif

	str r0, vsync_delta

	.if 0 ; if need to double-buffer raster table.
	bl rasters_copy_table
	.endif

	; DO STUFF HERE!
	bl get_next_screen_for_writing
	ldr r11, screen_addr

	SET_BORDER 0x00ff00	; green
	mov r0, #0x8888
	orr r0, r0, r0, lsl #16
	.if _DRAW_LOGO
	bl logo_copy_and_cls
	.endif

	bl screen_cls

	.if _LEMON_LOGOS
	ldr r11, screen_addr
	bl lemon_logos
	.endif

	SET_BORDER 0xff0000	; blue
	ldr r11, screen_addr
	.if _RUBBER_CUBE
	bl draw_rubber_cube
	.else
	bl draw_3d_scene
	.endif

	SET_BORDER 0xffff00	; cyan
	ldr r11, screen_addr
	bl draw_scroller

	; show debug
	.if _DEBUG
	bl debug_write_vsync_count
	.endif

	SET_BORDER 0x000000	; black
	bl show_screen_at_vsync

	; exit if Escape is pressed
	.if _ENABLE_RASTERMAN
	swi RasterMan_ScanKeyboard
	mov r1, #0xc0c0
	cmp r0, r1
	beq exit
	.else
	swi OS_ReadEscapeState
	bcs exit
	.endif
	
	b main_loop

error_noscreenmem:
	.long 0
	.byte "Cannot allocate screen memory!"
	.p2align 2
	.long 0

.if _DEBUG
debug_write_vsync_count:
	str lr, [sp, #-4]!
	swi OS_WriteI+30			; home text cursor

.if _ENABLE_ROCKET && 0
	bl rocket_get_sync_time
.else
	ldr r0, vsync_delta			; or vsync_count
.endif
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex4

	adr r0, debug_string
	swi OS_WriteO
	
.if _ENABLE_MUSIC
	swi OS_WriteI+32			; ' '

    ; read current tracker position
    mov r0, #-1
    mov r1, #-1
    swi QTM_Pos

	mov r3, r1

	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex2
	adr r0, debug_string
	swi OS_WriteO

	swi OS_WriteI+58			; ':'

	mov r0, r3
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex2
	adr r0, debug_string
	swi OS_WriteO
.endif
	ldr pc, [sp], #4

debug_string:
	.skip 16
.endif

get_screen_addr:
	str lr, [sp, #-4]!
	adrl r0, screen_addr_input
	adrl r1, screen_addr
	swi OS_ReadVduVariables
	ldr pc, [sp], #4
	
screen_addr_input:
	.long VD_ScreenStart, -1

exit:	
	; wait for vsync (any pending buffers)
	.if _ENABLE_RASTERMAN
	swi RasterMan_Wait
	swi RasterMan_Release
	swi RasterMan_Wait
	.endif

	.if _ENABLE_MUSIC
	; disable music
	mov r0, #0
	swi QTM_Clear
	.endif

	; disable vsync event
	.if !_ENABLE_RASTERMAN
	mov r0, #OSByte_EventDisable
	mov r1, #Event_VSync
	swi OS_Byte

	; release our event handler
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_Release
	.endif

	; release our error handler
	mov r0, #ErrorV
	adr r1, error_handler
	mov r2, #0
	swi OS_Release

	; Display whichever bank we've just written to
	mov r0, #OSByte_WriteDisplayBank
	ldr r1, scr_bank
	swi OS_Byte
	; and write to it
	mov r0, #OSByte_WriteVDUBank
	ldr r1, scr_bank
	swi OS_Byte

	; CLS
	mov r0, #12
	SWI OS_WriteC

	; Flush keyboard buffer.
	mov r0, #15
	mov r1, #1
	swi OS_Byte

	SWI OS_Exit

; R0=event number
.if !_ENABLE_RASTERMAN
event_handler:
	cmp r0, #Event_VSync
	movnes pc, r14

	STMDB sp!, {r0-r1, lr}

	; update the vsync counter
	LDR r0, vsync_count
	ADD r0, r0, #1
	STR r0, vsync_count

.if 0
	; is there a new screen buffer ready to display?
	LDR r1, buffer_pending
	CMP r1, #0
	LDMEQIA sp!, {r0-r1, pc}

	; set the display buffer
	MOV r0, #0
	STR r0, buffer_pending
	MOV r0, #OSByte_WriteDisplayBank

	; some SVC stuff I don't understand :)
	STMDB sp!, {r2-r12}
	MOV r9, pc     ;Save old mode
	ORR r8, r9, #3 ;SVC mode
	TEQP r8, #0
	MOV r0,r0
	STR lr, [sp, #-4]!
	SWI XOS_Byte

	; set full palette if there is a pending palette block
	ldr r2, palette_pending
	cmp r2, #0
	beq .4

    adr r1, palette_osword_block
    mov r0, #16
    strb r0, [r1, #1]       ; physical colour

    mov r3, #0
    .3:
    strb r3, [r1, #0]       ; logical colour

    ldr r4, [r2], #4        ; rgbx
    and r0, r4, #0xff
    strb r0, [r1, #2]       ; red
    mov r0, r4, lsr #8
    strb r0, [r1, #3]       ; green
    mov r0, r4, lsr #16
    strb r0, [r1, #4]       ; blue
    mov r0, #12
    swi XOS_Word

    add r3, r3, #1
    cmp r3, #16
    blt .3

	mov r0, #0
	str r0, palette_pending
.4:

	LDR lr, [sp], #4
	TEQP r9, #0    ;Restore old mode
	MOV r0, r0
	LDMIA sp!, {r2-r12}
.endif

	LDMIA sp!, {r0-r1, pc}
.endif

error_handler:
	STMDB sp!, {r0-r2, lr}
	.if _ENABLE_RASTERMAN
	swi RasterMan_Release
	.endif

	.if _ENABLE_MUSIC
	; disable music
	mov r0, #0
	swi QTM_Clear
	.endif
.if !_ENABLE_RASTERMAN
	MOV r0, #OSByte_EventDisable
	MOV r1, #Event_VSync
	SWI OS_Byte
	MOV r0, #EventV
	ADR r1, event_handler
	mov r2, #0
	SWI OS_Release
.endif
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Release
	MOV r0, #OSByte_WriteDisplayBank
	LDR r1, scr_bank
	SWI OS_Byte
	LDMIA sp!, {r0-r2, lr}
	MOVS pc, lr

show_screen_at_vsync:
	; Show current bank at next vsync
	ldr r1, scr_bank
.if 0
	str r1, buffer_pending
	; Including its associated palette
	ldr r1, palette_block_addr
	str r1, palette_pending
.else
	MOV r0, #OSByte_WriteDisplayBank
	swi OS_Byte
.endif
	mov pc, lr

get_next_screen_for_writing:
	; Increment to next bank for writing
	ldr r1, scr_bank
	add r1, r1, #1
	cmp r1, #Screen_Banks
	movgt r1, #1
	str r1, scr_bank

	; Now set the screen bank to write to
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte

	; Back buffer address for writing bank stored at screen_addr
	b get_screen_addr

; ============================================================================
; Global vars.
; ============================================================================

; TODO: rename these to be clearer.
scr_bank:
	.long 0				; current VIDC screen bank being written to.

palette_block_addr:
	.long 0				; (optional) ptr to a block of palette data for the screen bank being written to.

vsync_count:
	.long 0				; current vsync count from start of exe.

last_vsync:
	.long 0				; vsync count at start of previous frame.

vsync_delta:
	.long 0

buffer_pending:
	.long 0				; screen bank number to display at vsync.

palette_pending:
	.long 0				; (optional) ptr to a block of palette data to set at vsync.

screen_addr:
	.long 0				; ptr to the current VIDC screen bank being written to.


; ============================================================================
; Additional code modules
; ============================================================================

; R0=cls colour word
; R11=screen ptr
.if _DRAW_LOGO
logo_copy_and_cls:
	str lr, [sp, #-4]!
	; Hacky hacky.
	add r12, r11, #Screen_Stride * Logo_Y_Pos
	bl screen_cls_with_end_ptr_set

	; Copy logo data to screen.
	adr r10, logo_data
	adr r12, logo_end
	sub r9, r12, r10

.1:
	ldmia r10!, {r1-r8}
	stmia r11!, {r1-r8}
	cmp r10, r12
	blt .1

	; Clear the rest of it.
	add r12, r11, #Screen_Bytes
	sub r12, r12, r9
	ldr lr, [sp], #4
	b screen_cls_with_end_ptr_set
.endif

.if _LEMON_LOGOS
lemon_logos:
	str lr, [sp, #-4]!
	add r11, r11, #Screen_Stride * Logo_Y_Pos

	adr r1, bit_string
	mov r8, #0x00000000
	mov r6, #0xffffffff
	bl plot_string

	adr r1, shifters_string
	mov r8, #0xffffffff
	mov r6, #0x00000000
	bl plot_string

	add r11, r11, #19*4
	adr r1, slip_string
	mov r8, #0x00000000
	mov r6, #0xffffffff
	bl plot_string

	adr r1, stream_string
	mov r8, #0xffffffff
	mov r6, #0x00000000
	bl plot_string

	ldr pc, [sp], #4

bit_string:
	.byte "bit"
	.byte 0
	.p2align 2

shifters_string:
	.byte "shifters"
	.byte 0
	.p2align 2

slip_string:
	.byte "slip"
	.byte 0
	.p2align 2

stream_string:
	.byte "stream"
	.byte 0
	.p2align 2
.endif

.include "lib/maths.asm"
.include "lib/3d-scene.asm"

reciprocal_table_p:
    .long reciprocal_table

.include "lib/rubber-cube.asm"
.include "lib/mode9-screen.asm"
;.include "lib/mode9-plot.asm"
.include "lib/mode9-palette.asm"
.if _ENABLE_RASTERMAN
.include "lib/rasters.asm"
.endif
.include "lib/scroller.asm"

.if _ENABLE_ROCKET
.include "lib/rocket.asm"
.endif

; ============================================================================
; Data Segment
; ============================================================================

grey_palette:
.if 0
	.long 0x00000000
	.long 0x00111111
	.long 0x00222222
	.long 0x00333333
	.long 0x00444444
	.long 0x00555555
	.long 0x00666666
	.long 0x00777777
	.long 0x00888888
	.long 0x00999999
	.long 0x00AAAAAA
	.long 0x00BBBBBB
	.long 0x00CCCCCC
	.long 0x00DDDDDD
	.long 0x00EEEEEE
	.long 0x00FFFFFF
.else
	.long 0x00000000
	.long 0x000000ff
	.long 0x0000ff00
	.long 0x0000ffff
	.long 0x00ff0000
	.long 0x00ff00ff
	.long 0x00ffff00
	.long 0x00ffffff
	.long 0x00888888
	.long 0x00999999
	.long 0x00AAAAAA
	.long 0x00BBBBBB
	.long 0x00CCCCCC
	.long 0x00DDDDDD
	.long 0x00EEEEEE
	.long 0x00FFFFFF
.endif

scroller_message:
; At 1 pixel/frame = 6.4s to traverse the screen.
; Speed = 40 chars/6.4s = 6.25 chars/s
; 16 patterns at 6 ticks/row = 122.88s
; So in 122.88s 122.88s * 6.25 chars/s = 768 chars.
;                                                                                                             1
;                   1         2         3         4         5         6         7         8         9         0
;          1........0.........0.........0.........0.........0.........0.........0.........0.........0.........0
    .byte "                                                    Is it a terrible twister?  No... this is the fir"
    .byte "st ever tipsy cube intro for the Acorn Archimedes!  Brought to you by Bitshifters & Slipstream for t"
    .byte "he FieldFX 2022 New Year's demostream.  Inspired by the Gerp 2014 rubber vector challenge, just rock"
    .byte "ing up 8 years late in true Archie fashion.  Credits..  code by kieran -- music by ToBach -- QTM/Ras"
    .byte "terMan by Phoenix^Quantum -- special thanks to Progen.  Tipsy cheers go out to...  Ate-Bit -- CRTC -"
    .byte "- DESiRE -- Hooy Program -- Inverse Phase -- Logicoma -- Loonies -- ne7 -- Proxima -- Rabenauge -- R"
    .byte "ift -- Torment -- YM Rockerz.  Tipsy hugs to Lemon. and Spaceballs for the Amiga inspiration.  Wishi"
    .byte "ng everyone a Happy New Year for 2023.  See you all at NOVA in June!"
    .byte 0
    .p2align 2

font_data:
    .incbin "build/font.bin"

.if _DRAW_LOGO
logo_data:
.incbin "build/logo.bin"
logo_end:
.endif

.if _ENABLE_MUSIC
music_data:
.incbin "data/music/arcchoon.mod"
.endif

palette_osword_block:
    .skip 8
    ; logical colour
    ; physical colour (16)
    ; red
    ; green
    ; blue
    ; (pad)

.include "lib/tables.asm"

; ============================================================================
; BSS Segment
; ============================================================================

.include "lib/bss.asm"
