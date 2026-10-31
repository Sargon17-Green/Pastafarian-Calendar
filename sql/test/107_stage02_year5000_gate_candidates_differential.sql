-- Stage 2 Slice 13 differential against an independently enumerated
-- 2-pair and 6-pair Python nested-loop oracle, with verified numeric constants.
-- Sort oracle keys: (close_day-open_day, open_day), same contract as normative
-- year5000; no production function is used to generate expected values.
BEGIN;
CREATE TEMP TABLE stage02_year5000_candidates_differential(test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok));
INSERT INTO stage02_year5000_candidates_differential
SELECT 'f1-first',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[]) AS p WHERE p.candidate_rank=1 AND p.candidate_count=2 AND p.open_gate_index=-2 AND p.close_gate_index=4 AND p.open_gate_day=100 AND p.close_gate_day=700))
UNION ALL SELECT 'f1-second',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[]) AS p WHERE p.candidate_rank=2 AND p.candidate_count=2 AND p.open_gate_index=-3 AND p.close_gate_index=4 AND p.open_gate_day=0 AND p.close_gate_day=700))
UNION ALL SELECT 'f2-first',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]) AS p WHERE p.candidate_rank=1 AND p.candidate_count=6 AND p.open_gate_index=-4 AND p.close_gate_index=2 AND p.open_gate_day=-200 AND p.close_gate_day=525))
UNION ALL SELECT 'f2-second',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]) AS p WHERE p.candidate_rank=2 AND p.candidate_count=6 AND p.open_gate_index=-3 AND p.close_gate_index=3 AND p.open_gate_day=-100 AND p.close_gate_day=700))
UNION ALL SELECT 'f2-third',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]) AS p WHERE p.candidate_rank=3 AND p.candidate_count=6 AND p.open_gate_index=-2 AND p.close_gate_index=4 AND p.open_gate_day=0 AND p.close_gate_day=800))
UNION ALL SELECT 'f2-fourth',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]) AS p WHERE p.candidate_rank=4 AND p.candidate_count=6 AND p.open_gate_index=-4 AND p.close_gate_index=3 AND p.open_gate_day=-200 AND p.close_gate_day=700))
UNION ALL SELECT 'f2-fifth',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]) AS p WHERE p.candidate_rank=5 AND p.candidate_count=6 AND p.open_gate_index=-3 AND p.close_gate_index=4 AND p.open_gate_day=-100 AND p.close_gate_day=800))
UNION ALL SELECT 'f2-sixth',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]) AS p WHERE p.candidate_rank=6 AND p.candidate_count=6 AND p.open_gate_index=-4 AND p.close_gate_index=4 AND p.open_gate_day=-200 AND p.close_gate_day=800))
UNION ALL SELECT 'f1-total',((SELECT count(*)=2 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[])))
UNION ALL SELECT 'f2-total',((SELECT count(*)=6 FROM pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[])))
UNION ALL SELECT 'f2-translation',((SELECT coalesce(bool_and(open_gate_index BETWEEN 10 AND 12 AND close_gate_index BETWEEN 16 AND 18),false) AND count(*)=6 FROM pastafari_sql_tamil.year5000_gate_pairs(450,10,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[])))
UNION ALL SELECT 'f2-same-days-after-translation',((SELECT count(*)=6 FROM pastafari_sql_tamil.year5000_gate_pairs(450,10,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]) AS new JOIN pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]) AS old USING(candidate_rank) WHERE new.open_gate_day=old.open_gate_day AND new.close_gate_day=old.close_gate_day AND new.open_gate_index=old.open_gate_index+14 AND new.close_gate_index=old.close_gate_index+14))
UNION ALL SELECT 'f1-open-strict',((SELECT count(*)=0 FROM pastafari_sql_tamil.year5000_gate_pairs(0,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[])))
UNION ALL SELECT 'f1-close-inclusive',((SELECT count(*)=2 FROM pastafari_sql_tamil.year5000_gate_pairs(700,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[])));
SELECT count(*) AS differential_assertions FROM stage02_year5000_candidates_differential;
COMMIT;
