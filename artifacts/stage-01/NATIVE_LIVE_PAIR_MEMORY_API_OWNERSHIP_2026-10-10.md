# Native pair memory API ownership extension (Stage 1 QA)

This extends the existing real PyFunge 24-pair / 48-Program interleaving
matrix. In addition to prior stack/geometry/source/I-O snapshots, every
actual runtime Funge-space.get, Funge-space.put, and Funge-space.putspace
call during each program's scheduled native instruction is intercepted.

An access to any Funge-space other than the currently executing Program's
own private space fails immediately. Every write must be attributable to
one directly executed native p step; a putspace event fails this bounded
corpus. The interceptor is always restored, including on execution error.
For each input label, the number of actual reads and writes must be
unchanged across AB versus BA schedules and across different live peers.

The independent Python-3 evidence auditor also verifies read/write counts,
schedule neutrality and 16 adversarial forged manifests. Python code is
only QA instrumentation; all calendar arithmetic and execution remain in
Native PyFunge-98. This is a finite-domain, documented-API guarantee;
unknown interpreter mutation interfaces, other inputs, production branch
promotion and global Stage 1 ownership remain OPEN.
