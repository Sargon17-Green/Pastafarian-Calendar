# Stage 1 — external five-field Word intake (2026-10-30)

Code: src/PastafarianWord.bas. The new InsertPastafarianDateFromSelection accepts exactly five labeled Word paragraphs in order: year, cutletName, dayInCutlet, monthName, dayInMonth. It reads selected text, rejects malformed fields, and inserts an unverified external tuple without replacing selected source. Legacy InputBox now rejects the ambiguous 254-character boundary.

Non-native verification: 24/24 independent JavaScript model cases PASS; 11/11 source inspection checks PASS. Includes a 1024-digit year, Unicode preservation and invalid-order/number rejection. These tests do NOT execute VBA or Word.

Open gates: Word compile and execution of PastafarianInputContractSelfTest, RakinModularSelfTest (8), RakinArithmeticSelfTest (5). Native Word devices offline. Source authenticity, canonical indices (17/47), NFC, Mapudungun linguistic approval and F(c,t) are NOT verified. Stay in Stage 1; do not merge main.
