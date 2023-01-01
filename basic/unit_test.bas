MODE 0
precision=65536
err_delta=1/256
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
PROCtest_multiply_matrices
REPEAT UNTIL GET
PROCtest_multiply_vectors
REPEAT UNTIL GET
PROCtest_make_matrices
REPEAT UNTIL GET
PROCtest_sine
REPEAT UNTIL GET
PROCtest_vector_dot_product
END
:
DEF PROCtest_vector_dot_product
CLS:PRINT"Running dot product tests."
num_dp_tests=18:data_dp_tests=60
:
DIM vec1 12, vec2 12
RESTORE data_dp_tests
failed=0
FOR I%=1 TO num_dp_tests
READ a,b,c,d,e,f
PROCmake_vec(vec1, a, b, c):PROCprintf_vec("vec1",vec1)
PROCmake_vec(vec2, d, e, f):PROCprintf_vec("vec2",vec2)
result=FNfp_to_float(FNvector_dot_product(vec1, vec2))
verify=FNtest_vector_dot_product(vec1, vec2)
error=ABS(verify-result)
PRINT ;"dot product=";result;" verify=";verify;" ";
IF error<err_delta PRINT "PASS" ELSE PRINT "FAIL error=";error:failed=failed+1
NEXT
PRINT (num_dp_tests-failed);"/";num_dp_tests;" tests PASSED."
ENDPROC
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
DEF FNvector_dot_product(B%, C%)
=USR(vector_dot_product)
DEF FNtest_vector_dot_product(B%, C%)
a=FNfp_to_float(B%!0):b=FNfp_to_float(B%!4):c=FNfp_to_float(B%!8)
d=FNfp_to_float(C%!0):e=FNfp_to_float(C%!4):f=FNfp_to_float(C%!8)
=a*d+b*e+c*f
:
: REM Unit vectors.
DATA 3.0, 4.0, 5.0,  1.0, 0.0, 0.0
DATA 3.0, 4.0, 5.0,  0.0, 1.0, 0.0
DATA 3.0, 4.0, 5.0,  0.0, 0.0, 1.0
: REM Zero vectors.
DATA 3.0, 4.0, 5.0,  0.0, 0.0, 0.0
DATA 0.0, 0.0, 0.0,  100.0, 200.0, 300.0
: REM Orthogonal vectors.
DATA 10.0, 0.0, 0.0,  0.0, 20.0, 0.0
DATA 0.0, 20.0, 0.0,  0.0, 0.0, 30.0
DATA 0.0, 0.0, 30.0,  10.0, 0.0, 0.0
: REM Negative vectors.
DATA 10.0, 0.0, 0.0,  -1.0, 0.0, 0.0
DATA 100.0, 200.0, 300.0,  -1.0, -1.0, -1.0
DATA 100.0, 200.0, 300.0,  -1.0, -1.0, 1.0
DATA -100.0, -200.0, -300.0,  -1.0, -1.0, -1.0
: REM Precision tests.
DATA 255.9, 0.0, 0.0,  1.0, 0.0, 0.0
DATA 0.0, 255.9, 0.0,  0.0, -1.0, 0.0
DATA 0.0, 0.0, -256,    0.0, 0.0, 1.0
DATA -256.0, 0.0, 0.0,  -1.0, 0.0, 0.0
DATA 50.0, 100.0, 200.0, 0.1, 0.2, 0.3
DATA -200.0, 100.0, -500.0,  0.99, -0.99, 0.99
:
DEF PROCtest_sine
CLS
failed=0
FOR degs=0 TO 360 STEP 10
rad=degs/360:verify_cos=COS(RAD(degs)):verify_sin=SIN(RAD(degs))
A%=FNfloat_to_fp(rad)
s=FNfp_to_float(USR(sine)):c=FNfp_to_float(USR(cosine))
PRINT "deg=";degs;" rad=";rad;" rad_fp=";A%;" s=";s;" c=";c;" sin=";verify_sin;" cos=";verify_cos;" ";
error=ABS(s-verify_sin)
IF error<err_delta PRINT "PASS" ELSE PRINT "FAIL error=";error:failed=failed+1
NEXT
PRINT failed;" tests FAILED."
ENDPROC
:
DEF PROCmake_matrix(mat,a,b,c,d,e,f,g,h,i)
mat!0=FNfloat_to_fp(a):mat!4=FNfloat_to_fp(b):mat!8=FNfloat_to_fp(c)
mat!12=FNfloat_to_fp(d):mat!16=FNfloat_to_fp(e):mat!20=FNfloat_to_fp(f)
mat!24=FNfloat_to_fp(g):mat!28=FNfloat_to_fp(h):mat!32=FNfloat_to_fp(i)
ENDPROC
DEF PROCprintx_matrix(mat)
PRINT "[";~mat!0;",";~mat!4;",";~mat!8;"]"
PRINT "[";~mat!12;",";~mat!16;",";~mat!20;"]"
PRINT "[";~mat!24;",";~mat!28;",";~mat!32;"]"
ENDPROC
DEF PROCprintf_matrix(mat)
PRINT "[";FNfp_to_float(mat!0);",";FNfp_to_float(mat!4);",";FNfp_to_float(mat!8);"]"
PRINT "[";FNfp_to_float(mat!12);",";FNfp_to_float(mat!16);",";FNfp_to_float(mat!20);"]"
PRINT "[";FNfp_to_float(mat!24);",";FNfp_to_float(mat!28);",";FNfp_to_float(mat!32);"]"
ENDPROC
:
DEF PROCmultiply_vector(mat,vec,res)
a=FNfp_to_float(mat!0):b=FNfp_to_float(mat!4):c=FNfp_to_float(mat!8)
d=FNfp_to_float(mat!12):e=FNfp_to_float(mat!16):f=FNfp_to_float(mat!20)
g=FNfp_to_float(mat!24):h=FNfp_to_float(mat!28):i=FNfp_to_float(mat!32)
x=FNfp_to_float(vec!0):y=FNfp_to_float(vec!4):z=FNfp_to_float(vec!8)
res!0=FNfloat_to_fp(a*x + b*y + c*z)
res!4=FNfloat_to_fp(d*x + e*y + f*z)
res!8=FNfloat_to_fp(g*x + h*y + i*z)
ENDPROC
:
DEF PROCmultiply_matrix(mat1,mat1,matR)
a1=FNfp_to_float(mat1!0):b1=FNfp_to_float(mat1!4):c1=FNfp_to_float(mat1!8)
d1=FNfp_to_float(mat1!12):e1=FNfp_to_float(mat1!16):f1=FNfp_to_float(mat1!20)
g1=FNfp_to_float(mat1!24):h1=FNfp_to_float(mat1!28):i1=FNfp_to_float(mat1!32)

