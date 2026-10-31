-- Stage 2 Slice 13 native: 35 bounded assertions, synthetic numeric gates.
-- Fixed oracle values independently enumerated by nested Python loops, not copied
-- from the PostgreSQL production function.
BEGIN;
CREATE TEMP TABLE stage02_year5000_candidates_native(test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok));
WITH f1 AS MATERIALIZED (SELECT * FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[])),
     f2 AS MATERIALIZED (SELECT * FROM pastafari_sql_tamil.year5000_gate_pairs(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[]))
INSERT INTO stage02_year5000_candidates_native
SELECT 'f1:count',((SELECT count(*)=2 FROM f1))
UNION ALL SELECT 'f1:rank1',(EXISTS(SELECT 1 FROM f1 WHERE candidate_rank=1 AND candidate_count=2 AND open_gate_index=-2 AND close_gate_index=4 AND open_gate_day=100 AND close_gate_day=700))
UNION ALL SELECT 'f1:rank2',(EXISTS(SELECT 1 FROM f1 WHERE candidate_rank=2 AND candidate_count=2 AND open_gate_index=-3 AND close_gate_index=4 AND open_gate_day=0 AND close_gate_day=700))
UNION ALL SELECT 'f1:distinct-ranks',((SELECT count(DISTINCT candidate_rank)=2 FROM f1))
UNION ALL SELECT 'f1:pick1',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_pick_gate_pair(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[],1) WHERE candidate_rank=1 AND open_gate_index=-2))
UNION ALL SELECT 'f1:pick2',(EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_pick_gate_pair(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[],2) WHERE candidate_rank=2 AND open_gate_index=-3))
UNION ALL SELECT 'f1:pick3-missing',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_pick_gate_pair(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[],3)))
UNION ALL SELECT 'f1:open-exclusive',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(0,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[])))
UNION ALL SELECT 'f1:close-inclusive',((SELECT count(*)=2 FROM pastafari_sql_tamil.year5000_gate_pairs(700,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[])))
UNION ALL SELECT 'f1:after-close',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(701,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[])))
UNION ALL SELECT 'f2:count',((SELECT count(*)=6 FROM f2))
UNION ALL SELECT 'f2:rank1',(EXISTS(SELECT 1 FROM f2 WHERE candidate_rank=1 AND candidate_count=6 AND open_gate_index=-4 AND close_gate_index=2 AND open_gate_day=-200 AND close_gate_day=525))
UNION ALL SELECT 'f2:rank2',(EXISTS(SELECT 1 FROM f2 WHERE candidate_rank=2 AND open_gate_index=-3 AND close_gate_index=3 AND open_gate_day=-100 AND close_gate_day=700))
UNION ALL SELECT 'f2:rank3',(EXISTS(SELECT 1 FROM f2 WHERE candidate_rank=3 AND open_gate_index=-2 AND close_gate_index=4 AND open_gate_day=0 AND close_gate_day=800))
UNION ALL SELECT 'f2:rank4',(EXISTS(SELECT 1 FROM f2 WHERE candidate_rank=4 AND open_gate_index=-4 AND close_gate_index=3 AND open_gate_day=-200 AND close_gate_day=700))
UNION ALL SELECT 'f2:rank5',(EXISTS(SELECT 1 FROM f2 WHERE candidate_rank=5 AND open_gate_index=-3 AND close_gate_index=4 AND open_gate_day=-100 AND close_gate_day=800))
UNION ALL SELECT 'f2:rank6',(EXISTS(SELECT 1 FROM f2 WHERE candidate_rank=6 AND open_gate_index=-4 AND close_gate_index=4 AND open_gate_day=-200 AND close_gate_day=800))
UNION ALL SELECT 'f2:rank7-missing',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_pick_gate_pair(450,-4,ARRAY[-200,-100,0,115,230,400,525,700,800]::numeric[],7)))
UNION ALL SELECT 'invalid:day-fraction',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650.5,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[])))
UNION ALL SELECT 'invalid:index-fraction',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3.5,ARRAY[0,100,200,300,400,500,600,700]::numeric[])))
UNION ALL SELECT 'invalid:gate-fraction',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300.5,400,500,600,700]::numeric[])))
UNION ALL SELECT 'invalid:gap-below42',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,41,141,241,341,441,541,641]::numeric[])))
UNION ALL SELECT 'invalid:gap-above963',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,964,1064,1164,1264,1364,1464,1564]::numeric[])))
UNION ALL SELECT 'invalid:duplicate',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300,400,400,600,700]::numeric[])))
UNION ALL SELECT 'invalid:decrease',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300,250,500,600,700]::numeric[])))
UNION ALL SELECT 'invalid:null-gate',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300,NULL,500,600,700]::numeric[])))
UNION ALL SELECT 'invalid:short',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[0,100,200,300,400,500]::numeric[])))
UNION ALL SELECT 'invalid:multidim',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_gate_pairs(650,-3,ARRAY[[0,100,200,300,400,500,600,700],[0,100,200,300,400,500,600,700]]::numeric[])))
UNION ALL SELECT 'invalid:rank-zero',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_pick_gate_pair(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[],0)))
UNION ALL SELECT 'invalid:rank-negative',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_pick_gate_pair(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[],-1)))
UNION ALL SELECT 'invalid:rank-fraction',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_pick_gate_pair(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[],1.5)))
UNION ALL SELECT 'invalid:rank-null',(NOT EXISTS(SELECT 1 FROM pastafari_sql_tamil.year5000_pick_gate_pair(650,-3,ARRAY[0,100,200,300,400,500,600,700]::numeric[],NULL::numeric)))
UNION ALL SELECT 'metadata:two-sql',((SELECT count(*)=2 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_language l ON l.oid=p.prolang WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('year5000_gate_pairs','year5000_pick_gate_pair') AND l.lanname='sql'))
UNION ALL SELECT 'metadata:immutable',((SELECT count(*)=2 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('year5000_gate_pairs','year5000_pick_gate_pair') AND p.provolatile='i'))
UNION ALL SELECT 'metadata:no-oracle',((SELECT count(*)=0 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('year5000_gate_pairs','year5000_pick_gate_pair') AND position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0));
SELECT count(*) AS native_assertions FROM stage02_year5000_candidates_native;
COMMIT;
