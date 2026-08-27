CREATE VIEW pastafari_sql_tamil.source_language_catalog AS
SELECT category, canonical_index, source_text_tamil
FROM (VALUES
('CUTLET'::text,1,'வெண்கலம்'::text),
('CUTLET',2,'நரி'),
('CUTLET',3,'சிறுநீரகம்'),
('CUTLET',4,'லகாஷ்'),
('CUTLET',5,'சிந்தனை'),
('CUTLET',6,'ஒன்பதில் நான்கு பாகங்கள்'),
('CUTLET',7,'பல்குராஷ்'),
('CUTLET',8,'நாணல்'),
('CUTLET',9,'கொத்து'),
('CUTLET',10,'தேள்'),
('CUTLET',11,'சாம்பல்'),
('CUTLET',12,'கோதுமை'),
('CUTLET',13,'ஆறு'),
('CUTLET',14,'சிரிப்பு'),
('CUTLET',15,'அக்காத்'),
('CUTLET',16,'கொம்பு'),
('CUTLET',17,'காலிக் குடம்'),
('MONTH',1,'களிமண்'),
('MONTH',2,'மாதுளை'),
('MONTH',3,'முழங்கை'),
('MONTH',4,'பொறாமை'),
('MONTH',5,'எரிடு'),
('MONTH',6,'பற்பசை'),
('MONTH',7,'ஐந்தில் மூன்று பாகங்கள்'),
('MONTH',8,'கர்ஷூமப்'),
('MONTH',9,'சிறுத்தை'),
('MONTH',10,'தகரம்'),
('MONTH',11,'மூடுபனி'),
('MONTH',12,'குங்கிலியம்'),
('MONTH',13,'நூற்புக்கோல்'),
('MONTH',14,'விலா எலும்பு'),
('MONTH',15,'கரோப் பழம்'),
('MONTH',16,'உருக்'),
('MONTH',17,'வெட்கம்'),
('MONTH',18,'ஒட்டகம்'),
('MONTH',19,'செம்பு'),
('MONTH',20,'கிணறு'),
('MONTH',21,'முட்டை மஞ்சள்'),
('MONTH',22,'நட்சத்திரம்'),
('MONTH',23,'தேன்'),
('MONTH',24,'மண்ணீரல்'),
('MONTH',25,'சுண்ணாம்புக்கல்'),
('MONTH',26,'மகிழ்ச்சி'),
('MONTH',27,'அத்திப்பழம்'),
('MONTH',28,'நினவே'),
('MONTH',29,'தவளை'),
('MONTH',30,'தார்'),
('MONTH',31,'மெழுகுவர்த்தி'),
('MONTH',32,'மூடிய கதவு'),
('MONTH',33,'எள்'),
('MONTH',34,'கழுத்துப் பின்புறம்'),
('MONTH',35,'வெள்ளி'),
('MONTH',36,'அல்லி மலர்'),
('MONTH',37,'புயல்'),
('MONTH',38,'கழுதை'),
('MONTH',39,'மாவு'),
('MONTH',40,'வருத்தம்'),
('MONTH',41,'பாபிலோன்'),
('MONTH',42,'நாக்கு'),
('MONTH',43,'ஆளி'),
('MONTH',44,'உப்பு'),
('MONTH',45,'பேரிக்காய்'),
('MONTH',46,'வில்'),
('MONTH',47,'மணல்')
) AS catalog(category, canonical_index, source_text_tamil);

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.source_name(p_category text, p_index integer)
RETURNS text
LANGUAGE SQL
STABLE
STRICT
AS $$
    SELECT source_text_tamil
    FROM pastafari_sql_tamil.source_language_catalog
    WHERE category = p_category AND canonical_index = p_index
$$;
