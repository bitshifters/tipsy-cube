; ============================================================================
; BSS.
; ============================================================================

.bss

; ============================================================================

stack:
    .skip 1024
stack_base:

; ============================================================================

.p2align 2
vidc_table_1:
	.skip 256*4*4

; TODO: Can we get rid of these?
vidc_table_2:
	.skip 256*4*4

vidc_table_3:
	.skip 256*8*4

memc_table:
	.skip 256*2*4

; ============================================================================

.if _RUBBER_CUBE != 0
polygon_span_table:
    .skip Screen_Height * 4     ; per scanline.
.endif

; ============================================================================

.if _USE_RECIPROCAL_TABLE
reciprocal_table:
	.skip 65536*4
.endif

; ============================================================================

.if _RUBBER_CUBE
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
.endif

; ============================================================================

.if _INCLUDE_SPAN_GEN
gen_code_pointers:
	.skip	4*8*MAXSPAN

gen_code_start:
.endif

; ============================================================================
