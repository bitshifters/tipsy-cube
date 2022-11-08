; ============================================================================
; Prototype Framework - stripped back from stniccc-archie.
; ============================================================================

.equ _DEBUG, 1
.equ _ENABLE_MUSIC, 0
.equ _FIX_FRAME_RATE, 0					; useful for !DDT breakpoints
.equ _SYNC_EDITOR, 1

.equ Screen_Banks, 3
.equ Screen_Mode, 9
.equ Screen_Width, 320
.equ Screen_Height, 240
.equ Mode_Height, 256
.equ Screen_PixelsPerByte, 2
.equ Screen_Stride, Screen_Width/Screen_PixelsPerByte
.equ Screen_Bytes, Screen_Stride*Screen_Height
.equ Mode_Bytes, Screen_Stride*Mode_Height

.include "lib/swis.h.asm"

.org 0x8000

; ============================================================================
; Stack
; ============================================================================

Start:
    adrl sp, stack_base
	B main

.skip 1024
stack_base:

; ============================================================================
; Main
; ============================================================================

main:
	MOV r0,#22	;Set MODE
	SWI OS_WriteC
	MOV r0,#Screen_Mode
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

	MOV r0,#23	;Disable cursor
	SWI OS_WriteC
	MOV r0,#1
	SWI OS_WriteC
	MOV r0,#0
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC

	; LOAD STUFF HERE!

.if _ENABLE_MUSIC
	; Load module
	adrl r0, module_filename
	mov r1, #0
	swi QTM_Load

	mov r0, #48
	swi QTM_SetSampleSpeed
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

	; Start with bank 1
	mov r1, #1
	str r1, scr_bank
	
	; Claim the Error vector
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Claim

	; Claim the Event vector
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_AddToVector

	; LATE INITALISATION HERE!
	adr r2, blue_palette
	bl palette_set_block

	; Sync tracker.
	bl rocket_init
	bl rocket_start

	; Enable Vsync event
	mov r0, #OSByte_EventEnable
	mov r1, #Event_VSync
	SWI OS_Byte

main_loop:

	; Block if we've not even had a vsync since last time - we're >50Hz!
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
	str r0, vsync_delta

	; R0 = vsync delta since last frame.
	bl rocket_update

	; show debug
	.if _DEBUG
	bl debug_write_vsync_count
	.endif

	; DO STUFF HERE!
	bl get_next_screen_for_writing
	ldr r8, screen_addr
	bl screen_cls
	bl stacked_plot_fx
	bl show_screen_at_vsync

	; exit if Escape is pressed
	MOV r0, #OSByte_ReadKey
	MOV r1, #IKey_Escape
	MOV r2, #0xff
	SWI OS_Byte
	
	CMP r1, #0xff
	CMPEQ r2, #0xff
	BEQ exit
	
	b main_loop

error_noscreenmem:
	.long 0
	.byte "Cannot allocate screen memory!"
	.align 4
	.long 0

.if _DEBUG
debug_write_vsync_count:
	mov r0, #30
	swi OS_WriteC

.if _ENABLE_MUSIC
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

	mov r0, r3
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex2
	adr r0, debug_string
	swi OS_WriteO
.else
	ldr r0, vsync_delta	; rocket_sync_time
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex4

	adr r0, debug_string
	swi OS_WriteO
.endif
	mov pc, r14

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

screen_addr:
	.long 0					; ptr to the current VIDC screen bank being written to.

exit:	
	; wait for vsync (any pending buffers)
	mov r0, #19
	swi OS_Byte

.if _ENABLE_MUSIC
	; disable music
	mov r0, #0
	swi QTM_Stop
.endif

	; disable vsync event
	mov r0, #OSByte_EventDisable
	mov r1, #Event_VSync
	swi OS_Byte

	; release our event handler
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_Release

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

	SWI OS_Exit

; R0=event number
event_handler:
	cmp r0, #Event_VSync
	movnes pc, r14

	STMDB sp!, {r0-r1, lr}

	; update the vsync counter
	LDR r0, vsync_count
	ADD r0, r0, #1
	STR r0, vsync_count

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
	LDMIA sp!, {r0-r1, pc}

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

error_handler:
	STMDB sp!, {r0-r2, lr}
	MOV r0, #OSByte_EventDisable
	MOV r1, #Event_VSync
	SWI OS_Byte
	MOV r0, #EventV
	ADR r1, event_handler
	mov r2, #0
	SWI OS_Release
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
	str r1, buffer_pending
	; Including its associated palette
	ldr r1, palette_block_addr
	str r1, palette_pending
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
; Additional code modules
; ============================================================================

.include "lib/rocket.asm"
.include "lib/mode9-palette.asm"

