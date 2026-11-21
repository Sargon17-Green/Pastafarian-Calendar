#!/usr/bin/env python3
"""QA-only exact-source sauce hot-path tracing, without changing production."""
from __future__ import annotations
import argparse
import hashlib
from pathlib import Path

P="pastafari_sql_tamil."
LOCK={
 "sql/04_stage02_stone_states.sql":"caed82dc41d7a259953dc817d5e0722038821310",
 "sql/08_stage02_bowl_round.sql":"68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6",
 "sql/10_stage02_sauce.sql":"c5c6be7c02c255382ae7c317bfbf17138a12788c",
}
def sources():
    out={}
    for path,sha in LOCK.items():
        b=Path(path).read_bytes()
        actual=hashlib.sha1(b"blob "+str(len(b)).encode()+b"\0"+b).hexdigest()
        assert actual==sha,("source lock",path,actual)
        out[path]=b.decode("utf-8")
    return out

def definition(text,name):
    anchor="CREATE OR REPLACE FUNCTION "+P+name+"("
    assert text.count(anchor)==1,("function",name)
    i=text.index(anchor)
    j=text.find("\nCREATE OR REPLACE FUNCTION ",i+len(anchor))
    return text[i:j if j>=0 else len(text)].strip()+"\n"

def clone(text,name,extra):
    original=definition(text,name)
    ops=[("CREATE OR REPLACE FUNCTION "+P+name+"(",
          "CREATE OR REPLACE FUNCTION "+P+"qa_hot_"+name+"(",1)]
    if "LANGUAGE SQL IMMUTABLE STRICT" in original:
        ops.append(("LANGUAGE SQL IMMUTABLE STRICT","LANGUAGE SQL VOLATILE STRICT",1))
    else:
        assert "LANGUAGE SQL STABLE STRICT" in original
        ops.append(("LANGUAGE SQL STABLE STRICT","LANGUAGE SQL VOLATILE STRICT",1))
    ops+=extra
    result=original
    for a,b,n in ops:
        assert result.count(a)==n,(name,a,result.count(a))
        result=result.replace(a,b)
    reverse=result
    for a,b,n in reversed(ops):
        assert reverse.count(b)==n,("reverse",name,b)
        reverse=reverse.replace(b,a)
    assert reverse==original,("non-reversible",name)
    return result

def trace(name,args,ret,call,tag):
    return f"""CREATE OR REPLACE FUNCTION {P}qa_hot_trace_{name}({args})
RETURNS {ret} LANGUAGE plpgsql VOLATILE STRICT AS $hot$
DECLARE v {ret}; t timestamptz := clock_timestamp();
BEGIN
  RAISE NOTICE 'SQL_TAMIL_HOT_ENTER={name}:%', ({tag})::text;
  v := {call};
  RAISE NOTICE 'SQL_TAMIL_HOT_EXIT={name}:%:%', ({tag})::text,
    round(extract(epoch FROM clock_timestamp()-t)*1000,3);
  RETURN v;
END;
$hot$;
"""

def generate(s):
    stone=s["sql/04_stage02_stone_states.sql"]
    bowl=s["sql/08_stage02_bowl_round.sql"]
    sauce=s["sql/10_stage02_sauce.sql"]
    out=[
      trace("stone_state","p_index integer",P+"stone5",
            P+"stone_state(p_index)","p_index"),
      clone(stone,"stone_value",[(P+"stone_state(",P+"qa_hot_trace_stone_state(",1)]),
      trace("stone_value","p_index integer,p_kind integer","numeric",
            P+"qa_hot_stone_value(p_index,p_kind)","p_index"),
      clone(bowl,"bowl_round",[(P+"stone_value(",P+"qa_hot_trace_stone_value(",4)]),
      trace("bowl_round","p_bowls numeric[],p_drop numeric,p_i integer","numeric[]",
            P+"qa_hot_bowl_round(p_bowls,p_drop,p_i)","p_i"),
      trace("post_stir_chain","p_bowls numeric[]","numeric[]",
            P+"post_stir_chain(p_bowls)","array_length(p_bowls,1)"),
      clone(sauce,"sauce",[
          (P+"bowl_round(",P+"qa_hot_trace_bowl_round(",1),
          (P+"post_stir_chain(",P+"qa_hot_trace_post_stir_chain(",1)]),
      trace("sauce","p_calculation_day numeric,p_target_day numeric",P+"sauce_result",
            P+"qa_hot_sauce(p_calculation_day,p_target_day)","p_target_day")
    ]
    text="\n".join(out)
    for name in ("stone_value","bowl_round","sauce"):
        assert "CREATE OR REPLACE FUNCTION "+P+name+"(" not in text
        assert "CREATE OR REPLACE FUNCTION "+P+"qa_hot_"+name+"(" in text
    return text

PROBE=r"""\set ON_ERROR_STOP on
SET statement_timeout = '75s';
DO $single$
DECLARE
 v_original pastafari_sql_tamil.sauce_result;
 v_qa pastafari_sql_tamil.sauce_result;
 v_stone numeric;
BEGIN
 RAISE NOTICE 'SQL_TAMIL_HOT_CASE=signed_negative_offset_1';
 v_stone := pastafari_sql_tamil.qa_hot_trace_stone_value(46,1);
 IF v_stone IS NULL OR v_stone IS DISTINCT FROM pastafari_sql_tamil.stone_value(46,1) THEN
   RAISE EXCEPTION 'stone clone differs from production';
 END IF;
 RAISE NOTICE 'SQL_TAMIL_HOT_STONE_EQUIVALENCE=1/1 PASS';
 v_original := pastafari_sql_tamil.sauce(-15055671,-15055672);
 v_qa := pastafari_sql_tamil.qa_hot_trace_sauce(-15055671,-15055672);
 IF v_original IS NULL OR v_qa IS DISTINCT FROM v_original THEN
   RAISE EXCEPTION 'sauce clone differs from production';
 END IF;
 RAISE NOTICE 'SQL_TAMIL_HOT_SAUCE_EQUIVALENCE=1/1 PASS';
END;
$single$;
"""

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--self-test",action="store_true")
    p.add_argument("--out-dir",type=Path)
    args=p.parse_args()
    if not args.self_test and args.out_dir is None:
        p.error("must choose --self-test or --out-dir")
    s=sources()
    sql=generate(s)
    assert sql==generate(s)
    assert "statement_timeout = '75s'" in PROBE
    if args.self_test:
        bad=dict(s)
        k="sql/08_stage02_bowl_round.sql"
        bad[k]=bad[k].replace(P+"stone_value(",P+"wrong(",1)
        try: generate(bad)
        except AssertionError: pass
        else: raise AssertionError("mutated source not rejected")
        print("SQL_TAMIL_HOT_SOURCE_LOCKS=3/3 PASS")
        print("SQL_TAMIL_HOT_REVERSIBLE_CLONES=3/3 PASS")
        print("SQL_TAMIL_HOT_MUTATION_REJECTED=PASS")
        print("SQL_TAMIL_HOT_NATIVE=NOT_EXECUTED")
    if args.out_dir:
        args.out_dir.mkdir(parents=True,exist_ok=True)
        (args.out_dir/"hotspot_aliases.sql").write_text(sql,encoding="utf-8")
        (args.out_dir/"hotspot_probe.sql").write_text(PROBE,encoding="utf-8")
        print("SQL_TAMIL_HOT_GENERATED=2; PRODUCTION_MODIFIED=NO")
if __name__=="__main__":
    main()
