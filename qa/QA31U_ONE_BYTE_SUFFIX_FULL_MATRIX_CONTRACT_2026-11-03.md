# QA31U — exhaustive 256 one-byte suffix Native frontier experiment

Project: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Parent SHA: 9690786ec6c9afc61e94c863579df7ed82a5c278
Pinned original source blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Pinned interpreter: PyFunge-0.5-rc2.tar.gz, SHA256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac

## Why this case set

Original QA31S+QA31T proved only finite properties, not Stage1 acceptance. In QA31T the
second ~ at physical STEP 7918 saw EOF for exact b'1 0 0 0'; introducing a
trailing byte changed the next route. Eight space/tab separator variants without
suffix had the same IP/opcode route and m(3,49)=1, q(1,49)=3 then 4.
Four variants with LF, CRLF, trailing ASCII space or tab yielded m=0.
None of (286,5), (235,23), (235,32) was physically visited.

QA31U varies only the final, single byte, holding b'1 0 0 0' fixed.
It tests all 256 possible single-octet suffix values 0x00..0xFF,
including NUL, CR, LF, tab, high-bit bytes and nonprintable values.
The exact no-suffix control belongs to QA31T and is not silently treated as
an extra one-byte case.

## Runs, physical oracle and bounds

- Eight jobs/shards indexed 0..7. Shard i executes byte values 32*i through 32*i+31 in ascending order.
- Exactly 256 fresh, untouched-source in-process PyFunge Native Program runs across all shards.
- Per-case physical tick limit: 25,000. Per-shard maximum: 800,000. Total maximum: 6,400,000 physical steps. Any STEP_LIMIT or RUNTIME_ERROR fails that shard; report remains a bounded observation rather than a PASS.
- No source, Funge-Space, original interpreter, initial IP, stdout policy, or read contents are modified. Byte provenance is recorded as hexadecimal; filenames contain only two-digit hex labels.
- Record every Native STEP (IP, delta, opcode, stringmode, pre/post stack, next IP/delta), p/g, j/x, every stdin read/readline byte offset and EOF event, terminal output, tick count and compressed trace SHA256.
- Independent Python 3 auditor recomputes original Git blob, checks the 2,015-row geometry, all expected input SHA256, all 32 compressed trace SHA256 per shard, all physical ticks and IP/delta chaining, native opcode compared with original source plus preceding p overlay, p/g stack operations, read-byte/EOF provenance and visits to all three frontier targets.
- Each shard must independently reject 18/18 forged receipts/trace events (11 receipt and 7 physical-trace tampering variants); the first trace must contain actual p, g, stdin read witnesses to make tampering effective.
- Output per shard: receipt JSON; independent audit JSON with per-input gate states, frontier ticks, j/x observations; 32 compressed full traces; Native/audit logs.
- Gate-combination, output and boundary observations are measurements only. Independent audit does not substitute a complete functional/semantic oracle for the original program.
- CI acceptance requires all eight jobs completed/success on the exact same HEAD, all 256 HALT receipts, independently audited physical traces and 144/144 hostile controls. ZIP SHA256 and CRC must be checked for each of the eight artifacts before recording artifact-level acceptance.

## Scope

QA31U gives a complete enumeration of **one-byte suffixes after one fixed prefix**,
not a proof over all inputs. Finite non-visitation is not unreachability. No
production edit, Stage1 PASS, Stage2, main update, merge, public release,
global input ownership, global reachability or functional/geometric PASS.
