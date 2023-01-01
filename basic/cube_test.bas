MODE 9
precision=65536
:
DIM code 65536
OSCLI "LOAD <Test$Dir>.CodeLib "+STR$~(code)
vector_dot_product=code+0
matrix_multiply_vector=code+4
matrix_multiply=code+8
sine=code+12
cosine=code+16
make_rotate_x=code+20
make_rotate_y=code+24
make_rotate_z=code+28
make_identity=code+32
divide=code+36
:
cx=0:cy=0:cz=-160
ox=0:oy=0:oz=64
: REM vp_dist (D)=160 and vp_height (h)=160.
: REM So h/D=1 FOV=2*atan(h/D)=90 degrees
: REM Say FOV=60 h/D=0.57735 D=160/0.57735~=277.128
vp_scale=160
vp_centre_x=160:vp_centre_y=128
vdu_scale=4:
:
vec_size=12
num_verts=8
num_faces=6
DIM obj_verts num_verts*vec_size
DIM obj_faces num_faces*4
DIM rot_matrix 9*4
DIM rot_verts num_verts*vec_size
:
PROCmake_cube(num_verts,obj_verts,num_faces,obj_faces)
REPEAT UNTIL GET
:
angle=0
:
REPEAT
*FX19
CLS
:
A%=FNfloat_to_fp(angle):C%=rot_matrix:CALL make_rotate_y
PROCprintf_matrix(rot_matrix)
PROCrotate_verts(num_verts, obj_verts, rot_verts, rot_matrix)
:REM PROCplot_verts(num_verts, rot_verts)
PROCplot_edges(num_verts, rot_verts, num_faces, obj_faces)
:
:REM REPEAT UNTIL GET
angle=(angle+1) MOD 256
:
UNTIL FALSE
END
:
DEF FNfloat_to_fp(v)
=INT(v*precision)
DEF FNfp_to_float(fp)
=fp/precision
:
DEF PROCmake_vec(vec, x, y, z)
vec!0=FNfloat_to_fp(x):vec!4=FNfloat_to_fp(y):vec!8=FNfloat_to_fp(z)
ENDPROC
DEF PROCprintx_vec(name$,vec)
PRINT name$;"=[";~vec!0;",";~vec!4;",";~vec!8;"] ";
ENDPROC
DEF PROCprintf_vec(name$,vec)
PRINT name$;"=[";FNfp_to_float(vec!0);",";FNfp_to_float(vec!4);",";FNfp_to_float(vec!8);"] ";
ENDPROC
:
DEF PROCprintf_matrix(mat)
PRINT "[";FNfp_to_float(mat!0);",";FNfp_to_float(mat!4);",";FNfp_to_float(mat!8);"]"
PRINT "[";FNfp_to_float(mat!12);",";FNfp_to_float(mat!16);",";FNfp_to_float(mat!20);"]"
PRINT "[";FNfp_to_float(mat!24);",";FNfp_to_float(mat!28);",";FNfp_to_float(mat!32);"]"
ENDPROC
:
DEF PROCmake_cube(num_verts, vert_buf, num_faces, face_buf)
FOR I%=0 TO num_verts-1
vp=vert_buf+I%*vec_size
READ x, y, z
PROCmake_vec(vp, x, y, z)
PROCprintf_vec(STR$(I%),vp):PRINT
NEXT

FOR I%=0 TO num_faces-1
fp=face_buf+I%*4
READ a, b, c, d
fp?0=a:fp?1=b:fp?2=c:fp?3=d
PRINT a, b, c, d
NEXT
ENDPROC
:
: REM Vertices
DATA -64.0,  64.0, -64.0
DATA  64.0,  64.0, -64.0
DATA  64.0, -64.0, -64.0
DATA -64.0, -64.0, -64.0
DATA -64.0,  64.0,  64.0
DATA  64.0,  64.0,  64.0
DATA  64.0, -64.0,  64.0
DATA -64.0, -64.0,  64.0
:
: REM Faces
DATA 0, 1, 2, 3
DATA 1, 5, 6, 2
DATA 5, 4, 7, 6
DATA 4, 0, 3, 7
DATA 0, 4, 5, 1
DATA 2, 3, 7, 6
:
: REM Normals
DATA  0.0,  0.0, -1.0
DATA  1.0,  0.0,  0.0
DATA  0.0,  0.0,  1.0
DATA -1.0,  0.0,  0.0
DATA  0.0,  1.0,  0.0
DATA  0.0  -1.0,  0.0
:
DEF PROCrotate_verts(N%, in_verts, out_verts, matrix)
FOR I%=0 TO N%-1
A%=matrix:B%=in_verts+I%*vec_size:C%=out_verts+I%*vec_size
:REM PROCprintf_vec(STR$(I%),B%)
CALL matrix_multiply_vector
:REM PROCprintf_vec("rot",C%):PRINT
NEXT
ENDPROC
:
DEF PROCplot_verts(N%, verts)
FOR I%=0 TO N%-1
vp=verts+I%*vec_size
:REM PROCprintf_vec(STR$(I%),vp)
x=FNfp_to_float(vp!0)+ox:y=FNfp_to_float(vp!4)+oy:z=FNfp_to_float(vp!8)+oz
A%=FNfloat_to_fp(x-cx):B%=FNfloat_to_fp(z-cz):dx=FNfp_to_float(USR(divide))
A%=FNfloat_to_fp(y-cy):B%=FNfloat_to_fp(z-cz):dy=FNfp_to_float(USR(divide))
: REM Project to screen
:REM sx = vp_centre_x + vp_scale * (x-cx) / (z-cz)
:REM sy = vp_centre_y + vp_scale * (y-cy) / (z-cz)
sx = vp_centre_x + vp_scale * dx
sy = vp_centre_y + vp_scale * dy
PLOT 69, sx*vdu_scale, sy*vdu_scale
NEXT
ENDPROC

DEF PROCplot_edges(N%, verts, M%, faces)
DIM sx N%*4, sy N%*4
: REM Project all verts
FOR I%=0 TO N%-1
vp=verts+I%*vec_size
:REM PROCprintf_vec(STR$(I%),vp)
x=FNfp_to_float(vp!0)+ox:y=FNfp_to_float(vp!4)+oy:z=FNfp_to_float(vp!8)+oz
A%=FNfloat_to_fp(x-cx):B%=FNfloat_to_fp(z-cz):dx=FNfp_to_float(USR(divide))
A%=FNfloat_to_fp(y-cy):B%=FNfloat_to_fp(z-cz):dy=FNfp_to_float(USR(divide))
: REM Project to screen
:REM sx = vp_centre_x + vp_scale * (x-cx) / (z-cz)
:REM sy = vp_centre_y + vp_scale * (y-cy) / (z-cz)
sx!(I%*4) = FNfloat_to_fp(vp_centre_x + vp_scale * dx)
sy!(I%*4) = FNfloat_to_fp(vp_centre_y + vp_scale * dy)
NEXT

FOR face=0 TO M%-1
fp=faces+face*4
FOR edge=0 TO 3
v1i=fp?edge
v2i=fp?((edge+1)MOD4)

MOVE FNfp_to_float(sx!(v1i*4))*vdu_scale, FNfp_to_float(sy!(v1i*4)*vdu_scale)
DRAW FNfp_to_float(sx!(v2i*4))*vdu_scale, FNfp_to_float(sy!(v2i*4)*vdu_scale)
NEXT
NEXT
ENDPROC
