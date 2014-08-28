default: calculator

clean:
	rm -rf .b/

.b/main.o: main.asm graphics.dat
	mkdir -p .b/
	ca65 main.asm -o .b/main.o

.b/convert_decimal.o: convert_decimal.asm
	mkdir -p .b/
	ca65 convert_decimal.asm -o .b/convert_decimal.o

.b/chr.o: chr.asm chr.dat
	mkdir -p .b/
	ca65 chr.asm -o .b/chr.o

calculator: .b/main.o .b/convert_decimal.o .b/chr.o
	ld65 .b/main.o .b/convert_decimal.o .b/chr.o -o calculator.nes -C nes_nrom.cfg
