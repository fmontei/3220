addi.d  r0 r0 13
addi.d  r1 r1 0 
mov     r2 r1
addi.d  r3 r2 2

addi.d  r0 r0 -1
addi.f  r1 r1 3.5f
stw     r1 r3 0 
ldw     r4 r3 0
addi.d  r3 r3 2
cmpi    r0 0
brp     -7
movi.d  r5 22 
stw     r1 r5 1000
halt