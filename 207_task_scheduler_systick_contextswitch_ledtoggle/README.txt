1. Intro
---------------------------------------------------
Toolchain - collection of binaries that allow you to compile/assemble, link your source code files. Also provides C std. libs.
Also contains binaries to debug your application on the target.
Also contains binaries to analyze the executable:
1. Dissect different sections of the executable.
2. Disassemble.
3. Extract symbol and size info.
4. Convert executable in one format to another.


2. Popular toolchains
---------------------------------------------------
GCC, armcc


3. GCC cross toolchain imp libs for ARM target
---------------------------------------------------
compiler/assembler, linker	-	arm-none-eabi-gcc		
invoke linker explicitly    -   arm-none-eabi-ld
invoke assembler explicitly -   arm-none-eabi-as
NOTE: 
arm-none-eabi - 		 This tool chain targets for ARM architecture, has no vendor, does not target an operating system and complies with the ARM EABI. 
arm-none-linux-gnueabi - This toolchain targets the ARM architecture, has no vendor, creates binaries that run on the Linux operating system, and uses the GNU EABI.


4. final executable file (.elf) analyzers
---------------------------------------------------
arm-none-eabi-objdump
arm-none-eabi-readelf
arm-none-eabi-nm


5. executable file format converter
---------------------------------------------------
arm-none-eabi-objcopy


////////////////////////////////////////////////////////
BUILD PROCESS
////////////////////////////////////////////////////////
1. Pre-processing: .c -> .i
2. Code gen / compiler proper (compilation): .i -> .s
3. Assembler (compilation): .s -> .o (relocatable object file - machine code file. No absolute addresses for data and code)
4. Linker: .o, .a(std/3rd party lib) -> .elf (executable and linkable format - final execultable)
5. objcopy tool - .elf -> .bin/.hex

In gcc, all the above steps are performed using only one cmd - arm-none-eabi-gcc.

If you don't mention the p. arch. explicitly, inline asm instr. may not be recognized by the assembler.

Command to compile and produce a relocatable obj file:
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c main.c -o main.o

Command to compile and produce an assembly file:
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -S main.c -o main.s



/////////////////////////////////////////////////////////
Makefile
/////////////////////////////////////////////////////////
(see Makefile)
/////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////
Analyzing .o files (relocatable object files)
/////////////////////////////////////////////////////////
main.o is in .elf format (executable and linkable format)
.elf is the standard file format for obj files and executable files when you use GCC toolchain.
A file format describes the way of organizing various elements of a program in different sections (data, RO data, uinit data, etc.).

Command to analyze .o files:
arm-none-eabi-objdump.exe 

Example:
arm-none-eabi-objdump.exe -h main.o (we can control the following 4 sections: .text, .data, .bss, .rodata. We can also add user-defined sections).

arm-none-eabi-objdump.exe -d main.o


Sections of an .elf format file:
-----------------------------------------------------------------
.text - RO - stores all the instr. opcodes (the actual code) - Flash
.data, .bss, .rodata contain only data. They don't contain any instr. The disassembler tries to map those data to some instruction. That's why we see instructions in the disassembly file.
.data - RW init data - RAM
.bss - RW uinit data - RAM
.rodata - RO_data - Flash
.comment, .attributes sections are added by the compiler - Flash
user-defined sections - Flash/RAM

-----------------------------------------------------------------
Why is it called relocatable obj file? - Observe the disassembly file - Addr of fn + offset for every instr. of that fn.
The address of each fucntion is relocatable, it is not an absolute addr. (in our uc, code space starts from 0x2000_0000, not from 0x0) - you should assign the appropriate relocatable addr. here using the linker script and relocate these sections.

Addresses of (the first fns in) all sections in all obj files start from 0x0. But this won't cause any conflict as they are just dummy addr.


-----------------------------------------------------------------
What exactly is a program?
A program is a collection of code(instr.) and data - code operates on data.
Code is stored in Flash, RW_data is stored in RAM and RO_data is stored in Flash.
/////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////
Linker and locator: merging diff sections and addr relocation
/////////////////////////////////////////////////////////////////
All obj files have their own .text, .data, .bss, .rodata, etc sections. Now, you have to use linker to merge these sections and create a single executable.
Use linker to merge similar sections of diff obj files and to resolve all undef symbols of diff obj files.

Locator is part of linker - takes help of the linker script to understand how you wish to merge diff sections and assigns mentioned absolute addr. to diff merged sections.

