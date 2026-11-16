-- Eight actual year/day records verified in PG17 preflight run 42390557293.
CREATE TEMP TABLE slice24_cases(id text PRIMARY KEY,d numeric,y pastafari_sql_tamil.year_rec);
INSERT INTO slice24_cases VALUES
('anchor',-15055671,ROW(5000,-4,4,-15057703,-15053459)::pastafari_sql_tamil.year_rec),
('boundary_open',-15057703,ROW(5000,-4,4,-15057703,-15053459)::pastafari_sql_tamil.year_rec),
('boundary_close',-15053459,ROW(5000,-4,4,-15057703,-15053459)::pastafari_sql_tamil.year_rec),
('next_1',-15055671,ROW(5001,4,14,-15053459,-15047892)::pastafari_sql_tamil.year_rec),
('next_2',-15055671,ROW(5002,14,23,-15047892,-15043278)::pastafari_sql_tamil.year_rec),
('next_3',-15055671,ROW(5003,23,29,-15043278,-15039840)::pastafari_sql_tamil.year_rec),
('prev_2',-15055671,ROW(4998,-19,-12,-15064992,-15061829)::pastafari_sql_tamil.year_rec),
('prev_3',-15055671,ROW(4997,-29,-19,-15070673,-15064992)::pastafari_sql_tamil.year_rec);
