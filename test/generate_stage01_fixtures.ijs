load 'test/normative_reference.ijs'

NB. Generator local de fixture-uri. Produce valori numai din oracle-ul J al acestei linii.

line=: 4 : 0
  x, TAB, (":y), LF
)

text=. 'fixture',TAB,'valoare',LF
text=. text, 'SAVE_M' line nr_save M
text=. text, 'SAVE_2M' line nr_save 2x*M
text=. text, 'DAY_FOUNDATION' line nr_dayCount FOUNDATION_DAY
text=. text, 'DAY_FOUNDATION_MINUS_1' line nr_dayCount FOUNDATION_DAY-1x
text=. text, 'DAY_FOUNDATION_PLUS_1' line nr_dayCount FOUNDATION_DAY+1x
text=. text, 'WORK_COUNTS_FOUNDATION' line FOUNDATION_DAY nr_workCounts FOUNDATION_DAY
text=. text, 'STONE_ROW_1' line 0{STONES
text=. text, 'STONE_ROW_2' line 1{STONES
text=. text, 'PERMUTATION_1' line nr_bowlOrderFromNumber 1x
text=. text, 'PERMUTATION_720' line nr_bowlOrderFromNumber 720x
text=. text, 'CUTLET_FILTER_COUNT_6_3_2' line nr_cutletPartitionCount 6;3;2
text=. text, 'BOUNDED_COUNT_6_2_1_5' line nr_countBounded 6;2;1;5
text=. text, 'WEAVE_COUNT_2_2' line nr_countWeavings 2 2
text=. text, 'WEAVE_UNRANK_2_2_1' line 2 2 nr_unrankWeaving 1x
text=. text, 'WEAVE_UNRANK_2_2_2' line 2 2 nr_unrankWeaving 2x
sauceFoundation=. FOUNDATION_DAY nr_sauce FOUNDATION_DAY
text=. text, 'SAUCE_FOUNDATION_BOWLS' line >0{sauceFoundation
text=. text, 'SAUCE_FOUNDATION_ORDER46' line >1{sauceFoundation
text 1!:2 <'test/stage01_fixtures.tsv'
echo 'Fixture-urile Stage 1 au fost scrise în test/stage01_fixtures.tsv'
