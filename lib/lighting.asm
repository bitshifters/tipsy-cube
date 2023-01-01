; ============================================================================
; Lighting routines.
; ============================================================================


; Directional light calculation.
;
; Parameters:
;  R1=ptr to lighting direction vector (normalised)
;  R2=ptr to face normal vector
; Return:
;  R0=lighting contribution [0,1] [0.16]
; Trashes: R3-R8
;
; Compute R0=L.N
directional_lighting:
    str lr, [sp, #-4]!
    bl vector_dot_product
    ldr pc, [sp], #4


; Point light source calculation.
;
; Parameters:
;  R0=ptr to world position vector
;  R1=ptr to lighting position vector
;  R2=ptr to face normal vector
; Return:
;  R0=lighting contribution [0,1] [0.16]
; Trashes: R3-R9
;
; Compute R0=L.N/|L| where L=world_pos-light_pos
; NOTE: THIS IS UNTESTED.
.if 0
point_lighting:
    str lr, [sp, #-4]!

    mov r10, r2             ; stash N

    mov r2, r1              ; light_pos
    mov r1, r0              ; world_pos
    adr r0, temp_vector_1
    bl vector_sub           ; L=world_pos - light_pos

    adr r1, temp_vector_1   ; L
    mov r2, r10             ; N
    bl vector_dot_product   ; R0=L.N

    cmp r0, #0              ; L.N < 0 then facing away from light source
    movmi r0, #0            ; zero contribution.
    ldrmi pc, [sp], #4      ; return.

    mov r10, r0, asr #8     ; stash L.N as [16.8]
    adr r1, temp_vector_1
    bl vector_recip_length  ; R0=1/|L|   [0.16]

    ; Compute L.N/|L|
    mul r0, r10, r0         ; [8.24]        ; overflow?
    mov r0, r0, asr #8      ; [0.16]
    ldr pc, [sp], #4
.endif