Sections of final executable final.elf:
-----------------------------------------------------------------
.text -> .text(main.o) + .text(led.o)
.data -> .data(main.o) + .data(led.o)
.bss -> .bss(main.o) + .bss(led.o)
.rodata -> .rodata(main.o) + .rodata(led.o)



////////////////////////////////////////////////////////////////
Storage of final executable in code memory (Flash)
////////////////////////////////////////////////////////////////
-----------------------------------------------
	Unused code memory
	
	.data (init global and static variables)
	
	.rodata
	
	.text
	
	Vector table
-----------------------------------------------	

Earlier, it was said that .data section vars are RW vars. Then how is it possible to store them in Flash?
That's the reason you should copy/relocate this section to RAM - using startup (.s) file. 
Before calling application's main(), the C-startup code must run and should:
----------------------------------------------------------------------------
1. Copy the .data section from Flash to initial addr. of RAM (.data section has 2 addr: LMA, VMA. Used in linker script)
2. Reserve some space for .bss section and init it to 0
3. Initialize the SP 
4. Call main() -> bl main


In order to copy .data section from Flash to RAM, startup code needs some symbols to hold the starting address and size of these sections to determine the section boundaries.	
////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////
Different types of data(vars) of a program - see TB for program memory layout in Flash and SRAM
////////////////////////////////////////////////////////////////
Global vars initialized with 0: by default in .bss
----------------------------------------------------------------
Compiler is free to put such variable into .bss as well as into .data For example, GCC has a special option controlling such behavior:
-fno-zero-initialized-in-bss

If the target supports a BSS section, GCC by default puts variables that are initialized to zero into BSS. This can save space in the resulting code. This option turns off this behavior because some programs explicitly rely on variables going to the data section. E.g., so that the resulting executable can find the beginning of that section and/or make assumptions based on that.
The default is -fzero-initialized-in-bss.
----------------------------------------------------------------

2 broad types: global, local
1. Global init data - .data in Flash(LMA) -> VMA(relocated addr): .data in RAM - copied from Flash to RAM by startup code.
2. Global uninit data - .bss in RAM - Uinitialized global vars don't carry any important data - no point in storing them in .data section in Flash and again copying them to RAM using startup code.
3. Global init static data - .data - global private data to the src file where it is defined.
4. Global uninit static data - .bss 

5,6. Local init/uninit  - stack(created and destroyed dynamically), not in any section - local var of a fn
7. Local init static data - .data - it is like a global var but private to a fn
8. Local uninit static data - .bss 

9. Global const data - .rodata(Flash)
10. Local const data - stack - treated as local vars to a fn

For local initialized data(vars):
----------------------------------------------------------------
Vriables will get created in stack dynamically (when the fn is called), but the constants (values to which the vars are init) are stored in Flash.
So when the fn is called, the var will be created in RAM and will be init by reading the data from Flash.
----------------------------------------------------------------
////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////
.bss section
////////////////////////////////////////////////////////////////
.bss section doesn't consume any Flash space, hence no LMA.
Startup code must reserve RAM space for .bss section by knowing its size and init it to 0.
Linker script symbols help you determine the final size of .bss section.
////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////
Startup file of a uc
////////////////////////////////////////////////////////////////
Startup(.s) file is responsible for setting up the right environment for the main user code to run.
Code written in startup file runs before main(). It actually calls main() -> bl main
Some part of the startup code is target(p.) dependent - vector table, accessing & init SP, enable FPU or other peri which might be needed by tha application code from the very beginning.
It takes care of vector table placement in code memory as required by the p.
It is also possible to do stack reinitialization - change the stack placement.
It is also responsible for init .data, .bss sections in main memory - SRAM (copying .data sec from Flash to SRAM, init .bss section to all 0) and then call the main()



Writing startup file of uc from scratch in C
----------------------------------------------------------------
We need to 3 imp things:
1. Create vector table for your uc
2. Write startup code which init .data and .bss sections in SRAM
3. Call main()



1. Create VT for your uc
----------------------------------------------------------------
Total memory consumed by VT = 98 words (1 init value of MSP + 15 system exceptions + 82 IRQs)	
= 98*4 = 392 Bytes

Create an array to hold MSP and handler addresses:	
	uint32_t vectors[] = {VT};
Instruct the compiler not to store the above array in .data section but in a user-defined section. By default compiler will store init data in .data section. 

