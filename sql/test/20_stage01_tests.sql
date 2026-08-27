BEGIN;

CREATE TEMP TABLE stage01_assertions (
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK (ok)
);

INSERT INTO stage01_assertions VALUES
('கறி-துண்டுப் பெயர்களின் எண்ணிக்கை', (SELECT count(*)=17 FROM pastafari_sql_tamil.source_language_catalog WHERE category='CUTLET')),
('மாதப் பெயர்களின் எண்ணிக்கை', (SELECT count(*)=47 FROM pastafari_sql_tamil.source_language_catalog WHERE category='MONTH')),
('கறி-துண்டு canonicalIndex வரம்பு', (SELECT min(canonical_index)=1 AND max(canonical_index)=17 AND count(DISTINCT canonical_index)=17 FROM pastafari_sql_tamil.source_language_catalog WHERE category='CUTLET')),
('மாத canonicalIndex வரம்பு', (SELECT min(canonical_index)=1 AND max(canonical_index)=47 AND count(DISTINCT canonical_index)=47 FROM pastafari_sql_tamil.source_language_catalog WHERE category='MONTH')),
('மூல மொழி அட்டவணை மாற்றமுடியாத view', pg_relation_is_updatable('pastafari_sql_tamil.source_language_catalog'::regclass,true)=0),
('கோதுமை பெயர் நிலை', pastafari_sql_tamil.source_name('CUTLET',12)='கோதுமை'),
('உப்பு பெயர் நிலை', pastafari_sql_tamil.source_name('MONTH',44)='உப்பு');

INSERT INTO stage01_assertions VALUES
('பெரும் எண்ணின் துல்லியம்', pastafari_sql_tamil_test.m()=170141183460469231731687303715884105727::numeric),
('SAVE ஒன்று', pastafari_sql_tamil_test.save_value(1)=1),
('SAVE M', pastafari_sql_tamil_test.save_value(pastafari_sql_tamil_test.m())=pastafari_sql_tamil_test.m()),
('SAVE M+1', pastafari_sql_tamil_test.save_value(pastafari_sql_tamil_test.m()+1)=1),
('SAVE 2M', pastafari_sql_tamil_test.save_value(2*pastafari_sql_tamil_test.m())=pastafari_sql_tamil_test.m()),
('SAVE பூஜ்யம்', pastafari_sql_tamil_test.save_value(0)=pastafari_sql_tamil_test.m()),
('நிறுவல் நாளின் நாள்-எண்', pastafari_sql_tamil_test.day_count(pastafari_sql_tamil_test.foundation_day())=1),
('நிறுவலுக்கு முந்தைய நாள்-எண்', pastafari_sql_tamil_test.day_count(pastafari_sql_tamil_test.foundation_day()-1)=2),
('நிறுவலுக்கு அடுத்த நாள்-எண்', pastafari_sql_tamil_test.day_count(pastafari_sql_tamil_test.foundation_day()+1)=3),
('ஒரே நாளின் தூரம் ஒன்று', (pastafari_sql_tamil_test.work_counts(pastafari_sql_tamil_test.foundation_day(),pastafari_sql_tamil_test.foundation_day())).distance=1),
('ஒரே நாளின் திசை இரண்டு', (pastafari_sql_tamil_test.work_counts(pastafari_sql_tamil_test.foundation_day(),pastafari_sql_tamil_test.foundation_day())).direction=2);

INSERT INTO stage01_assertions VALUES
('கல் அட்டவணை நாற்பத்தாறு வரிகள்', (SELECT count(*)=46 FROM pastafari_sql_tamil_test.stone_table)),
('முதல் கல் நிலை', (pastafari_sql_tamil_test.stone_row(1)).wheat=17 AND (pastafari_sql_tamil_test.stone_row(1)).barley=29 AND (pastafari_sql_tamil_test.stone_row(1)).salt=43 AND (pastafari_sql_tamil_test.stone_row(1)).bitter=71 AND (pastafari_sql_tamil_test.stone_row(1)).red=101),
('முதல் permutation', pastafari_sql_tamil_test.bowl_order_from_number(1)=ARRAY[1,2,3,4,5,6]),
('எழுநூற்று இருபதாவது permutation', pastafari_sql_tamil_test.bowl_order_from_number(720)=ARRAY[6,5,4,3,2,1]),
('falling factorial துல்லியம்', pastafari_sql_tamil_test.falling_factorial(5,3)=60),
('binomial துல்லியம்', pastafari_sql_tamil_test.binomial_exact(5,2)=10),
('bounded composition எண்ணிக்கை', pastafari_sql_tamil_test.bounded_count(6,2,1,5)=5),
('bounded composition முதல் unrank', pastafari_sql_tamil_test.unrank_bounded_composition(6,2,1,5,1)=ARRAY[1,5]),
('bounded composition கடைசி unrank', pastafari_sql_tamil_test.unrank_bounded_composition(6,2,1,5,5)=ARRAY[5,1]),
('கட்டாய உள் எல்லையுள்ள partition எண்ணிக்கை', pastafari_sql_tamil_test.cutlet_partition_count(6,3,0,3,false)=4),
('கட்டாய உள் எல்லையுள்ள முதல் partition', pastafari_sql_tamil_test.unrank_cutlet_partition(6,3,3,1)=ARRAY[1,2,3]),
('கட்டாய உள் எல்லையுள்ள கடைசி partition', pastafari_sql_tamil_test.unrank_cutlet_partition(6,3,3,4)=ARRAY[3,2,1]);