a2=FNfp_to_float(mat2!0):b2=FNfp_to_float(mat2!4):c2=FNfp_to_float(mat2!8)
d2=FNfp_to_float(mat2!12):e2=FNfp_to_float(mat2!16):f2=FNfp_to_float(mat2!20)
g2=FNfp_to_float(mat2!24):h2=FNfp_to_float(mat2!28):i2=FNfp_to_float(mat2!32)

matR!0=FNfloat_to_fp(a1*a2 + b1*d2 + c1*g2)
matR!4=FNfloat_to_fp(a1*b2 + b1*e2 + c1*h2)
matR!8=FNfloat_to_fp(a1*c2 + b1*f2 + c1*i2)
matR!12=FNfloat_to_fp(d1*a2 + e1*d2 + f1*g2)
matR!16=FNfloat_to_fp(d1*b2 + e1*e2 + f1*h2)
matR!20=FNfloat_to_fp(d1*c2 + e1*f2 + f1*i2)
matR!24=FNfloat_to_fp(g1*a2 + h1*d2 + i1*g2)
matR!28=FNfloat_to_fp(g1*b2 + h1*e2 + i1*h2)
matR!32=FNfloat_to_fp(g1*c2 + h1*f2 + i1*i2)
ENDPROC
:
DEF PROCtest_make(name$,A%,C%,func)
PRINT name$;" with R0=";FNfp_to_float(A%)
CALL func
PROCprintf_matrix(C%)
ENDPROC

