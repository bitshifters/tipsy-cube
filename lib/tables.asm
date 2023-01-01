; ============================================================================
; Library module tables (include at end).
; ============================================================================

.p2align 6

; ============================================================================
; Data tables.
; ============================================================================

sinus_table:
	.incbin "data/sine_8192.bin"

; ============================================================================

.if _INCLUDE_SQRT
sqrt_table:
	.incbin "data/sqrt_1024.bin"

rsqrt_table:
	.incbin "data/rsqrt_1024.bin"
.endif

; ============================================================================
; BSS.
; ============================================================================

polygon_span_table:
    .skip Screen_Height * 4     ; per scanline.

; ============================================================================

.if _USE_RECIPROCAL_TABLE
reciprocal_table:
	.skip 65536*4
.endif

; ============================================================================

; For each frame:               [MAX_FRAMES]
;  long number_of_faces         (4)
;  long object_min_max_y        (4) max in high word, min in low word.
;  For each face:               [MAX_VISIBLE_FACES]
;   long number_of_edges         (4)
;   long face_colour_word        (4) as written to screen.
;   long face_min_y              (4)
;   long face_max_y              (4)

rubber_cube_face_list:
    .skip RUBBER_CUBE_MAX_FRAMES * RUBBER_CUBE_FACES_SIZE

; WARNING: Code must change if these do!
; Actually doesn't need to be a circular buffer, we preallocate the max
; size per frame, so edge_size * max_edges * max_faces = 192.
rubber_cube_edge_list:
    .skip POLYGON_EDGE_SIZE * OBJ_MAX_EDGES_PER_FACE * OBJ_MAX_VISIBLE_FACES * RUBBER_CUBE_MAX_FRAMES
    ; 16 * 4 * 3 * 256 = 192 * 256

; ============================================================================

.if _INCLUDE_SPAN_GEN
gen_code_pointers:
	.skip	4*8*MAXSPAN

gen_code_start:
.endif

; ============================================================================

