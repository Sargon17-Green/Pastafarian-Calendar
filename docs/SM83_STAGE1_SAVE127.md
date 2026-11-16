# SM83 Stage1: signed canonical SAVE127 native candidate

Project PC-BRANCH-SM83-ASSEMBLY-GEEZ; branch SM83-Assembly+ግዕዝ.
Predecessor 7985c2434fab4b9e5472fad05a1e02085cc2dd0e is accepted by run 43940074307: two jobs completed/success, Host 92, ROM0 free 10, DMG header PASS, PyBoy A5/309/40 frames8286.

Input: active serialized owner lease (1..13 SRAM banks), canonical signed ordinal (0<=length<=106496, sign 0 or 1, no high zero byte, zero sign0/length0); SRAM enabled, interrupts disabled. SAVE(x)=1+((x-1) mod M), M=2^127-1, Euclidean modulo. Output: canonical positive (sign0, length1..16, bytes little-endian), status0; invalid/capacity status2; inactive status6. SAVE(0)=M; SAVE(-1)=M-1; SAVE(M)=M; SAVE(2^127)=1; SAVE(2^128)=2.

Algorithm: independent 16-byte WRAM remainder with high-to-low radix256 Horner scan, 2^127=1 (mod M) fold, M->0 remainder, complement of 127 bits for negative input, and zero residue -> M. Snapshot first16 owner SRAM bytes for rollback; commit metadata only after successful writes. Bytes from logical owner offset16 onward and all other owners stay unchanged until abort. Under serialized stable lease OwnerByteWrite failures are non-mutating and earlier prefix is restored; concurrent lease corruption or physical failure during rollback is not supported. Existing ROM0 Save127 is only an unsigned 128-bit primitive; this routine accepts signed multi-bank input.

Native cases310..319: idle, zero, M, one, negative one, high-bit 2^127, invalid negative zero, +2^128, -2^128, abort scrub. Independent Host oracle uses Python Euclidean arbitrary-precision math plus separately computed radix256 modular residue and full 13-bank input.

Acceptance only after exact-SHA natural-push completed success for verify and dmg-native-smoke; Host SAVE127 PASS count; real RGBDS, ROM_HEADER PASS; ROM0 free >=10; PyBoy A5/319/40 <=9000 frames. Does not implement calendar date conversion, Ge'ez source catalog, Stage2 or main merge.