It is a very tedious task to write handlers for all the system exceptions + IRQs. Instead, we can write a generic default handler and make it as an alias for all the exception handlers. For that you have to use GCC attributes 'weak' and 'alias'.
Weak: Lets programmer to override already defined weak(dummy) fn/ISR with the same fn name.
Alias: Lets programmer to give alias name for a fn/ISR.

Now, how to impl a real fn/ISR which handles NMI/HardFault exception? - That's done by the programmer.
Progammer has to override the fn in his src file and write the actual ISR code. 
So, in startup file, we have to make this fn name as 'weak'. This allows the programmer to override this fn with the same fn name in his application code with actual ISR impl.

* Provide weak aliases for each Exception handler to the Default_Handler. As they are weak aliases, any function with the same name will override this definition.



2. Write startup code which init .data and .bss sections in SRAM
---------------------------------------------------------------
Write this code in Reset_Handler, since this is the first fn which gets executed when the p. undergoes Reset.
Copy .data section from Flash to SRAM - for this, the startup script needs to know the boundaries of .data region present in linker script.
Init .bss section to 0 in SRAM
Call main()
////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////
Linker script of a uc
////////////////////////////////////////////////////////////////
Linker script is a text file which explains how different sections of the obj files should be merged to create an output file. It also includes code and data memory addr and size info.

Linker and locator combo assigns 'unique absolute addresses' to diff sections of the output file by referring to addr info mentioned in the linker script.

Linker scripts are written using GNU linker command language. GNU linker script has the file extension .ld
You must supply .ld script at the linking pphase to the linker using -T option.



Writing a linker script
----------------------------------------------------------------
To write a linker script, you have to first understand diff commands.

1. ENTRY - to set the 'Entry point address' in the header of final .elf generated.
----------------------------------------------------------------
Syntax: 
ENTRY(_symbol_name_) //fn name

Example:		
ENTRY(Reset_Handler)

In our case, Reset_Handler is the entry point into the application. It is the first piece of code that executes right after the p. resets. The debugger uses this info to locate the first fn to execute.
Not a mandatory command to use, but required when you debug the .elf file using GDB.



2. MEMORY - allows you to describe the different memories present in the target and their start addr and size info.
----------------------------------------------------------------
Syntax: 
MEMORY
{
	name(attr) : ORIGIN = origin, LENGTH = len 
}
//label : origin, len in bytes or lenK in KB
//label - defines name of the memory region which will be later referenced by other parts of the linker script.
//attr - (optional) defines attribute list of the memory region. Valid attributes list must be made up of the chars - ALIRWX! that match section attributes.

Example: uc-STM32F4VGT6, Flash size = 1024 KB = 1 MB, SRAM1 size = 112 KB, SRAM2 size = 16 KB
MEMORY 
{
	FLASH(rx) : ORIGIN=0x08000000, LENGTH=1024K
	SRAM1(rwx): ORIGIN=0x20000000, LENGTH=112K
	SRAM2(rwx): ORIGIN=0x20000000 + 112K - 4, LENGTH=16K
}

The linker uses info mentioned in this command to assign addresses to merged sections - relocation
The info given under this command also helps the linker to calc. total code and data memory consumed so far and throw an error message if data, code, heap or stack areas cannot fit into available size.
You can fine-tune various memories available in your target and allow diff sections to occupy diff memory areas.
Typically, one linker script has one memory command.



3. SECTIONS - to create diff output sections in the final executable .elf generated.
----------------------------------------------------------------
Imp command by which you can instruct the linker how to merge the input sections to yield an output section (see above - Linker and locator).
This command also controls the order in which diff output sections appear in the .elf file generated.
By using this command, you can also mention the placement of a section in a memory region. For ex: you instruct the linker to place the .text section in the FLASH memory region, which is described by the MEMORY command.

Syntax:
/*Here, this command is used to create 2 sections in the final .elf file gen*/
SECTIONS			
{
	.text:			/*This section should include .text section of all input files*/
	{
		//merge all .u_vector_table sections of all input files --- ?
		//merge all .text sections of all input files
		//merge all .rodata sections of all input files
	}> (FLASH)			/*section placement info in the memory using '>' symbol. Here no relocation*/

	
	
	.data:			/*This section should include .data section of all input files*/
	{
		//merge all .data sections of all input files
	}>(vma) AT>(lma)	
/*Once linker sees this, it also generates load addresses which fall in LMA region*/
/*After that, it generates absolute addresses for this section which fall in the VMA region*/	

}



