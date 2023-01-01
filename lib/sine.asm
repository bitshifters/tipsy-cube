; ============================================================================
; Sine and cosine functions.
; ============================================================================

.equ SINUS_TABLE_BITS, 13
.equ SINUS_TABLE_SIZE, 1<<SINUS_TABLE_BITS
.equ SINUS_TABLE_SHIFT, 32-SINUS_TABLE_BITS

; Sine.
; Parameters:
;  R0 = radians [0.0, 1.0] at fixed point precision. [s1.16]
; Returns:
;  R0 = sin(2 * PI * radians)
; Trashes: R9
sine:
    adr r9, sinus_table
    mov r0, r0, asl #PRECISION_BITS         ; remove integer part
    mov r0, r0, lsr #SINUS_TABLE_SHIFT      ; remove insignificant bits
    ldr r0, [r9, r0, lsl #2]                ; lookup word
    mov pc, lr

; Cosine.
; Parameters:
;  R0 = radians [0.0, 1.0] at fixed point precision. [s1.16]
; Returns:
;  R0 = cos(2 * PI * radians)
; Trashes: R9
cosine:
    adr r9, sinus_table
    add r0, r0, #MATHS_CONST_QUARTER                    ; add PI/2
    mov r0, r0, asl #PRECISION_BITS         ; remove integer part
    mov r0, r0, lsr #SINUS_TABLE_SHIFT      ; remove insignificant bits
    ldr r0, [r9, r0, lsl #2]                ; lookup word
    mov pc, lr

; Sine and Cosine.
; Parameters:
;  R0 = angle in brads [0-255]
; Returns:
;  R0 = sin(angle)
;  R1 = cos(angle)
; Trashes: R9
sin_cos:
    adr r9, sinus_table
    mov r0, r0, asr #8                      ; convert brads to radians
    add r1, r0, #MATHS_CONST_QUARTER                    ; add PI/2
    mov r1, r1, asl #PRECISION_BITS         ; remove integer part
    mov r1, r1, lsr #SINUS_TABLE_SHIFT      ; remove insignificant bits
    ldr r1, [r9, r1, lsl #2]                ; lookup word
    mov r0, r0, asl #PRECISION_BITS         ; remove integer part
    mov r0, r0, lsr #SINUS_TABLE_SHIFT      ; remove insignificant bits
    ldr r0, [r9, r0, lsl #2]                ; lookup word
    mov pc, lr

; ============================================================================
