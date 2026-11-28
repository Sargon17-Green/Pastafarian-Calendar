#!/usr/bin/env python3
"""Independent fail-closed one-line Befunge-98 grammar evidence audit."""
import copy,json,sys
from pathlib import Path
SIGN=(0,2,5,7,9,11,13,15,17,19,21)
MAG=(1,3,6,8,10,12,14,16,18,20,22)
def require(c,m):
    if not c:raise AssertionError(m)
def canonical():
    fields=["0","100","0","0","9"]
    for k in range(9):
        fields.extend(["0",str(k*42)])
    return fields+["1"]
def make():
    base=canonical()
    enc=lambda t:" ".join(t)
    result=[
      ("plain",enc(base),1),
      ("whitespace","  "+"\t  ".join(base)+"   ",1),
      ("negative_day",enc(["1","100"]+base[2:]),1),
      ("negative_index",enc(base[:2]+["1","7"]+base[4:]),1),
      ("negative_gate",enc(base[:5]+["1","7"]+base[7:]),1),
      ("long_magnitude",enc(base[:1]+["9"*70]+base[2:]),1),
      ("leading_magnitude_zeros",enc(base[:1]+["000100"]+base[2:]),1),
      ("rank_three",enc(base[:-1]+["3"]),1),
      ("empty","",-1),("whitespace_only","  \t ",-1),
      ("early_linebreak",enc(base[:12])+"\n"+enc(base[12:]),-1),
      ("extra_same_line",enc(base)+" 1",-1),
      ("rank_zero",enc(base[:-1]+["0"]),-1),
      ("gate_count_eight",enc(base[:4]+["8"]+base[5:]),-1),
      ("gate_count_ten",enc(base[:4]+["10"]+base[5:]),-1),
      ("gate_count_two_digits",enc(base[:4]+["09"]+base[5:]),-1),
      ("tab_only_between","\t".join(base),1),
      ("invalid_cr",enc(base)+"\r",-1),
      ("multi_line_post_lf_not_checked",enc(base)+"\nEXTRA INVALID",1)
    ]
    for position in range(len(base)):
        for prefix,label in (("-","negative_token"),("+","positive_sign_token")):
            x=list(base);x[position]=prefix+x[position]
            result.append(("%s_%02d"%(label,position),enc(x),-1))
        x=list(base);x[position]="garbage"
        result.append(("nondigit_token_%02d"%position,enc(x),-1))
        x=list(base);x.pop(position)
        result.append(("missing_field_%02d"%position,enc(x),-1))
    for position in SIGN:
        for val in ("2","00","01"):
            x=list(base);x[position]=val
            result.append(("bad_sign_%02d_%s"%(position,val),enc(x),-1))
    for position in MAG:
        x=list(base);x[position-1]="1";x[position]="0"
        result.append(("negative_zero_%02d"%position,enc(x),-1))
    for position,val in ((0,"1.0"),(4,"9x"),(23,"1,2"),(2,"0x0")):
        x=list(base);x[position]=val
        result.append(("punctuation_%02d"%position,enc(x),-1))
    return result
def verify(doc):
    require(type(doc) is dict and
            doc.get("schema")=="befunge-stage1-24token-one-line-native-grammar-v1" and
            doc.get("scope")=="FIRST_LINE_24_FIELDS_ONLY_NOT_EOF_CERTIFIED_STAGE1_OPEN" and
            doc.get("last_completed_stage")==0 and type(doc.get("last_completed_stage")) is int and
            doc.get("production_modified") is False and
            doc.get("full_functional_acceptance") is False and
            doc.get("post_newline_unverified") is True,
            "Native grammar metadata or acceptance scope misreported")
    specification=make()
    found=doc.get("records")
    require(type(found) is list and len(found)==len(specification) and
            type(doc.get("case_count")) is int and
            doc["case_count"]==len(specification),
            "Native grammar evidence missing or extra")
    for row,(label,raw,expected) in zip(found,specification):
        require(type(row) is dict and row.get("case")==label and
                row.get("raw")==raw and
                row.get("expected_output")==[expected] and
                row.get("native_output")==[expected] and
                type(row.get("return_code")) is int and row["return_code"]==0,
                "Native grammar tamper at "+label)
    return len(specification)
def main(root):
    directory=Path(root)
    doc=json.loads((directory/"native_year5000_24token_grammar.json").read_text("utf-8"))
    n=verify(doc)
    tests=[
      ("scope",lambda z:z.__setitem__("scope","COMPLETE")),
      ("count",lambda z:z.__setitem__("case_count",n+1)),
      ("stage",lambda z:z.__setitem__("last_completed_stage",1)),
      ("functional",lambda z:z.__setitem__("full_functional_acceptance",True)),
      ("production",lambda z:z.__setitem__("production_modified",True)),
      ("eof",lambda z:z.__setitem__("post_newline_unverified",False)),
      ("missing",lambda z:z["records"].pop()),
      ("reordered",lambda z:z["records"].reverse()),
      ("input",lambda z:z["records"][0].__setitem__("raw","0")),
      ("malformed_accepted",lambda z:z["records"][23].__setitem__("native_output",[1])),
      ("valid_rejected",lambda z:z["records"][0].__setitem__("native_output",[-1])),
      ("return",lambda z:z["records"][0].__setitem__("return_code",1))
    ]
    rejected=[]
    for name,action in tests:
        trial=copy.deepcopy(doc);action(trial)
        try:verify(trial)
        except AssertionError:rejected.append(name)
        else:raise AssertionError("accepted forged native grammar report "+name)
    response={"schema":"befunge-stage1-24token-native-grammar-independent-audit-v1",
              "native_cases_checked":n,"hostile_evidence_rejected":rejected,
              "last_completed_stage":0,"post_newline_unverified":True}
    (directory/"native_year5000_24token_grammar_audit.json").write_text(
        json.dumps(response,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_24TOKEN_GRAMMAR_%d_CASES_12_TAMPER_REJECT_PASS"%n)
if __name__=="__main__":
    require(len(sys.argv)==2,"evidence folder required")
    main(sys.argv[1])