DEF PROCtest_make_matrices
CLS
DIM matrix 36
PROCtest_make("rotate_x", FNfloat_to_fp(0), matrix, make_rotate_x)
PROCtest_make("rotate_x", FNfloat_to_fp(32), matrix, make_rotate_x)
PROCtest_make("rotate_x", FNfloat_to_fp(64), matrix, make_rotate_x)
PROCtest_make("rotate_x", FNfloat_to_fp(128), matrix, make_rotate_x)
PROCtest_make("rotate_x", FNfloat_to_fp(192), matrix, make_rotate_x)
REPEAT UNTIL GET
CLS
PROCtest_make("rotate_x", FNfloat_to_fp(0), matrix, make_rotate_y)
PROCtest_make("rotate_y", FNfloat_to_fp(32), matrix, make_rotate_y)
PROCtest_make("rotate_y", FNfloat_to_fp(64), matrix, make_rotate_y)
PROCtest_make("rotate_y", FNfloat_to_fp(128), matrix, make_rotate_y)
PROCtest_make("rotate_y", FNfloat_to_fp(192), matrix, make_rotate_y)
REPEAT UNTIL GET
CLS
PROCtest_make("rotate_z", FNfloat_to_fp(0), matrix, make_rotate_z)
PROCtest_make("rotate_z", FNfloat_to_fp(32), matrix, make_rotate_z)
PROCtest_make("rotate_z", FNfloat_to_fp(64), matrix, make_rotate_z)
PROCtest_make("rotate_z", FNfloat_to_fp(128), matrix, make_rotate_z)
PROCtest_make("rotate_z", FNfloat_to_fp(192), matrix, make_rotate_z)
ENDPROC
:
DEF PROCtest_multiply_vector(A%,x,y,z)
DIM vec 12, res 12, ver 12
PROCmake_vec(vec, x, y, z)
PROCmultiply_vector(A%,vec,ver)
B%=vec:C%=res:CALL matrix_multiply_vector
PROCprintf_vec("A:",vec):PROCprintf_vec("B:",res):PROCprintf_vec("C:",ver):PRINT
ENDPROC
:
DEF PROCtest_multiply_vectors
CLS
DIM matrix 36
PROCtest_make("rotate_x", FNfloat_to_fp(64), matrix, make_rotate_x)
PROCtest_multiply_vector(matrix, 1,0,0)
PROCtest_multiply_vector(matrix, 0,1,0)
PROCtest_multiply_vector(matrix, 0,0,1)
PROCtest_multiply_vector(matrix, 0,0,0)
PROCtest_multiply_vector(matrix, -1,0,0)
PROCtest_multiply_vector(matrix, 0,-1,0)
PROCtest_multiply_vector(matrix, 0,0,-1)
PROCtest_multiply_vector(matrix, 0.5,0.5,0.5)
PROCtest_multiply_vector(matrix, 0,10,-10)
REPEAT UNTIL GET
CLS
PROCtest_make("rotate_x", FNfloat_to_fp(-32), matrix, make_rotate_x)
PROCtest_multiply_vector(matrix, 1,0,0)
PROCtest_multiply_vector(matrix, 0,1,0)
PROCtest_multiply_vector(matrix, 0,0,1)
PROCtest_multiply_vector(matrix, 0,0,0)
PROCtest_multiply_vector(matrix, -1,0,0)
PROCtest_multiply_vector(matrix, 0,-1,0)
PROCtest_multiply_vector(matrix, 0,0,-1)
PROCtest_multiply_vector(matrix, 0.5,0.5,0.5)
PROCtest_multiply_vector(matrix, 0,10,-10)
REPEAT UNTIL GET
CLS
PROCtest_make("rotate_y", FNfloat_to_fp(-64), matrix, make_rotate_y)
PROCtest_multiply_vector(matrix, 1,0,0)
PROCtest_multiply_vector(matrix, 0,1,0)
PROCtest_multiply_vector(matrix, 0,0,1)
PROCtest_multiply_vector(matrix, 0,0,0)
PROCtest_multiply_vector(matrix, -1,0,0)
PROCtest_multiply_vector(matrix, 0,-1,0)
PROCtest_multiply_vector(matrix, 0,0,-1)
PROCtest_multiply_vector(matrix, 0.5,0.5,0.5)
PROCtest_multiply_vector(matrix, 0,10,-10)
REPEAT UNTIL GET
CLS
PROCtest_make("rotate_y", FNfloat_to_fp(128), matrix, make_rotate_y)
PROCtest_multiply_vector(matrix, 1,0,0)
PROCtest_multiply_vector(matrix, 0,1,0)
PROCtest_multiply_vector(matrix, 0,0,1)
PROCtest_multiply_vector(matrix, 0,0,0)
PROCtest_multiply_vector(matrix, -1,0,0)
PROCtest_multiply_vector(matrix, 0,-1,0)
PROCtest_multiply_vector(matrix, 0,0,-1)
PROCtest_multiply_vector(matrix, 0.5,0.5,0.5)
PROCtest_multiply_vector(matrix, 0,10,-10)
REPEAT UNTIL GET
CLS
PROCtest_make("rotate_z", FNfloat_to_fp(32), matrix, make_rotate_z)
PROCtest_multiply_vector(matrix, 1,0,0)
PROCtest_multiply_vector(matrix, 0,1,0)
PROCtest_multiply_vector(matrix, 0,0,1)
PROCtest_multiply_vector(matrix, 0,0,0)
PROCtest_multiply_vector(matrix, -1,0,0)
PROCtest_multiply_vector(matrix, 0,-1,0)
PROCtest_multiply_vector(matrix, 0,0,-1)
PROCtest_multiply_vector(matrix, 0.5,0.5,0.5)
PROCtest_multiply_vector(matrix, 0,10,-10)
REPEAT UNTIL GET
CLS
PROCtest_make("rotate_z", FNfloat_to_fp(64), matrix, make_rotate_z)
PROCtest_multiply_vector(matrix, 1,0,0)
PROCtest_multiply_vector(matrix, 0,1,0)
PROCtest_multiply_vector(matrix, 0,0,1)
PROCtest_multiply_vector(matrix, 0,0,0)
PROCtest_multiply_vector(matrix, -1,0,0)
PROCtest_multiply_vector(matrix, 0,-1,0)
PROCtest_multiply_vector(matrix, 0,0,-1)
PROCtest_multiply_vector(matrix, 0.5,0.5,0.5)
PROCtest_multiply_vector(matrix, 0,10,-10)
ENDPROC
:
DEF PROCtest_multiply_matrices
CLS
DIM matrixA 36, matrixB 36, matrixC 36
PROCtest_make("identity", 0, matrixA, make_identity)
PROCmake_matrix(matrixB, 1,2,3,4,5,6,7,8,9)
PRINT"B=":PROCprintf_matrix(matrixB)
A%=matrixA:B%=matrixB:C%=matrixC:CALL matrix_multiply
PROCmake_matrix(matrixA, -1,0,0, 0,-1,0, 0,0,-1)
PRINT"A=":PROCprintf_matrix(matrixA)
A%=matrixA:B%=matrixB:C%=matrixC:CALL matrix_multiply
PRINT"A*B=":PROCprintf_matrix(matrixC)
PROCmake_matrix(matrixA, 1,1,1, 0,0,0, 0,0,0)
PRINT"A=":PROCprintf_matrix(matrixA)
A%=matrixA:B%=matrixB:C%=matrixC:CALL matrix_multiply
PRINT"A*B=":PROCprintf_matrix(matrixC)
REPEAT UNTIL GET
CLS
PROCmake_matrix(matrixA, 0,0,0, 1,1,1, 0,0,0)
PRINT"A=":PROCprintf_matrix(matrixA)
A%=matrixA:B%=matrixB:C%=matrixC:CALL matrix_multiply
PRINT"A*B=":PROCprintf_matrix(matrixC)
PROCmake_matrix(matrixA, 0,0,0, 0,0,0, 1,1,1)
PRINT"A=":PROCprintf_matrix(matrixA)
A%=matrixA:B%=matrixB:C%=matrixC:CALL matrix_multiply
PRINT"A*B=":PROCprintf_matrix(matrixC)
PROCtest_make("rotate_x", FNfloat_to_fp(-45), matrixB, make_rotate_x)
A%=matrixA:B%=matrixB:C%=matrixC:CALL matrix_multiply
PRINT"A*B=":PROCprintf_matrix(matrixC)
A%=matrixB:B%=matrixA:C%=matrixC:CALL matrix_multiply
PRINT"B*A=":PROCprintf_matrix(matrixC)
PROCtest_make("rotate_y", FNfloat_to_fp(90), matrixA, make_rotate_y)
A%=matrixA:B%=matrixB:C%=matrixC:CALL matrix_multiply
PRINT"A*B=":PROCprintf_matrix(matrixC)
ENDPROC
