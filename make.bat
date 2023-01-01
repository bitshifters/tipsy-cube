@echo off

echo Start build...
if EXIST build del /Q build\*.*
if NOT EXIST build mkdir build

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\compile.txt -m250 -Fbin -opt-adr -o build\proto-arc.bin proto-arc.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to assemble code.
	exit /b 1
)

echo Making !folder...
set FOLDER="!Tipsy"
if EXIST %FOLDER% del /Q "%FOLDER%"
if NOT EXIST %FOLDER% mkdir %FOLDER%

echo Adding files...
copy folder\*.* "%FOLDER%\*.*"
copy build\proto-arc.bin "%FOLDER%\!RunImage,ff8"
copy "data\music\arcchoon.mod" "%FOLDER%\Music,001"

echo Copying !folder...
set HOSTFS=..\arculator\hostfs
if EXIST "%HOSTFS%\%FOLDER%" del /Q "%HOSTFS%\%FOLDER%"
if NOT EXIST "%HOSTFS%\%FOLDER%" mkdir "%HOSTFS%\%FOLDER%"
copy "%FOLDER%\*.*" "%HOSTFS%\%FOLDER%"
