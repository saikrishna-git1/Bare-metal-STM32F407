#variable. Instead of using arm-none-eabi-gcc everytime, I can use just the var name.
CC=arm-none-eabi-gcc
#CC="C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\bin\arm-none-eabi-gcc" 
MCPU=cortex-m4
#compiler flags/options - min. 3 flags 
CFLAGS= -c -mcpu=$(MCPU) -mthumb -std=gnu11 -Wall -O0 
LDFLAGS= -nostdlib -T STM32F4VGTx_v2.ld -Wl,-Map=final.map

all: main.o led.o startup_STM32F4VGTx.o final.elf

clean: 
	rm -rf *.o *.elf	


#Target: Dependencies
#	Recepie(command)
main.o: main.c
#	$(CC) $(CFLAGS) main.c -o main.o #	$^ - dependencies, $@ - target
	$(CC) $(CFLAGS) $^ -o $@ 
	
led.o: led.c
	$(CC) $(CFLAGS) $^ -o $@
	
startup_STM32F4VGTx.o: startup_STM32F4VGTx.c
	$(CC) $(CFLAGS) $^ -o $@
	
final.elf: main.o led.o startup_STM32F4VGTx.o
	$(CC) $(LDFLAGS) $^ -o $@

load:
	openocd -f board/stm32f4discovery.cfg