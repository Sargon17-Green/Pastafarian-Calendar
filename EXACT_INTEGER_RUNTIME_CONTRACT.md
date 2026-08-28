# കൃത്യ പൂർണ്ണസംഖ്യാ runtime കരാർ

മഗിള നിർദേശിക്കുന്ന നോർമറ്റീവ് കണക്കിൽ floating-point ഉപയോഗിക്കാനാവില്ല. `M = 2^127 - 1` മാത്രമല്ല, permutation/composition/weaving count-ുകളും അതിലേറെ വലുതാകാം. അതിനാൽ ഈ implementation line പ്രവർത്തിപ്പിക്കുന്ന SPL runtime ഓരോ arithmetic operation-നും sign സഹിതമുള്ള കൃത്യമായ, overflow ഇല്ലാത്ത പൂർണ്ണസംഖ്യ നൽകണം.

ഘട്ടം 1-ലെ പ്രാഥമിക portability തീരുമാനം ഇതാണ്:

1. SPL source സ്വയം floating-point ഉപയോഗിക്കില്ല.
2. runtime integer ഒരു നിശ്ചിത machine width-ൽ wrap, saturate, truncate ചെയ്യുകയാണെങ്കിൽ ആ runtime ഈ repository-യ്ക്ക് അംഗീകരിക്കാനാവില്ല.
3. `test/exact_integer_probe.spl` കുറഞ്ഞത് `2^127 - 1` കൃത്യമായി നിർമിക്കാനും അതിന്മേൽ arithmetic നടത്താനും runtime-ന് കഴിയുന്നുവെന്ന് തെളിയിക്കണം.
4. അതിലും വലിയ combinatorial arithmetic പരിശോധിക്കുന്ന probe പൂർണ്ണ oracle-നൊപ്പം ചേർക്കണം.
5. ഈ പരിശോധനകൾ വിജയിക്കാത്ത runtime-നെ ഉപയോഗിച്ച് Stage 1 GREEN ആയി പ്രഖ്യാപിക്കരുത്.

SPL ഭാഷയുടെ ചരിത്രപരമായ രേഖകൾ character-നെ signed integer ആയി മാത്രം വിവരിക്കുകയും width-നെ നോർമറ്റീവ് ആയി ഉറപ്പിക്കാതിരിക്കുകയും ചെയ്യുന്നതിനാൽ runtime capability ഒരു നിർബന്ധിത test precondition ആക്കുന്നു. ഈ പരിസ്ഥിതിയിൽ SPL runner ഇല്ലാത്തതിനാൽ capability ഇതുവരെ പ്രവർത്തിപ്പിച്ച് തെളിയിച്ചിട്ടില്ല.
