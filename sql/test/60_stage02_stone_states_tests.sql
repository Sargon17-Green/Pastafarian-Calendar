-- Native Stage 2 stones regression: independent fixed golden values and boundaries.
-- Golden vectors calculated separately with integer arithmetic; no reference SQL loaded.
BEGIN;
CREATE TEMP TABLE stage02_stone_assertions (
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK(ok)
);
INSERT INTO stage02_stone_assertions(test_name,ok) VALUES
('அறியப்பட்ட துல்லிய நிலை 1', (pastafari_sql_tamil.stone_state(1)=ROW(17::numeric,29::numeric,43::numeric,71::numeric,101::numeric)::pastafari_sql_tamil.stone5)),
('அறியப்பட்ட துல்லிய நிலை 2', (pastafari_sql_tamil.stone_state(2)=ROW(378::numeric,1073::numeric,2375::numeric,6195::numeric,10493::numeric)::pastafari_sql_tamil.stone5)),
('அறியப்பட்ட துல்லிய நிலை 3', (pastafari_sql_tamil.stone_state(3)=ROW(146106::numeric,1163582::numeric,5685063::numeric,38495823::numeric,110114158::numeric)::pastafari_sql_tamil.stone5)),
('அறியப்பட்ட துல்லிய நிலை 23', (pastafari_sql_tamil.stone_state(23)=ROW(77564730720631127195256936625899538078::numeric,18350534809599576800554196621275474477::numeric,136515445896507027766058223646135438648::numeric,59702139753743844437817074109053343983::numeric,16051679527321293846854424588737480047::numeric)::pastafari_sql_tamil.stone5)),
('அறியப்பட்ட துல்லிய நிலை 46', (pastafari_sql_tamil.stone_state(46)=ROW(73799454308499791987382386781055001470::numeric,147925408106533232424672641008220632365::numeric,94499522601819303005579577099149028685::numeric,108473647672201258090947028490673028834::numeric,137131922036975206684616468948804344042::numeric)::pastafari_sql_tamil.stone5)),
('செல்லாத குறியீடு 0', (pastafari_sql_tamil.stone_state(0) IS NULL)),
('செல்லாத குறியீடு -1', (pastafari_sql_tamil.stone_state(-1) IS NULL)),
('செல்லாத குறியீடு 47', (pastafari_sql_tamil.stone_state(47) IS NULL)),
('NULL இடம்', (pastafari_sql_tamil.stone_state(NULL::integer) IS NULL)),
('விதை கூறு 1', (pastafari_sql_tamil.stone_value(1,1)=17)),
('விதை கூறு 2', (pastafari_sql_tamil.stone_value(1,2)=29)),
('விதை கூறு 3', (pastafari_sql_tamil.stone_value(1,3)=43)),
('விதை கூறு 4', (pastafari_sql_tamil.stone_value(1,4)=71)),
('விதை கூறு 5', (pastafari_sql_tamil.stone_value(1,5)=101)),
('செல்லாத கூறு 0', (pastafari_sql_tamil.stone_value(3,0) IS NULL)),
('செல்லாத கூறு 6', (pastafari_sql_tamil.stone_value(3,6) IS NULL)),
('செல்லாத கூறு -1', (pastafari_sql_tamil.stone_value(3,-1) IS NULL)),
('NULL கூறு', (pastafari_sql_tamil.stone_value(3,NULL::integer) IS NULL)),
('அனைத்தும் 46 இடங்கள்', ((SELECT count(*)=46 FROM generate_series(1,46) AS g(i) WHERE pastafari_sql_tamil.stone_state(i) IS NOT NULL))),
('அனைத்தும் M எல்லைக்குள்', ((SELECT bool_and((st).wheat BETWEEN 1 AND pastafari_sql_tamil.save_modulus() AND (st).barley BETWEEN 1 AND pastafari_sql_tamil.save_modulus() AND (st).salt BETWEEN 1 AND pastafari_sql_tamil.save_modulus() AND (st).bitter BETWEEN 1 AND pastafari_sql_tamil.save_modulus() AND (st).red BETWEEN 1 AND pastafari_sql_tamil.save_modulus()) FROM (SELECT pastafari_sql_tamil.stone_state(i) AS st FROM generate_series(1,46) AS g(i)) x))),
('முடிவு மறுநிலை விதி', (((pastafari_sql_tamil.stone_state(46)).wheat=pastafari_sql_tamil.save_value((pastafari_sql_tamil.stone_state(45)).wheat*(pastafari_sql_tamil.stone_state(45)).wheat+3*(pastafari_sql_tamil.stone_state(45)).barley+46) AND (pastafari_sql_tamil.stone_state(46)).barley=pastafari_sql_tamil.save_value((pastafari_sql_tamil.stone_state(45)).barley*(pastafari_sql_tamil.stone_state(45)).barley+5*(pastafari_sql_tamil.stone_state(45)).salt+(pastafari_sql_tamil.stone_state(45)).wheat) AND (pastafari_sql_tamil.stone_state(46)).salt=pastafari_sql_tamil.save_value((pastafari_sql_tamil.stone_state(45)).salt*(pastafari_sql_tamil.stone_state(45)).salt+7*(pastafari_sql_tamil.stone_state(45)).bitter+(pastafari_sql_tamil.stone_state(45)).barley) AND (pastafari_sql_tamil.stone_state(46)).bitter=pastafari_sql_tamil.save_value((pastafari_sql_tamil.stone_state(45)).bitter*(pastafari_sql_tamil.stone_state(45)).bitter+11*(pastafari_sql_tamil.stone_state(45)).red+(pastafari_sql_tamil.stone_state(45)).salt) AND (pastafari_sql_tamil.stone_state(46)).red=pastafari_sql_tamil.save_value((pastafari_sql_tamil.stone_state(45)).red*(pastafari_sql_tamil.stone_state(45)).red+13*(pastafari_sql_tamil.stone_state(45)).wheat+(pastafari_sql_tamil.stone_state(45)).bitter)))),
('முதன்மை சார்பு தனிமை', ((position('pastafari_sql_tamil_test' in pg_get_functiondef('pastafari_sql_tamil.stone_state(integer)'::regprocedure))=0))),
('கூறு சார்பு தனிமை', ((position('pastafari_sql_tamil_test' in pg_get_functiondef('pastafari_sql_tamil.stone_value(integer,integer)'::regprocedure))=0)));
SELECT 'இரண்டாம் கட்ட கல் நிலைச் சோதனைகள்' AS status,
       count(*) AS assertion_count FROM stage02_stone_assertions;
COMMIT;
