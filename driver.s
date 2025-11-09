.code32

_ata_driver_init:
  push %ebp
  mov %esp, %ebp 
  mov 8(%ebp), %eax 
  mov %eax, disk_addr
  mov 12(%ebp), %eax 
  mov %eax, disk_lba
  mov 16(%ebp), %eax 
  mov %eax, disk_img_size
  mov 20(%ebp), %eax 
  mov %eax, disk_number

_ata_driver_load:
  mov disk_addr, %edi 
  mov disk_img_size, %eax
  test %eax, %eax
  jz _ret

  cmpl $0xFF, %eax 
  jbe 1f 
  mov $0xFF, %eax

1:
  mov %eax, %ebx
  push %ebx 

  movl disk_lba, %ecx
  // init 

  mov $0x1F2, %dx
  mov %bl, %al
  out %al, %dx 

  mov $0x1F3, %dx
  mov %cl, %al
  out %al, %dx 
  shr $8, %ecx 

  mov $0x1F4, %dx
  mov %cl, %al
  out %al, %dx 
  shr $8, %ecx 

  mov $0x1F5, %dx
  mov %cl, %al
  out %al, %dx 

  
  mov $0x1F6, %dx
  movb disk_number, %al
  shl $4, %al 
  or $0xE0, %al
  mov disk_lba, %ecx 
  shr $24, %ecx 
  and $0x0F, %cl 
  or %cl, %al
  out %al, %dx
  // send read command
  mov $0x1F7, %dx
  mov $0x20, %al
  out %al, %dx
  jmp _wait_loop

_wait_loop:
  mov $0x1F7, %dx
  in %dx, %al
  testb $0x08, %al
  jz _wait_loop
  jmp _read

_read:
  mov $256, %cx
  mov $0x1F0, %dx
  rep insw

_sleep:
  mov $0x3F6, %dx 
  in %dx, %al
  in %dx, %al
  in %dx, %al
  in %dx, %al
  dec %bl
  cmp $0, %bl
  jnz _wait_loop

_update_values:
  pop %ebx
  mov disk_img_size, %eax 
  sub %ebx, %eax
  mov %eax, disk_img_size
  mov disk_lba, %eax 
  add %ebx, %eax
  mov %eax, disk_lba
  mov %edi, disk_addr 
  jmp _ata_driver_load

_ret:
  pop %ebp
  ret

disk_img_size: .long 0x0 
disk_lba: .long 0x0
disk_addr: .long 0x0 
disk_number: .long 0x0

.org 512
