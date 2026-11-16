# Stage1 signed ordinal +1/-1: native candidate

Project PC-BRANCH-SM83-ASSEMBLY-GEEZ; branch SM83-Assembly+ግዕዝ.
Predecessor exact cfffd74; CI 43825110741 completed/success Native299.

**Input**: active serialized DI invocation, live owner lease (1–13 physical SRAM banks), canonical sign (0 nonnegative, 1 negative), 24-bit little-endian length, little-endian magnitude and delta (0:+1, 1:-1).
**Output**: exact signed integer + delta in same owner lease, canonical sign and length; status 0 success, 2 invalid/capacity, 6 idle. Other owners and lease tags immutable.
**Algorithm**: first validate sign/top byte and scan carry/borrow prefix via owner-resolved logical bytes; check growth capacity BEFORE any write; compute resulting metadata; write uniform prefix then final replacement byte; commit metadata last. If a write reports an error, restore already written prefix. This rollback presumes the DI serialized lease remains available; concurrent lease corruption and physical faults are outside this guarantee.
**Gates**: independent Python-int Host oracle (including 255/256, logical 8192/8193 and fragmented owners), Native cases300–309, exact SHA completed verify/native jobs, RGBDS header PASS, measured ROM0 free >=10, PyBoy A5/309/40 <=9000. Before CI completion all are candidates, not Native PASS.
**Still open**: canonical SAVE modulo 2^127-1, full native date engine and Ge'ez catalog; dispatcher stays $40. No main/merge/Stage2.