Location counter (.) - <*_v2.ld>
----------------------------------------------------------------
This is a special linker symbol denoted by a dot '.'
This symbol is called location counter since linker auto updates this symbol with location(addr) info.
You can use this symbol inside the linker script to track and define boundaries of various sections.
You can also set the location counter to any specific value while writing linker script.
Location counter should appear only inside the SECTIONS command.
It is incr. by the size of the output section - this helps you to track the boundary.

We should use location counter and linker script symbols together.



Linker script symbols
----------------------------------------------------------------
A symbol is the name of an addr(mem loc), but a symbol declaration is not equivalent to a var declaration what you do in your C application.

In C, - int my_value = 100; - you don't know at which location this var is located. You just access it using the var name my_value. But in the background, it must be converted into an addr. manipulation. 

So, how this variable/fn name is replaced by the address? - with the help of 'symbol table'.
When you compile a C prog, .c -> .o. In .o, the compiler maintains a table called symbol table. For the compiler, this is not a var/fn name. It is var name for you, the programmer. For the compiler/linker terminology, we call it 'symbol name' - a symbol is a name given to an address. 

Symbol table has 2 major columns - address, symbol_name.

The address will be resolved by looking into the symbol table which is maintained by the compiler in the .o file.

When writing a C prg, we need not worry about these symbols. But now writing linker script, we want to catch the boundary info - _etext, _sdata, _edata. Here, we can't create variables - not a .c file. 



Example of symbol declaration in .ld script:
----------------------------------------------------------------
__max_heap_size = 0x400;
__max_stack_size = 0x200;

When linker sees these symbol names in .ld script, it adds them into the symbol table in the final .elf file.



Example-2
----------------------------------------------------------------
.text:
{		// at the beginning linker assumes that (.) = start of vma of this section. Here, . = addr. of FLASH
	*(.u_vector_table)
	*(.text)
	*(.rodata)
	end_of_text = .; //symbol_name = end_of_text; . = location counter. Remember, (.) is incr. by the size of the output 	  section auto by the linker.
}>FLASH

Hence, now (.) holds the address of end of the .text section. Now, you get the boundary. Now, you can export this symbol to C prog and access the exact addr where the .text section ends.

Location counter always tracks VMA of the section in which it is being used (not LMA).


Example-3
----------------------------------------------------------------
.data 
{
	start_of_data = .; //Here, the location_counter resets to the start of VMA of this section. Hence, here . = start addr. of SRAM
	*(.data)
}>SRAM AT>FLASH



Now, to copy .data section from Flash to SRAM, we should know:
1. source address = _etext (since, here .rodata in part of .text)
2. destination address = _sdata
3. size of .data section = _edata - _sdata

////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////
Linking and linker flags
////////////////////////////////////////////////////////////////

After compile-proper stage, use the same command to link:
----------------------------------------------------------------
arm-none-eabi-gcc -nostdlib -T STM32F4VGTx_v2.ld *.o -o final.elf //Added this cmd to Makefile
arm-none-eabi-objdump.exe -h final.elf



Analyzing final.elf file
----------------------------------------------------------------
final.elf file is a collection of various sections - .text, .data, .bss, etc. Make sure they are placed at appropriate absolute addresses. You can do that using tools like objdump, readelf, etc. But you can also instruct the linker to craete a spl file called mapfile - by using mapfile, we can analyze various resource allocation and placement in the memory.

Command to create (memory) mapfile:
----------------------------------------------------------------
-Map=final.map



Command to see all the symbols of the application:
----------------------------------------------------------------
arm-none-eabi-nm.exe final.elf



Start addr of a section must always be word-aligned.
Here, linker will not care about using *fill* . You have to do that manually using ALIGN command to align the location counter.
COMMON section - optional.


Strip debug & header info to create the .bin
////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////
Now, finish writing 'Reset_Handler' in startup file
////////////////////////////////////////////////////////////////
see startup.s

////////////////////////////////////////////////////////////////





////////////////////////////////////////////////////////////////
OpenOCD - semihosting
////////////////////////////////////////////////////////////////
semihosting - there must be a support of host. Here, host is OpenOCD. 
printf() statement is pulled by the host application and then displayed on the OpenOCD console. Hence, OpenOCD must be running and it should be in connection with the target.

TO use semihosting, 
1. change the --specs file in the Makefile -> --specs=rdimon.specs  -> lib with semihosting support.
2. initialise_monitor_handles(); - in main.c
3. don't use syscalls.c. Now semihosting lib is providing all the syscalls.


Enable semihosting feature in OpenOCD using the command -> 'arm semihosting enable' in Putty.

////////////////////////////////////////////////////////////////


