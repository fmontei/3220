movi.d r0 1912
andi.d r1 r0 2157
addi.d r1 r1 -521
add.d r2 r0 r1
cmp r1 r2
brz 6 
brp 5
and.d r3 r0 r1
movi.f r8 -222.70
addi.f r8 r8 57.40
movi.f r9 359.90
add.f r10 r8 r9 
mov r4 r3
movi.d r5 11
add.d r6 r4 r5
cmpi r5 11
halt
