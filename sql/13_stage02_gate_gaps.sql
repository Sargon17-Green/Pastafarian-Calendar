-- Stage 2 Slice 11: production gate-gap primitive, no cache or reference.
-- தமிழ்: வருட வாயில் இடைவெளிகள்.
-- Signed displacement is an integral nonzero index displacement.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.gate_gap_signed(p_offset numeric)
RETURNS numeric LANGUAGE SQL STABLE STRICT AS $sql$
 SELECT 41::numeric + pastafari_sql_tamil.choose_rank(
   pastafari_sql_tamil.ask_bowl(
     pastafari_sql_tamil.sauce(
       pastafari_sql_tamil.foundation_day(),
       pastafari_sql_tamil.foundation_day() + p_offset
     ), 1, 1
   ), 922::numeric
 )
 WHERE p_offset=trunc(p_offset) AND p_offset<>0
$sql$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.positive_gate_gap(p_n numeric)
RETURNS numeric LANGUAGE SQL STABLE STRICT AS $sql$
 SELECT pastafari_sql_tamil.gate_gap_signed(p_n)
 WHERE p_n=trunc(p_n) AND p_n>0
$sql$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.negative_gate_gap(p_n numeric)
RETURNS numeric LANGUAGE SQL STABLE STRICT AS $sql$
 SELECT pastafari_sql_tamil.gate_gap_signed(-p_n)
 WHERE p_n=trunc(p_n) AND p_n>0
$sql$;
