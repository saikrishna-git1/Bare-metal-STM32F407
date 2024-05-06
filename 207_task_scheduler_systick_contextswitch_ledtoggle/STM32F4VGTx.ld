ENTRY(Reset_Handler)

MEMORY 
{
	FLASH(rx) : ORIGIN =0x08000000, LENGTH =1024K
	SRAM(rwx) : ORIGIN =0x20000000, LENGTH =128K
}

SECTIONS
{
	.text :
	{
		*(.u_vector_table)
		*(.text)
		*(.rodata)
	}>FLASH AT>FLASH
	
	.data :
	{
		*(.data)
	}>SRAM AT>FLASH
	
	.bss :
	{
		*(.bss)
	}>SRAM
}