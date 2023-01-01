; ============================================================================
; Rasters via RasterMan.
; ============================================================================

rasters_init:
    ; Configure RasterMan for future compatibility.
    mov r0, #4
    mov r1, #0
    mov r2, #-1
    mov r3, #-1
    mov r4, #-1
    swi RasterMan_Configure

	; Init tables.
	adr r5, raster_tables
	ldmia r5, {r0-r3}
	add r0, r0, r5			; vidc table 1
	add r1, r1, r5			; vidc table 2
	add r2, r2, r5			; vidc table 3
	add r3, r3, r5			; memc table
	stmfd sp!, {r0-r3}

	mov r4, #0
	mov r6, #VIDC_Col0 | 0x000
	mov r7, r6
	mov r8, r6
	mov r9, r6
	mov r5, #256
.1:
	stmia r0!, {r6-r9}		; 4x VIDC commands per line.
	stmia r1!, {r6-r9}		; 4x VIDC commands per line.
	stmia r2!, {r6-r9}		; 4x VIDC commands per line.
	stmia r2!, {r6-r9}		; 4x VIDC commands per line.
	str r4, [r3], #4
	str r4, [r3], #4
	subs r5, r5, #1
	bne .1

	ldmfd sp, {r0-r3}
	swi RasterMan_SetTables
	ldmfd sp!, {r0-r3}

    ; Add some actual rasters. Use a table, dummy.
    mov r3, #0
    adr r2, raster_list
.2:
    ldmia r2!, {r5-r9}
    cmp r5, #-1
    moveq pc, lr

    movs r4, r5, lsr #8     ; strip out repeat.
    moveq r4, #1            ; zero repeat means just 1.
    and r5, r5, #0xff       ; raster line.
    add r1, r0, r5, lsl #4  ; find line entry in VIDC table 1.

.3:
    stmia r1!, {r6-r9}      ; blat VIDC registers for line.
    subs r4, r4, #1
    bne .3

    str r3, [r1]            ; always reset bg colour to black.

    b .2

; Number repeats << 8 | Rasterline, VIDC registers x 4.
; 0xffffffff to end list.
raster_list:
    .long 0,   VIDC_Col8 | 0x222, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000
    .long 1,   VIDC_Border | 0x222, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000
    .long 170, VIDC_Border | 0x444, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000
    .long 171, VIDC_Col8 | 0x444, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000
    .long 254, VIDC_Border | 0x222, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000
    .long 255, VIDC_Col8 | 0x222, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000, VIDC_Col0 | 0x000

    ; End.
    .long 0xffffffff

raster_tables:
	.long vidc_table_1 - raster_tables
	.long vidc_table_2 - raster_tables
	.long vidc_table_3 - raster_tables
	.long memc_table   - raster_tables

.if 0   ; if need to double-buffer raster table.
rasters_copy_table:
    adr r9, vidc_table_1
    adr r10, vidc_table_2
    adr r11, vidc_table_3

.1:
    ldmia r10!, {r0-r7}
    stmia r9!, {r0-r7}
    cmp r10, r11
    blt .1

    mov pc, lr
.endif
