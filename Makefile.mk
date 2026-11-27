##########################################################################
# TIPSY CUBE MAKEFILE
# Run with bin\snmake.exe via make.bat (Windows, cmd.exe).
##########################################################################

RM_RF:=-cmd /c rd /s /q
MKDIR_P:=-cmd /c mkdir
COPY:=copy
VASM?=bin\vasmarm_std_win32.exe
VLINK?=bin\vlink.exe
SHRINKLER?=bin\Shrinkler.exe
PYTHON3?=python.exe

FOLDER=!Tipsy
HOSTFS?=..\arculator\hostfs\Builds

##########################################################################
# RELEASE BUILD (default)
# !Tipsy: the loader as !RunImage and the Shrinkler-packed demo as Demo.
##########################################################################

.PHONY:release
release: build ./build/loader.bin ./build/tipsy-cube.shri
	$(RM_RF) $(FOLDER)
	$(MKDIR_P) $(FOLDER)
	$(COPY) .\folder\*.* "$(FOLDER)\*.*"
	$(COPY) .\build\loader.bin "$(FOLDER)\!RunImage,ff8"
	$(COPY) .\build\tipsy-cube.shri "$(FOLDER)\Demo,ffd"

# Same build assembled with _DEBUG=1.
.PHONY:debug
debug: VASM_FLAGS=-D_DEBUG=1
debug: release

# Copy the built folder to an Arculator hostfs (override HOSTFS=... as needed).
.PHONY:deploy
deploy:
	$(RM_RF) "$(HOSTFS)\$(FOLDER)"
	$(MKDIR_P) "$(HOSTFS)\$(FOLDER)"
	$(COPY) "$(FOLDER)\*.*" "$(HOSTFS)\$(FOLDER)\*.*"

build:
	$(MKDIR_P) "./build"

.PHONY:clean
clean:
	$(RM_RF) "build"
	$(RM_RF) "$(FOLDER)"

##########################################################################
# CODE
##########################################################################

./build/loader.bin: build lib/loader.asm lib/arc-shrinkler.asm
	$(VASM) -L build\loader.txt -m250 -Fbin -opt-adr -o $@ lib\loader.asm

./build/tipsy-cube.shri: ./build/tipsy-cube.bin
	$(SHRINKLER) -d -b -p -z build\tipsy-cube.bin build\tipsy-cube.shri

./build/tipsy-cube.bin: build ./build/tipsy-cube.o link_script.txt
	$(VLINK) -T link_script.txt -b rawbin1 -o $@ build\tipsy-cube.o -Mbuild\linker.txt

.PHONY:./build/tipsy-cube.o	# always build as source dependencies aren't tracked.
./build/tipsy-cube.o: build tipsy-cube.asm ./build/sine_8192.bin ./build/font.bin
	$(VASM) -L build\compile.txt -m250 -Fvobj -opt-adr $(VASM_FLAGS) -o $@ tipsy-cube.asm

##########################################################################
# TABLES AND ASSETS
##########################################################################

./build/sine_8192.bin: ./bin/sine_table.py | build
	$(PYTHON3) bin\sine_table.py 8192 65536 -o $@

./build/font.bin: ./data/gfx/Fine.png ./bin/png2arc_font.py ./bin/arc.py ./bin/png.py | build
	$(PYTHON3) bin\png2arc_font.py -o $@ --glyph-dim 8 8 --max-glyphs 96 data\gfx\Fine.png 9
