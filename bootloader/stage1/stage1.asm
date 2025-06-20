[bits 16]

org 0x7c00

; near so the instruction takes up 3 bytes
; short is used for some reason (copilot told me to) and nop is used as a 1 byte spacer
jmp short .start ; 0 @ 3
nop

; BPB
bpb_oem_name:      db 'MSWIN4.1' ; 3 @ 8
bpb_bytes_per_sec: dw 0x200 ; 11 @ 2
bpb_sec_per_clus:  db 0x4 ; 13 @ 1
bpb_rsvd_sec_cnt:  dw 0x4 ; 14 @ 2
bpb_num_fat:       db 0x2 ; 16 @ 1
bpb_root_ent_cnt:  dw 0x200 ; 17 @ 2
bpb_tot_sec_16:    dw 0x0 ; 19 @ 2
bpb_media:         db 0xf8 ; 21 @ 1
bpb_fat_sz_16:     dw 0x40 ; 22 @ 2
bpb_sec_per_trk:   dw 0x20 ; 24 @ 2
bpb_num_heads:     dw 0x4 ; 26 @ 2
bpb_hidd_sec:      dd 0x0 ; 28 @ 4
bpb_tot_sec_32:    dd 0x10000 ; 32 @ 4

; EBP
ebp_drv_num: db 0x80 ; 36 @ 1
ebp_reserved1: db 0x0 ; 37 @ 1
ebp_boot_sig: db 0x29 ; 38 @ 1
ebp_vol_id: dd 0x0 ; 39 @ 4
ebp_vol_lab: db 'MY FAT DISK' ; 43 @ 11
ebp_fil_sys_type: db 'FAT16   ' ; 54 @ 8

; --- PUTS ---
; ds:si : pointer to null-terminated ascii string
.puts:
mov ah, 0xe
mov bh, 0x0
mov cx, 0x1

.puts_loop:
lodsb
test al, al
jz .puts_done

int 0x10
jmp .puts_loop

.puts_done:
ret
; --- PUTS END ---

; --- LBA_TO_CHS ---
.lba_to_chs:
; After this function read_sectors can be called so return values will correspond to the inputs of that interrupt
; ch: cylinder
; cl: sector
; dh: head
; ax: lba
div byte [bpb_sec_per_trk] ; al: quotient, ah: remainder
mov  cl, ah
inc cl
xor ah, ah
div byte [bpb_num_heads] ; al: quotient, ah: remainder
mov ch, al
mov dh, ah
ret
; --- LBA_TO_CHS END ---

; Make sure that CS is set to 0
.pre_start:
cli
jmp 0x0:.start

.start:

; Setup segment registers and stackpointer, code and data lives in the same location
; CS is already 0
mov ax, 0x0
mov ds, ax ; ds will start at the same location as cs
mov ss, ax ; ss will start at the same location as cs
mov es, ax ; es will start at the same location as cs
mov sp, 0x7c00 ; let the stack begin right before the code
mov [ebp_drv_num], dl ; dl contains drive number this sector came from

; Read disk parameters
mov ah, 0x8
mov dl, [ebp_drv_num]
int 0x13
; ch: cylinders
; cl: sectors per track
; dh: number of sides (0 based)

jc .failed_to_read_drive_params

; Success reading drive params
xor ax, ax
mov al, cl
and al, 0b00111111
mov [bpb_sec_per_trk], ax
mov al, dh
inc al
mov [bpb_num_heads], ax

; Root dir LBA:
; Reserved sectors is boot sector and a few empty sectors -> [bpb_rsvd_sec_cnt]
; Following is a couple of FATs -> [bpb_num_fat] * [bpb_fat_sz_16] (this is in sectors)
; LBA of root dir: [bpb_rsvd_sec_cnt] + [bpb_num_fat] * [bpb_fat_sz_16]
mov ax, [bpb_fat_sz_16]
mul byte [bpb_num_fat]
add ax, [bpb_rsvd_sec_cnt]

; Loading the root dir
call .lba_to_chs
mov ax, 32
mul word [bpb_root_ent_cnt]
mov bx, 512
div bx ; al contains sectors root directory spans, should be 32 sectors
mov dl, [ebp_drv_num]
mov bx, 0x7e00
call .read_sectors
jc .failed_to_read_drive_params

; Finding the kernel
; Assumption: should be in the root directory
mov bx, 16
mov si, .kernel
call .puts
jmp .hlt
mov di, .kernel
.find_kernel_loop:
test bx, bx
jz .kernel_not_found
mov ax, 11
call .strncmp
add si, 32
dec bx
jc .find_kernel_loop

.kernel_found:
mov si, .kernel_found_error
call .puts
jmp .hlt

.kernel_not_found:
mov si, .kernel_not_found_error
call .puts
jmp .hlt

.failed_to_read_drive_params:
mov si, .failed_to_read_drive_params_error
call .puts
jmp .hlt

.hlt:
cli
hlt
hlt

.failed_to_read_drive_params_error: db 'Failed to read params', 0x0
.kernel_not_found_error: db 'Kernel not found', 0x0
.kernel_found_error: db 'Kernel found!', 0x0
.kernel: db 'TEST    TXT'

; --- STRNCMP ---
; si: str1
; di: str2
; ax: n
.strncmp:
push si ; save for later
push di
push bx
push cx
clc ; clear carry
.strncmp_loop:
test ax, ax
jz .strncmp_done
mov bl, [si] ; load char of str1
mov cl, [di] ; load char of str2
inc si ; move to the next char
inc di ; move to the next char
dec ax
cmp bl, cl ; compare the chars
je .strncmp_loop
stc
.strncmp_done:
pop cx
pop bx
pop di
pop si
ret
; --- STRNCMP END ---

; --- READ_SECTORS ---
; al: number of sectors to read
; ch: cylinder
; cl: sector
; dh: head
; dl: drive num
; es:bx: pointer to buffer
.read_sectors:
mov ah, 0x2
int 0x13
ret
; --- READ_SECTORS END ---

; Fill file with 0's until 510
times 510-($-$$) db 0
db 0x55
db 0xaa