TRUNCATE TABLE pastafari_sql_tamil_test.weave_memo;

INSERT INTO stage01_assertions VALUES
('2,2 நெய்தல்களின் எண்ணிக்கை', pastafari_sql_tamil_test.weave_count(ARRAY[2,2],ARRAY[2,2],0,0)=2),
('2,2 முதல் நெய்தல்', pastafari_sql_tamil_test.unrank_weaving(ARRAY[2,2],1)=ARRAY[1,1,2,2]),
('2,2 இரண்டாம் நெய்தல்', pastafari_sql_tamil_test.unrank_weaving(ARRAY[2,2],2)=ARRAY[1,2,1,2]);

INSERT INTO stage01_assertions VALUES
('குறுகிய தேர்வு முன்னோக்கி rejection', pastafari_sql_tamil_test.choose_rank_short(ROW(pastafari_sql_tamil_test.m(),1)::pastafari_sql_tamil_test.answer_stream,10)=1),
('குறுகிய தேர்வு பின்னோக்கி rejection', pastafari_sql_tamil_test.choose_rank_short(ROW(pastafari_sql_tamil_test.m(),-1)::pastafari_sql_tamil_test.answer_stream,10)=10),
('wide தேர்வு வரம்பு', pastafari_sql_tamil_test.choose_rank_wide(ROW(pastafari_sql_tamil_test.m(),1)::pastafari_sql_tamil_test.answer_stream,pastafari_sql_tamil_test.m()+1) BETWEEN 1 AND pastafari_sql_tamil_test.m()+1);

WITH s AS (
    SELECT pastafari_sql_tamil_test.sauce(pastafari_sql_tamil_test.foundation_day(),pastafari_sql_tamil_test.foundation_day()) AS a,
           pastafari_sql_tamil_test.sauce(pastafari_sql_tamil_test.foundation_day(),pastafari_sql_tamil_test.foundation_day()) AS b
)
INSERT INTO stage01_assertions
SELECT 'ரசத்தின் மீள்கணக்கீடு துல்லியமாக ஒரேது', a=b FROM s;

WITH s AS (
    SELECT pastafari_sql_tamil_test.sauce(pastafari_sql_tamil_test.foundation_day(),pastafari_sql_tamil_test.foundation_day()) AS r
), q AS (
    SELECT r,(r).order_at_drop_46[6] AS last_id FROM s
)
INSERT INTO stage01_assertions
SELECT '46வது துளியின் கடைசி கிண்ணத்துக்கு அடுத்தது முதல் கிண்ணம்',
       pastafari_sql_tamil_test.next_bowl_in_drop46_order(r,last_id)=(r).order_at_drop_46[1]
FROM q;

INSERT INTO stage01_assertions VALUES
('production தொடக்க நுழைவு முடிவு வழங்காது', (SELECT count(*)=0 FROM pastafari_sql_tamil.calendar_date_spaghetti(0,0))),
('தனி context உள்ளீடு தக்கவைக்கிறது', (pastafari_sql_tamil.new_monster_context(11,22)).calculation_day=11 AND (pastafari_sql_tamil.new_monster_context(11,22)).target_day=22),
('அடிப்படை dispatcher validation செய்கிறது', (pastafari_sql_tamil.base_dispatch(pastafari_sql_tamil.new_monster_context(11,22))).status='READY');

INSERT INTO stage01_assertions
SELECT 'இந்த வரியின் எல்லா function-களும் SQL மொழியிலேயே உள்ளன', count(*)=0
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
JOIN pg_language l ON l.oid=p.prolang
WHERE n.nspname IN ('pastafari_sql_tamil','pastafari_sql_tamil_test')
  AND l.lanname<>'sql';

INSERT INTO stage01_assertions
SELECT 'production நுழைவு test oracle-ஐ அழைக்காது',
       position('pastafari_sql_tamil_test' in pg_get_functiondef('pastafari_sql_tamil.calendar_date_spaghetti(numeric,numeric)'::regprocedure))=0;

INSERT INTO stage01_assertions
SELECT 'எதிர்கால legacy மற்றும் patch பெயர்கள் production-இல் இல்லை', count(*)=0
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='pastafari_sql_tamil'
  AND p.proname ~ '(old|legacy|patch|detour|ghost|latch)';

SELECT 'முதல் கட்ட SQL சோதனைகள் அனைத்தும் வெற்றியடைந்தன' AS status,
       count(*) AS assertion_count
FROM stage01_assertions;

COMMIT;