.macro PIXEL_LOOKUP_TO reg
	; r0 = XXvv00uu
	add r3, r0, r9				; XXvv00uu + YYbb00aa
	and r0, r3, #0x000000ff
	and r1, r3, #0x00ff0000
	add r0, r0, r11
	ldrb \reg, [r0, r1, lsr #8]
	; 8c
.endm

.equ Stacked_Plot_Z_Start, Screen_Height-4
.equ Stacked_Plot_Z_Step, 8
.equ Stacked_Plot_X_Step, 8

stacked_plot_fx:
	str lr, [sp, #-4]!

; R0=startx, R1=starty, R2=endx, R3=endy, R4=colour, R12=screen_addr
	ldr r12, screen_addr

	; Reset Y-buffer
	bl y_buffer_reset

	; Draw lines from bottom to top (Z)
	mov r5, #Stacked_Plot_Z_Start
	.1:
	bl stacked_plot_line
	subs r5, r5, #Stacked_Plot_Z_Step
	bpl .1

	ldr pc, [sp], #4

stacked_plot_line:
	stmfd sp!, {r5, lr}

	; Plot line from left to right
	mov r6, #0

	; Get y = fn(x, z)
	; r5=z, r6=x, returns r7=y
	; must preserve r0,r1
	bl stacked_fn
	mov r0, r6
	mov r1, r7

	.1:
	add r6, r6, #Stacked_Plot_X_Step
	cmp r6, #Screen_Width
	bge .2

	; Get y' = fn(x', z)
	bl stacked_fn
	mov r2, r6
	mov r3, r7

	stmfd sp!, {r5,r6}

	mov r4, #0x0f

	; Draw line from (x,y) to (x',y')
	bl drawline
	; Now r0=x', r1=y'

	ldmfd sp!, {r5,r6}
	b .1
	.2:

	ldmfd sp!, {r5, pc}

; r5=z, r6=x, returns r7=y = fn(x, z)
; must preserve r0,r1
stacked_fn:
	; 
	adr r9, sine_table

	ldr r7, rocket_sync_time	; t
	add r7, r7, r5				; z+t
	and r7, r7, #255
	ldr r10, [r9, r7, lsl #2]	; sin(z+t)
	mov r10, r10, asr #4		; 1.12

	add r8, r6, r7
	and r8, r8, #255			; table size
	ldr r7, [r9, r8, lsl #2]	; sin(x)
	mov r7, r7, asr #4			; 1.12

	mul r8, r10, r7				; 1.8 x 1.8 = 1.24
	mov r7, r8, asr #19			; max +-32 pixels

	; Add z to y to make the stack.
	add r7, r7, r5
	mov pc, lr

y_buffer_reset:
	mov r0, #0
	mov r1, #Screen_Height
	adr r2, y_buffer
	add r0, r2, #Screen_Width*4
	.1:
	str r1, [r2], #4
	cmp r2, r0
	blt .1
	mov pc, lr


; R0=startx, R1=starty, R2=endx, R3=endy, R4=colour, R12=screen_addr
; Trashes r5, r6, r7, r8, r9, r10, r11
drawline:
	str lr, [sp, #-4]!			; push lr on stack

	subs r5, r2, r0				; r5 = dx = endx - startx
	rsblt r5, r5, #0			; r5 = abs(dx)

	cmp r0,r2					; startx < endx?
	movlt r7, #1				; r7 = sx = 1
	movge r7, #-1				; r7 = sx = -1

	subs r6, r3, r1				; r6 = dy = endy - starty
	rsblt r6, r6, #0			; r6 = abs(dy)
	rsb r6, r6, #0				; r6 = -abs(dy)

	cmp r1, r3					; starty < endy?
	movlt r8, #1				; r8 = sy = 1
	movge r8, #-1				; r8 = sy = -1

	add r9, r5, r6				; r9 = dx + dy = err

.1:
	cmp r0, r2					; x0 == x1?
	cmpeq r1, r3				; y0 == y1?
	ldreq pc, [sp], #4			; rts

	; there will be faster line plot algorithms by keeping track of
	; screen pointer then flushing a byte or word when moving to next row
	bl plot_pixel

	mov r10, r9, lsl #1			; r10 = err * 2
	cmp r10, r6					; e2 >= dy?
	addge r9, r9, r6			; err += dy
	addge r0, r0, r7			; x0 += sx

	cmp r10, r5					; e2 <= dx?
	addle r9, r9, r5			; err += dx
	addle r1, r1, r8			; y0 += sy

	b .1

; R0=x, R1=y, R4=colour, R12=screen_addr, trashes r10, r11
plot_pixel:
	cmp r1, #Screen_Height
	movge pc, lr
	cmp r1, #0
	movmi pc, lr

	adr r10, y_buffer
	ldr r11, [r10, r0, lsl #2]	; y_buffer[x]
	cmp r1, r11
	movge pc, lr
	str r1, [r10, r0, lsl #2]	; y_buffer[x] = y

	; ptr = screen_addr + starty * screen_stride + startx DIV 2
	add r10, r12, r1, lsl #7	; r10 = screen_addr + starty * 128
	add r10, r10, r1, lsl #5	; r10 += starty * 32 = starty * 160
	add r10, r10, r0, lsr #1	; r10 += startx DIV 2

	ldrb r11, [r10]				; load screen byte

	tst r0, #1					; odd or even pixel?
	andeq r11, r11, #0xF0		; mask out left hand pixel
	orreq r11, r11, r4			; mask in colour as left hand pixel

	andne r11, r11, #0x0F		; mask out right hand pixel
	orrne r11, r11, r4, lsl #4	; mask in colour as right hand pixel

	strb r11, [r10]				; store screen byte
	mov pc, lr

.include "lib/mode9-screen.asm"
.include "lib/maths.asm"

; ============================================================================
; Data Segment
; ============================================================================

.if _ENABLE_MUSIC
module_filename:
	.byte "<Demo$Dir>.Music",0
	.align 4
.endif

blue_palette:
	.long 0x00000000
	.long 0x00110000
	.long 0x00220000
	.long 0x00330000
	.long 0x00440000
	.long 0x00550000
	.long 0x00660000
	.long 0x00770000
	.long 0x00880000
	.long 0x00990000
	.long 0x00AA0000
	.long 0x00BB0000
	.long 0x00CC0000
	.long 0x00DD0000
	.long 0x00EE0000
	.long 0x00FF0000

.p2align 6
sine_table:
	.incbin "data\sine.bin"

; ============================================================================
; BSS Segment
; ============================================================================

palette_osword_block:
    .skip 8
    ; logical colour
    ; physical colour (16)
    ; red
    ; green
    ; blue
    ; (pad)

.p2align 6
y_buffer:
	.skip Screen_Width
