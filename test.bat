@echo off

echo Start build...
if EXIST build del /Q build\*.*
if NOT EXIST build mkdir build

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\test.txt -m250 -Fbin -opt-adr -o build\code-library.bin code-library.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to assemble code.
	exit /b 1
)

echo Tokenising BASIC...
bin\beebasm.exe -i basic\basic_files.asm -do build\basic_files.ssd

if %ERRORLEVEL% neq 0 (
	echo Failed to tokenise BASIC.
	exit /b 1
)

echo Extracting BASIC files...
bin\bbcim -e build\basic_files.ssd utest
bin\bbcim -e build\basic_files.ssd ctest

echo Making !folder...
set FOLDER="!Test"
if EXIST %FOLDER% del /Q "%FOLDER%"
if NOT EXIST %FOLDER% mkdir %FOLDER%

echo Adding files...
copy test\*.* "%FOLDER%\*.*"
copy build\code-library.bin "%FOLDER%\CodeLib,ff8"
copy build\basic_files.ssd.$.ctest "%FOLDER%\!RunImage,ffb"
copy build\basic_files.ssd.$.utest "%FOLDER%\UnitTest,ffb"

echo Copying !folder...
set HOSTFS=..\..\Arculator_V2.1_Windows\hostfs
if EXIST "%HOSTFS%\%FOLDER%" del /Q "%HOSTFS%\%FOLDER%"
if NOT EXIST "%HOSTFS%\%FOLDER%" mkdir "%HOSTFS%\%FOLDER%"
copy "%FOLDER%\*.*" "%HOSTFS%\%FOLDER%"
