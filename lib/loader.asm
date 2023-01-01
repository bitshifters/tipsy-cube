; ============================================================================
; Generic loader to decompress main exe.
; ============================================================================

.equ _DEBUG, 0

.include "../lib/swis.h.asm"

.ifndef _WIMPSLOT
.equ _WIMPSLOT, 1500*1024            ; Assumed RAM.
.endif

.equ STACK_SIZE, 1024

.org 0x8000

main:
    ; Get compressed file size.
    mov r0, #5
	adr r1, filename
    swi OS_File
    cmp r0, #1
    swine OS_Exit                   ; file not found.
    ; R4=file length.

    ; Calculate load address.
    ldr r2, endofram
    add r4, r4, #3
    bic r4, r4, #0b11               ; round up to 4 bytes
    sub r2, r2, r4                  ; subtract file size
    sub r2, r2, #STACK_SIZE + NUM_CONTEXTS*4    ; subtract working space
    mov r9, r2                      ; remember load address

	; Load compressed file.
	mov r0, #0xff
	adr r1, filename
    mov r3, #0
	swi OS_File

    ; Relocate LZ4 decoder.
    ldr r12, endofram               ; dst
    mov r8, r12
    adr r11, reloc_start            ; src
    adr r10, reloc_end              ; end
.1:
    ldr r0, [r11], #4
    str r0, [r12], #4
    cmp r11, r10
    blt .1

    ; Call decompressor.
    mov r0, r9                      ; source
    mov r1, #0x8000                 ; destination
    mov r2, #0                      ; no callback
    sub r9, r8, #STACK_SIZE + NUM_CONTEXTS*4               ; context
    mov sp, r8                      ; reset stack top
    mov pc, r8                      ; jump to reloc


filename:
	.byte "<Demo$Dir>.Demo",0
	.align 4

endofram:
    .long 0x8000 + _WIMPSLOT - (reloc_end - reloc_start)

reloc_start:
	bl ShrinklerDecompress
    mov pc, #0x8000

.include "../lib/arc-shrinkler.asm"

reloc_end:

; ============================================================================
