movi.d r0 0
movi.d r5 55
mov    r1 r5
stw    r1 r0 2
movi.d r5 66
mov    r1 r5
stw    r1 r0 4
movi.d r5 77
mov    r1 r5
stw    r1 r0 6
ldw    r2 r0 2
ldw    r3 r0 4
ldw    r4 r0 6
stw    r4 r0 1022
halt