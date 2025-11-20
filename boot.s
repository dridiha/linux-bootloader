.code16
.global _start

.equ BASE_SEG, 0x1000
.equ DISK_IMG_SIZE_BYTES, 0x52E800
.equ DISK_IMG_SECTORS, 0x2974

_start:
  cli
  xor %ax, %ax
  mov %ax, %ds
  mov %ax, %ss 
  xor %bx, %bx

_load_ata_driver:
  mov $0x7E0, %ax
  mov %ax, %es 
  mov $0x02, %ah
  mov $1, %al
  mov $0, %ch
  mov $2, %cl 
  mov $0, %dh
  mov $0x80, %dl
  int $0x13
  
_load_boot_sector:
  mov $BASE_SEG, %ax
  mov %ax, %es
  mov $0x02, %ah
  mov $1, %al
  mov $0, %ch
  mov $3, %cl 
  mov $0, %dh
  mov $0x80, %dl
  int $0x13

_load_setup_sectors:
   mov $0x200, %bx
   mov $0x02, %ah
   movb %es:0x1F1, %al
   mov $0x0, %ch
   mov $0x4, %cl
   mov $0, %dh
   mov $0x80, %dl
   int $0x13

_init_kernel_header:
  movb $0xFF, %es:0x210
  // heap 
  orb $0x80, %es:0x211
  // heap end_ptr
  movw $0xDE00, %es:0x224
  // cmd_line_ptr
  movl $0x1E000, %es:0x228
  // address of initramfs
  movl $0x3C00000, %es:0x218
  // size of initramfs 
  movl $DISK_IMG_SIZE_BYTES, %es:0x21c

_copy_cmd_line:
  cld
  mov $cmd_line_size, %cx
  mov $cmd_line, %si 
  mov $0xE000, %di 
  rep movsb

_switch_pm:
  lgdt gdt_desc
  mov %cr0, %eax
  or $0x1, %eax
  mov %eax, %cr0
  mov $2, %al
  out %al, $0x92 
  ljmp $0x8, $_start_32

.code32
_start_32:
  mov $0x10, %ax
  mov %ax, %ds
  mov %ax, %ss
  mov %ax, %es 
  mov %ax, %fs
  mov %ax, %gs
  mov $0x90000, %esp

_load_compressed_kernel:
  push $0x0

  xor %ebx, %ebx
  mov %es:0x101F4, %edx
  shr $5, %edx
  push %edx

  xor %eax, %eax
  movb %es:0x101F1, %al
  add $3, %al
  push %eax

  push $0x100000

  call 0x7E00

  add $16, %esp

_load_initramfs:
  push $0x1 
  push $DISK_IMG_SECTORS
  push $0x0
  push $0x3C00000
  
  call 0x7E00 
  add $16, %esp
// use a 16 bit data/code segment to go back to the real mode
_reset_16:
  cli
  mov $0x20, %eax
  mov %eax, %ds
  mov %eax, %ss
  mov %eax, %es 
  mov %eax, %fs
  mov %eax, %gs
  ljmp $0x18, $_switch_rm

.code16
_switch_rm:
  mov %cr0, %eax
  and $~1, %eax
  mov %eax, %cr0
  ljmp $0x0000, $_start_16

_start_16:
  // reload the segments with the base seg value: 0x1000
  cli
  mov $BASE_SEG, %ax
  mov %ax, %ds 
  mov %ax, %es 
  mov %ax, %ss
  mov %ax, %gs
  mov %ax, %fs
  mov $0xE000, %esp
  ljmp $0x1020, $0x0

gdt:
gdt_null:
  .long 0x0
  .long 0x0
gdt_code:
  .word 0xFFFF
  .word 0x0 
  .byte 0x0
  .byte 0x9A 
  .byte 0xCF
  .byte 0x0 
gdt_data:
  .word 0xFFFF
  .word 0x0 
  .byte 0x0
  .byte 0x92 
  .byte 0xCF
  .byte 0x0 
gdt_16_code:
  .word 0xFFFF
  .word 0x0 
  .byte 0x0
  .byte 0x9b 
  .byte 0x0
  .byte 0x0 
gdt_16_data:
  .word 0xFFFF
  .word 0x0 
  .byte 0x0
  .byte 0x93 
  .byte 0x0
  .byte 0x0 

gdt_end:
gdt_desc:
  .word gdt_end - gdt - 1 
  .long gdt

cmd_line:
  .asciz "console=ttyS0 acpi=off nokaslr"
  
cmd_line_size = . - cmd_line

.org 510
.word 0xAA55
