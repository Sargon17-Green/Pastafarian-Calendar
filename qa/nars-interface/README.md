# PC-BRANCH-APL-GERMAN: NARS2000 native-interface source audit

This is an independent, branch-only, bounded read-only investigation. The workflow downloads NARS2000's public SourceForge SVN trunk using HTTPS without executing downloaded code. It records SVN revision, inventory, per-file SHA256, and possible C source symbols for command-line parsing, stdin, Windows IPC, COM and workspace auto-load.

A symbol hit in code or comments is NOT proof of a working CLI; a no-hit result is NOT proof of absence. The source revision is NOT asserted to be the source of version 0.5.14.11 without a documented revision mapping.

The scanner always returns cli_supported=UNDETERMINED and native_executed=false. A human/code-review proof and a genuine pinned NARS2000 run remain necessary.

Offline tests: python3 -m unittest discover -s qa/nars-interface -p 'test_*.py' -v
Original APL+Deutsch HEAD: 7161824b9fcbfaca91f20d1ea492417e77003ff4
No APL source changes, no main/merge, no Native PASS.
