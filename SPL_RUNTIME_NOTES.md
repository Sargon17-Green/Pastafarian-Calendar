# SPL runtime കുറിപ്പുകൾ

ഈ രേഖ semantic source of truth അല്ല. നോർമറ്റീവ് അർത്ഥം embedded Appendix A-ൽ നിന്നുമാത്രമാണ് എടുക്കുന്നത്. ഇവിടെ രേഖപ്പെടുത്തുന്നത് Stage 1 source പ്രവർത്തിപ്പിക്കാൻ വേണ്ട toolchain അവസ്ഥ മാത്രമാണ്.

Shakespeare Programming Language-ന്റെ പരമ്പരാഗത toolchain source play-നെ `spl2c` വഴി C-യിലേക്ക് മാറ്റി പിന്നീട് native executable ആക്കുന്നതാണ്. ഈ execution environment-ൽ `spl2c` ലഭ്യമല്ല; പഴയ toolchain നിർമ്മിക്കാൻ സാധാരണ ആവശ്യമായ parser-generator ഉപകരണങ്ങളും ഇവിടെ മുൻകൂട്ടി ലഭ്യമല്ല. അതിനാൽ ആ toolchain ഉപയോഗിച്ച് local execution തെളിവ് നേടാനായിട്ടില്ല.

ഒരു runtime സ്വീകരിക്കാവുന്നതാകാൻ ഈ implementation line-ൽ താഴെ പറയുന്നവ നിർബന്ധമാണ്:

- input/output, assignment, comparison, conditional goto, scene goto, character stack എന്നിവ SPL semantics അനുസരിച്ച് പ്രവർത്തിക്കണം;
- signed integer arithmetic exact ആയിരിക്കണം;
- കുറഞ്ഞത് `2^127-1` കൃത്യമായി കൈകാര്യം ചെയ്യണം;
- അതിനേക്കാൾ വലുതാകുന്ന combinatorial count-ുകൾക്കും wrap, saturation, truncation, floating-point approximation ഒന്നും ഉണ്ടാകരുത്;
- runtime implementation ഏത് host ഭാഷയിൽ എഴുതപ്പെട്ടതാണെന്നത് calendar semantics-ന്റെ ഭാഗമാകരുത്; repository-യിലെ algorithm, oracle, tests, fixtures, generators എല്ലാം SPL തന്നെയായിരിക്കണം;
- oracle-ലേക്ക് production fallback അനുവദനീയമല്ല.

`test/exact_integer_probe.spl` runtime capability-യുടെ ആദ്യ gate ആണ്. അത് പരാജയപ്പെട്ടാൽ ആ runtime ഉപയോഗിച്ച് Stage 1 GREEN പ്രഖ്യാപിക്കരുത്.
