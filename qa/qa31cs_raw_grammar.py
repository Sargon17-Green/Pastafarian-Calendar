"""Prove the active scanner's byte grammar, then test actual unmodified streams in native PyFunge."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

ACTIVE="src/work_counts.b98"
REF="reference/work_counts.b98"
SAVE="reference/save.b98"
SOURCE_IDS={ACTIVE:"7418e1ec5fe88fe5c14b75710dea2d5607527f28",REF:"f941efc793c9eee4accf5d03873f8ed029b16725",
            SAVE:"7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44"}
GRAMMAR=rb"[ \t\r\n]*([0-9]+)[ \t\r\n]+([0-9]+)[ \t\r\n]+([0-9]+)[ \t\r\n]+([0-9]+)[ \t\r\n]*"
BAD=(("empty",b""),("three-at-eof",b"0 1 0"),("fifth-field",b"0 1 0 2 0"),
     ("doubled-space-missing-final",b"0 1  0 "),("tab-joined-fifth",b"0\t1\t0\t2\t3"),("crlf-missing",b"0 1\r\n0"),
     ("junk-after-lf",b"0 1 0 2\nX"),("nul-after-four",b"0 1 0 2\0"),("vertical-tab",b"0\v1 0 2"),
     ("form-feed",b"0 1\f0 2"),("arabic-indic-digit",b"0 1 0 \xd9\xa2"),("nonbreaking-space",b"0 1\xc2\xa0" b"0 2"))
GOOD=(("bare-eof",b"0 1 0 2"),("leading-space",b" 0 1 0 2"),("double-space",b"0  1 0 2"),
      ("tabs",b"0\t1\t0\t2"),("crlf-inside",b"0\r\n1 0 2"),("fourth-field-lf",b"0 1 0 2\n"),
      ("all-separators",b"\r0 \t\r\n1 0 2\t\r\n"),("leading-zeroes",b"01 00012 00 021"),
      ("multi-line-final-eof",b"0\n21\r1\t12"))


def need(value,why):
    if not value:
        raise ValueError(why)


def prove():
    from qa31ch_scanner_induction import Scanner,prove as source_proof
    for path,expected in SOURCE_IDS.items():
        raw=Path(path).read_bytes()
        need(hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()==expected,"source identity "+path)
    proof=source_proof(Scanner(Path(ACTIVE).read_bytes().split(b"\n")))
    need(proof["transitions"]==9*257,"scanner proof incomplete")
    return proof


def native(path,data):
    run=subprocess.run(["pyfunge","--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2",path],
                       input=data,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=50,check=True)
    return run.stdout.decode("ascii").split()


def audit(rows):
    need(len(rows)==len(BAD)+len(GOOD),"wrong number of raw streams")
    for (label,data),row in zip(BAD+GOOD,rows):
        matched=re.fullmatch(GRAMMAR,data)
        need(row["label"]==label and bytes.fromhex(row["raw_hex"])==data and
             bool(matched)==(label in dict(GOOD)),"stream class "+label)
        if matched:
            need(row["tokens"]==[int(s) for s in matched.groups()] and
                 [len(block) for block in row["oracle"]]==[5,1,1] and
                 row["output"]==sum(row["oracle"],[]) and row["output"]!=["-1"]*7,"reference "+label)
        else:
            need(row["oracle"]==[] and row["output"]==["-1"]*7,"rejection "+label)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt",type=Path)
    parser.add_argument("--verify",action="store_true")
    args=parser.parse_args()
    proof=prove()
    if args.verify:
        data=json.loads(args.receipt.read_bytes())
        need(data["source_ids"]==SOURCE_IDS and data["scanner"]==json.loads(json.dumps(proof)),"source proof")
        audit(data["rows"])
    else:
        rows=[]
        for label,data in BAD+GOOD:
            match=re.fullmatch(GRAMMAR,data)
            fields=[int(s) for s in match.groups()] if match else []
            norm=b" ".join(str(v).encode() for v in fields).split()
            parts=[native(path,b" ".join(f)+b"\n") for path,f in
                   [(REF,norm),(SAVE,norm[:2]),(SAVE,norm[2:])]] if match else []
            rows.append(dict(label=label,raw_hex=data.hex(),tokens=fields,output=native(ACTIVE,data),oracle=parts))
        audit(rows)
        args.receipt.write_text(json.dumps(dict(source_ids=SOURCE_IDS,scanner=proof,rows=rows),indent=2,sort_keys=True)+"\n")
    print("QA31CS_SOURCE_AND_RAW_BYTES_PASS",proof["transitions"],"transitions; 12 bad, 9 good, 48 Native executions")


if __name__=="__main__":
    main()
