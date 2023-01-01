; ============================================================================
; Library of code modules.
; ============================================================================

.equ _DEBUG, 0
.include "lib/swis.h.asm"

.org 0x0000

; ============================================================================
; Jump table to functions.
; ============================================================================

b vector_dot_product               ; +0
b matrix_multiply_vector    ; +4
b matrix_multiply           ; +8
b sine                      ; +12
b cosine                    ; +16
b matrix_make_rotate_x      ; +20
b matrix_make_rotate_y      ; +24
b matrix_make_rotate_z      ; +28
b matrix_make_identity      ; +32
b divide                    ; +36

; ============================================================================
; Code modules.
; ============================================================================

.include "lib/maths.asm"
