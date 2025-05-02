[bits 16]

org 0x7c00

; near so the instruction takes up 3 bytes
; short is used for some reason (copilot told me to) and nop is used as a 1 byte spacer
jmp short .start ; 0 @ 3
nop

; BPB
bpb_oem_name: db 'MSWIN4.1' ; 3 @ 8
bpb_bytes_per_sec: dw 0x200 ; 11 @ 2
bpb_sec_per_clus: db 0x4 ; 13 @ 1
bpb_rsvd_sec_cnt: dw 0x4 ; 14 @ 2
bpb_num_fat: db 0x2 ; 16 @ 1
bpb_root_ent_cnt: dw 0x200 ; 17 @ 2
bpb_tot_sec_16: dw 0x0 ; 19 @ 2
bpb_media: db 0xf8 ; 21 @ 1
bpb_fat_sz_16: dw 0x40 ; 22 @ 2
bpb_sec_per_trk: dw 0x20 ; 24 @ 2
bpb_num_heads: dw 0x4 ; 26 @ 2
bpb_hidd_sec: dd 0x0 ; 28 @ 4
bpb_tot_sec_32: dd 0x10000 ; 32 @ 4

; EBP
ebp_drv_num: db 0x80 ; 36 @ 1
ebp_reserved1: db 0x0 ; 37 @ 1
ebp_boot_sig: db 0x29 ; 38 @ 1
ebp_vol_id: dd 0x0 ; 39 @ 4
ebp_vol_lab: db 'MY FAT DISK' ; 43 @ 11
ebp_fil_sys_type: db 'GOTCHA  ' ; 54 @ 8


.start:
cli

mov ah, 0xa
mov al, 'A'
mov bh, 0x0
mov cx, 1
int 0x10

cli
hlt
hlt

; Fill file with 0's until 510
times 510-($-$$) db 0
db 0x55
db 0xaa