load 'src/calendar_spaghetti.ijs'
load 'test/normative_reference.ijs'

NB. Suită locală pentru Bootstrap. Niciun test nu consultă altă implementare.

check=: 4 : 0
  if. -. x do.
    echo 'EȘEC: ', y
    assert. 0
  end.
  echo 'OK: ', y
  1
)

echo 'Stage 1 — pornire suită J + română'

(validateSourceLanguageCatalog '') check 'catalogul românesc are 17 + 47 intrări unice'
(CUTLET_CANONICAL_INDEX -: 1+i.17) check 'indicii canonici ai chiftelelor sunt fixați'
(MONTH_CANONICAL_INDEX -: 1+i.47) check 'indicii canonici ai lunilor sunt fixați'
('grâu' -: cutletNameFromCanonicalIndex 12) check 'traducerea semantică pentru grâu este fixată'
('pastă de dinți' -: monthNameFromCanonicalIndex 6) check 'traducerea semantică pentru pastă de dinți este fixată'
('Palguraș' -: cutletNameFromCanonicalIndex 7) check 'transliterarea deterministă Palguraș este fixată'
('Karșumab' -: monthNameFromCanonicalIndex 8) check 'transliterarea deterministă Karșumab este fixată'

(TABLETS_DAY - FOUNDATION_DAY = 14777149x) check 'distanța dintre Tablete și Fundație este exactă'
(M = <:2x^127) check 'M este 2^127 - 1 în precizie extinsă'
(M > 2x^126) check 'aritmetica extinsă depășește domeniul întregului mașină uzual'

((nr_save 1x) = 1x) check 'SAVE(1)'
((nr_save M-1x) = M-1x) check 'SAVE(M-1)'
((nr_save M) = M) check 'SAVE(M) întoarce M, nu zero'
((nr_save M+1x) = 1x) check 'SAVE(M+1)'
((nr_save 2x*M) = M) check 'SAVE(2M) întoarce M'
((nr_save _1x) = M-1x) check 'SAVE(-1) este înfășurat exact'

((nr_dayCount FOUNDATION_DAY) = 1x) check 'numărătoarea zilei Fundației este 1'
((nr_dayCount FOUNDATION_DAY+1x) = 3x) check 'ziua după Fundație are etichetă impară'
((nr_dayCount FOUNDATION_DAY-1x) = 2x) check 'ziua înainte de Fundație are etichetă pară'
((FOUNDATION_DAY nr_workCounts FOUNDATION_DAY) -: 1x 1x 1x 2x 2x) check 'cazul calculationDay = targetDay are distanța 1 și direcția 2'
((FOUNDATION_DAY nr_workCounts FOUNDATION_DAY+3x) -: 1x 7x 4x 8x 3x) check 'numărătorile înaintează cronologic fără diferență de etichete'

((0{STONES) -: 17x 29x 43x 71x 101x) check 'primul rând de pietre este canonic'
stone1=. 0{STONES
w=. 0{stone1
b=. 1{stone1
s=. 2{stone1
m=. 3{stone1
r=. 4{stone1
expectedStone2=. (nr_save +/ (w*w),(3x*b),2x), (nr_save +/ (b*b),(5x*s),w), (nr_save +/ (s*s),(7x*m),b), (nr_save +/ (m*m),(11x*r),s), nr_save +/ (r*r),(13x*w),m
((1{STONES) -: expectedStone2) check 'toate cele cinci pietre din rândul 2 citesc același snapshot vechi'

((nr_bowlOrderFromNumber 1x) -: 1 2 3 4 5 6) check 'permutarea de rang 1 este identitatea'
((nr_bowlOrderFromNumber 720x) -: 6 5 4 3 2 1) check 'permutarea de rang 720 este inversarea completă'
((nr_bowlOrderFromDrop 720x) -: 6 5 4 3 2 1) check 'o picătură multiplu de 720 selectează rangul 720'

streamPlus=. 1x 1x
((streamPlus nr_answerAt 0x) = 1x) check 'primul număr al fluxului sintetic este stabil'
((streamPlus nr_answerAt 3x) = 4x) check 'fluxul sintetic înaintează pe același inel'
((streamPlus nr_chooseRank 1x) = 1x) check 'selecția scurtă N=1'
((streamPlus nr_chooseRank M) = 1x) check 'selecția scurtă N=M'
wideN=. M+1x
((streamPlus nr_chooseRank wideN) = wideN) check 'selecția largă N=M+1 folosește numărul larg exact'

((nr_cutletPartitionCount 6;3;2) = 4x) check 'filtrul de frontieră pentru compoziții are numărul exact într-un spațiu mic'
((nr_unrankCutletPartition 6;3;2;1) -: 1 1 4) check 'unrank lexical filtrat — primul element'
((nr_unrankCutletPartition 6;3;2;4) -: 2 3 1) check 'unrank lexical filtrat — ultimul element'

((nr_countBounded 6;2;1;5) = 5x) check 'numărul compozițiilor limitate mici este exact'
((nr_unrankBounded 6;2;1;5;1) -: 1 5) check 'unrank limitat păstrează primul element lexical'
((nr_unrankBounded 6;2;1;5;5) -: 5 1) check 'unrank limitat păstrează ultimul element lexical'

((nr_countWeavings 2 2) = 2x) check 'numărul țesăturilor pentru 2 2 este exact'
((2 2 nr_unrankWeaving 1x) -: 1 1 2 2) check 'prima țesătură pentru 2 2 este lexicală'
((2 2 nr_unrankWeaving 2x) -: 1 2 1 2) check 'a doua țesătură pentru 2 2 este lexicală'
((nr_countWeavings 1 1 1) = 1x) check 'lunile unitare au o singură țesătură legală'
((1 1 1 nr_unrankWeaving 1x) -: 1 2 3) check 'țesătura unitară respectă ordinea deschiderii și închiderii'

countsFoundation=. FOUNDATION_DAY nr_workCounts FOUNDATION_DAY
hiddenFoundation=. nr_buildHiddenDrops countsFoundation
visibleFoundation=. nr_buildVisibleDrops countsFoundation
(7 = #hiddenFoundation) check 'oracle-ul produce exact șapte picături ascunse'
(46 = #visibleFoundation) check 'oracle-ul produce exact 46 de picături vizibile'
( (0x < <./ hiddenFoundation) *. ((>./ hiddenFoundation) <: M) ) check 'picăturile ascunse rămân în 1..M'
( (0x < <./ visibleFoundation) *. ((>./ visibleFoundation) <: M) ) check 'picăturile vizibile rămân în 1..M'

sauceFoundation=. FOUNDATION_DAY nr_sauce FOUNDATION_DAY
(6 = # >0{sauceFoundation) check 'sosul are exact șase boluri finale'
(6 = # ~. >1{sauceFoundation) check 'latch-ul ordinii picăturii 46 este o permutare de șase boluri'
( (/: >1{sauceFoundation) -: 1+i.6 ) check 'ordinea picăturii 46 conține exact ID-urile 1..6'

ctx=. FOUNDATION_DAY calendarDateSpaghettiBootstrap FOUNDATION_DAY
(MONSTER_STATUS_NOT_INTEGRATED -: monsterContextStatus ctx) check 'scheletul de producție validează intrarea fără a pretinde integrarea viitoare'
productionText=. 1!:1 <'src/calendar_spaghetti.ijs'
(0 = +/ 'normative_reference' E. productionText) check 'producția nu importă oracle-ul de test'

echo 'Stage 1 — toate testele executate au trecut'
