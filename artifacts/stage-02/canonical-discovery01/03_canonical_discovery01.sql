-- Stage02 DISCOVERY 01: பழைய மீதி வழி; திருத்தம் இங்கு இல்லை.
-- இந்தக் கோப்பு தனியான Stage01 அடிப்படை தரவுத்தளத்திற்கு மட்டும்.
CREATE FUNCTION pastafari_sql_tamil.old_remainder(p_x numeric)
RETURNS numeric
LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT CASE
        WHEN p_x IN ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric) THEN NULL::numeric
        WHEN p_x <> trunc(p_x) THEN NULL::numeric
        ELSE CASE WHEN mod(p_x,170141183460469231731687303715884105727::numeric)<0
            THEN mod(p_x,170141183460469231731687303715884105727::numeric)
               +170141183460469231731687303715884105727::numeric
            ELSE mod(p_x,170141183460469231731687303715884105727::numeric)
        END
    END
$$;

-- உண்மையான சேமிப்பு நுழைவாயில் பழைய மீதியை அழைக்கிறது.
CREATE FUNCTION pastafari_sql_tamil.save_value(p_x numeric)
RETURNS numeric
LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT pastafari_sql_tamil.old_remainder(p_x)
$$;
