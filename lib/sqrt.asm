; ============================================================================
; SQRT routines.
; ============================================================================

; Assumptions:
;  SQRT and RSQRT tables available for values [0-65535]
;  Number of entries is 1024. (10-bits)

; Compute R0=sqrt (R1)
; Where R1 [0.0, 256.0)
; Trashes: R9
sqrt:
    adr r9, sqrt_table
    mov r1, r1, asr #8          ; [16.8]
    bic r8, r1, #0xff0000       ; [8.8]     ; overflow?
    mov r1, r1, lsr #6          ; [8.2]
    ldr r0, [r9, r1, lsl #2]
    mov pc, lr

; Compute R0=1/sqrt (R1)
; Where R1 [0.0, 256.0)
; Trashes: R9
rsqrt:
    adr r9, rsqrt_table
    mov r1, r1, asr #8          ; [16.8]
    bic r8, r1, #0xff0000       ; [8.8]     ; overflow?
    mov r1, r1, lsr #6          ; [8.2]
    ldr r0, [r9, r1, lsl #2]
    mov pc, lr
