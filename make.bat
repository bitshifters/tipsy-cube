@echo off

echo Start build...
if EXIST build del /Q build\*.*
if NOT EXIST build mkdir build

echo Making assets..
call make_assets.bat

if %ERRORLEVEL% neq 0 (
	echo Failed to make  code.
	exit /b 1
)

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\compile.txt -m250 -Fvobj -opt-adr -o build\tipsy-cube.o tipsy-cube.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to assemble code.
	exit /b 1
)

echo Linking code...
bin\vlink.exe -T link_script.txt -b rawbin1 -o build\tipsy-cube.bin build\tipsy-cube.o -Mbuild\linker.txt

if %ERRORLEVEL% neq 0 (
	echo Failed to link code.
	exit /b 1
)

echo Assembling loader...
bin\vasmarm_std_win32.exe -L build\loader.txt -m250 -Fbin -opt-adr -o build\loader.bin lib\loader.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to assemble code.
	exit /b 1
)

echo Compressing exe...
rem bin\lz4.exe -f build\proto-arc.bin build\proto-arc.lz4
bin\Shrinkler.exe -d -b -p -z build\tipsy-cube.bin build\tipsy-cube.shri

echo Making !folder...
set FOLDER="!Tipsy"
if EXIST %FOLDER% del /Q "%FOLDER%"
if NOT EXIST %FOLDER% mkdir %FOLDER%

echo Adding files...
copy folder\*.* "%FOLDER%\*.*"
copy build\loader.bin "%FOLDER%\!RunImage,ff8"
copy build\tipsy-cube.shri "%FOLDER%\Demo,ffd"

echo Copying !folder...
set HOSTFS=..\arculator\hostfs
if EXIST "%HOSTFS%\%FOLDER%" del /Q "%HOSTFS%\%FOLDER%"
if NOT EXIST "%HOSTFS%\%FOLDER%" mkdir "%HOSTFS%\%FOLDER%"
copy "%FOLDER%\*.*" "%HOSTFS%\%FOLDER%"
