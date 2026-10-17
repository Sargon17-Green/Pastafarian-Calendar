# Spaghetti09 — Native 17D genuine dual-worker rendezvous [substage 09A]

State: Native smoke fixture candidate. Not the 80-opcode full QA09 acceptance.
This does **not** promote calendar production, close Stage 1 or start Stage 2.

Source pin: `0bedcd5a7ed1207a836850fdcd91faeeae0ee901`.
Required QA08 parent source `4ba6902de08cf9483374f43a33f1d4ae7a14e3f6`
remains untouched. Native interpreter Funge++
`cwesson/funge-plus-plus@cd6d7f005b4fc33b486fcc2380b35406f6125ca4`
uses its real 17-component Funge-space, two actual native `t` forks and
cloned, separately owned stack-of-stacks.

The first worker, forked from (0,0), executes on negative-x space and
produces physical `p(10001)=31` then `p(10000)=62`. The main
IP computes the exact width of the second worker (115 source
instructions), uses native `j` to skip it, and executes a second
`t`. The new worker heads west through the *source text the main IP
deliberately skipped*; it has its own nested `{` and `}`, real `u`
transfer and produces `p(10003)=33` then `p(10002)=66`.

The main IP cannot reach the final computation until both physical
flags have been read equal to their respective emitted ready markers.
Two separately wired retry lanes occupy distinct y=1 and y=0
hyperplanes, while two independent ready lanes occupy y=-1 and y=-2.
On success, the main IP reads both physical residue cells with native
17D `g` and prints `31 33`. It must pass repeated Native runs for
both test seeds, including four intentionally corrupting mutations.

The failed attempts of QA08 remain documented. This fixture isolates
actual concurrency and deterministic fan-in *before* rebuilding the
full 17D 80-opcode mesh. Correctness of this fixture alone does not
satisfy the 17D source-generation requirements of the complete QA09.
