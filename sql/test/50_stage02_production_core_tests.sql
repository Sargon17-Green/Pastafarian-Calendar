-- Native-only, production-only Stage 2 core regression checks.
-- This database must NOT load sql/test/10_normative_reference.sql.
BEGIN;
CREATE TEMP TABLE stage02_core_assertions (
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK (ok)
);
INSERT INTO stage02_core_assertions(test_name,ok) VALUES
('சேமிப்பு நிலையான முழு எண்', (pastafari_sql_tamil.save_modulus()=170141183460469231731687303715884105727::numeric)),
('நிறுவல் நிலையான நாள்', (pastafari_sql_tamil.foundation_day()=(-15055671)::numeric)),
('நேர்மறை முழு வகுத்தல்', (pastafari_sql_tamil.floor_div(14,3)=4)),
('எதிர்மறை முழு வகுத்தல்', (pastafari_sql_tamil.floor_div(-14,3)=-5)),
('பூஜ்ய முழு வகுத்தல்', (pastafari_sql_tamil.floor_div(0,3)=0)),
('சரியான பகுதி எதிர்மறை', (pastafari_sql_tamil.floor_div(-15,3)=-5)),
('பெரும் முழு வகுத்தல்', (pastafari_sql_tamil.floor_div(pastafari_sql_tamil.save_modulus()*pastafari_sql_tamil.save_modulus()+pastafari_sql_tamil.save_modulus()-1,pastafari_sql_tamil.save_modulus())=pastafari_sql_tamil.save_modulus())),
('பெரும் எதிர்மறை வகுத்தல்', (pastafari_sql_tamil.floor_div(-(pastafari_sql_tamil.save_modulus()*pastafari_sql_tamil.save_modulus()+1),pastafari_sql_tamil.save_modulus())=-(pastafari_sql_tamil.save_modulus()+1))),
('பூஜ்ய பகுத்தல் நிராகரிப்பு', (pastafari_sql_tamil.floor_div(7,0) IS NULL)),
('எதிர்மறை பகுத்தல் நிராகரிப்பு', (pastafari_sql_tamil.floor_div(7,-2) IS NULL)),
('பின்ன பகா எண் நிராகரிப்பு', (pastafari_sql_tamil.floor_div(7,2.5) IS NULL)),
('பின்ன வகுக்கப்படும் எண் நிராகரிப்பு', (pastafari_sql_tamil.floor_div(7.5,2) IS NULL)),
('நேர்மறை யூக்ளிடியன் மீதி', (pastafari_sql_tamil.regular_mod(13,3)=1)),
('எதிர்மறை யூக்ளிடியன் மீதி', (pastafari_sql_tamil.regular_mod(-13,3)=2)),
('பெரும் யூக்ளிடியன் மீதி', (pastafari_sql_tamil.regular_mod(pastafari_sql_tamil.save_modulus()*pastafari_sql_tamil.save_modulus()+pastafari_sql_tamil.save_modulus()-1,pastafari_sql_tamil.save_modulus())=pastafari_sql_tamil.save_modulus()-1)),
('செல்லாத மீதி நிராகரிப்பு', (pastafari_sql_tamil.regular_mod(7,0) IS NULL)),
('சேமிப்பு ஒன்று', (pastafari_sql_tamil.save_value(1)=1)),
('சேமிப்பு எல்லை M', (pastafari_sql_tamil.save_value(pastafari_sql_tamil.save_modulus())=pastafari_sql_tamil.save_modulus())),
('சேமிப்பு M கூட்டல் ஒன்று', (pastafari_sql_tamil.save_value(pastafari_sql_tamil.save_modulus()+1)=1)),
('சேமிப்பு இரண்டு M', (pastafari_sql_tamil.save_value(2*pastafari_sql_tamil.save_modulus())=pastafari_sql_tamil.save_modulus())),
('சேமிப்பு பூஜ்யம்', (pastafari_sql_tamil.save_value(0)=pastafari_sql_tamil.save_modulus())),
('சேமிப்பு எதிர்மறை ஒன்று', (pastafari_sql_tamil.save_value(-1)=pastafari_sql_tamil.save_modulus()-1)),
('சேமிப்பு பெரும் இருபடி', (pastafari_sql_tamil.save_value(pastafari_sql_tamil.save_modulus()*pastafari_sql_tamil.save_modulus()+1)=1)),
('பின்ன சேமிப்பு நிராகரிப்பு', (pastafari_sql_tamil.save_value(1.5) IS NULL)),
('நிறுவல் நாள் எண்ணிக்கை', (pastafari_sql_tamil.day_count(pastafari_sql_tamil.foundation_day())=1)),
('நிறுவலுக்கு முன் ஒன்று', (pastafari_sql_tamil.day_count(pastafari_sql_tamil.foundation_day()-1)=2)),
('நிறுவலுக்குப் பின் ஒன்று', (pastafari_sql_tamil.day_count(pastafari_sql_tamil.foundation_day()+1)=3)),
('நிறுவலுக்கு முன் இரண்டு', (pastafari_sql_tamil.day_count(pastafari_sql_tamil.foundation_day()-2)=4)),
('பெரும் நாள் துல்லியம்', (pastafari_sql_tamil.day_count(pastafari_sql_tamil.foundation_day()+pastafari_sql_tamil.save_modulus())=2*pastafari_sql_tamil.save_modulus()+1)),
('பின்ன நாள் நிராகரிப்பு', (pastafari_sql_tamil.day_count(pastafari_sql_tamil.foundation_day()+0.5) IS NULL)),
('சம நாள் செயல் மற்றும் இலக்கு', ((pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day(),pastafari_sql_tamil.foundation_day())).action=1 AND (pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day(),pastafari_sql_tamil.foundation_day())).target=1)),
('சம நாள் தூரம் மற்றும் திசை', ((pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day(),pastafari_sql_tamil.foundation_day())).distance=1 AND (pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day(),pastafari_sql_tamil.foundation_day())).connection=2 AND (pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day(),pastafari_sql_tamil.foundation_day())).direction=2)),
('முன் திசை ஐந்து கூறுகள்', ((pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day()+2,pastafari_sql_tamil.foundation_day()-3))=ROW(5::numeric,6::numeric,6::numeric,11::numeric,1)::pastafari_sql_tamil.work_counts)),
('பின் திசை ஐந்து கூறுகள்', ((pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day()-3,pastafari_sql_tamil.foundation_day()+2))=ROW(6::numeric,5::numeric,6::numeric,11::numeric,3)::pastafari_sql_tamil.work_counts)),
('பெரும் வேலை நாள் துல்லியம்', ((pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day(),pastafari_sql_tamil.foundation_day()+pastafari_sql_tamil.save_modulus())).distance=pastafari_sql_tamil.save_modulus()+1 AND (pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day(),pastafari_sql_tamil.foundation_day()+pastafari_sql_tamil.save_modulus())).direction=3)),
('பின்ன வேலை நாள் நிராகரிப்பு', (pastafari_sql_tamil.work_counts(pastafari_sql_tamil.foundation_day()+0.5,pastafari_sql_tamil.foundation_day()) IS NULL)),
('நுழைவு இன்னும் முழு நாட்காட்டி அல்ல', ((SELECT count(*)=0 FROM pastafari_sql_tamil.calendar_date_spaghetti(pastafari_sql_tamil.foundation_day(),pastafari_sql_tamil.foundation_day()))));

SELECT 'இரண்டாம் கட்ட முதன்மை கணக்குச் சோதனைகள்' AS status,
       count(*) AS assertion_count
FROM stage02_core_assertions;
COMMIT;
