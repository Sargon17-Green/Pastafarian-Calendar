# ግዕዝ — source-language catalog policy

The source human language for this implementation branch is ግዕዝ
(classical Ethiopic / Ge'ez), not Amharic (አማርኛ) and not Coptic.

This file is a policy scaffold, not a frozen translation catalog.
No unreviewed English or modern Amharic phonetic forms are asserted to be
attested Classical Ge'ez terms. Preserve exact canonical indices independent
of display strings, and preserve distinctions among meaningful translated
names, proper names and intentionally meaningless sound sequences.

The canonicalIndex of each item must drive ordering, ranking, unranking,
selection, hashes and cache keys; translated Unicode text must never drive
semantic ordering. Before Stage 1 can be declared complete, every canonical
name must be populated and reviewed for Ge'ez orthography and morphology,
with stable Unicode normalization; then freeze its index-to-name mapping.
The canonical names in main are only a normative reference for index/content,
not a source to import host-language implementation code.

Status: CATALOG_UNFROZEN, LINGUISTIC_QA_PENDING.
