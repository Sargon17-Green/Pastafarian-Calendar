#!/usr/bin/env python3
"""Strict independent evidence gate for future 4244-symbol Native Chapel runs.

Self-test is Python-only and MUST NOT be reported as Native benchmark PASS.
Native runners must emit separate unrank/rank JSON records and a common word
file. A future Chapel implementation is not supplied or inferred by this gate.
"""
import argparse
import hashlib
import json
import math
import re
import sys
from collections import Counter
from itertools import permutations
from pathlib import Path

MONTH_LENGTHS = (115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
                 97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
                 97,50,122,110,81,54,101,83,88,40,25,77,98,122,105)
ROOT_SHA256 = "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"
WITNESS_SHA256 = "06c6599cdb55601d2a0f2562150a558ac7bc5eae7805251d2007ee9a84c0b488"
CHECKPOINTS = (6,16,32,64,96,128,256,512,1024,2048,4096,4244)
MAX_SECONDS = 180.0
MAX_RSS_KIB = 512*1024
HEX_SHA1 = re.compile(r"[0-9a-f]{40}\Z")
sys.set_int_max_str_digits(10000)


def verify_fifo_word(lengths, word):
    """Independent positional first/last-occurrence order oracle."""
    if Counter(word) != Counter({i+1:k for i,k in enumerate(lengths)}):
        raise ValueError("multiplicity mismatch")
    first = []
    last = []
    for symbol in range(1,len(lengths)+1):
        locations = tuple(i for i,x in enumerate(word) if x==symbol)
        if not locations:
            raise ValueError("missing symbol")
        first.append(locations[0])
        last.append(locations[-1])
    if first != sorted(first) or last != sorted(last):
        raise ValueError("FIFO order violation")
    return len(word)


def count_prefix(lengths, prefix=()):
    """Direct positional oracle for tiny cases; independent dense Python transfer for full year."""
    if sum(lengths)<=8:
        base=tuple(i+1 for i,k in enumerate(lengths) for _ in range(k))
        seen=set(permutations(base))
        return sum(word[:len(prefix)]==tuple(prefix) and
                   tuple(word.index(i) for i in range(1,len(lengths)+1))==
                   tuple(sorted(word.index(i) for i in range(1,len(lengths)+1))) and
                   tuple(len(word)-1-word[::-1].index(i) for i in range(1,len(lengths)+1))==
                   tuple(sorted(len(word)-1-word[::-1].index(i) for i in range(1,len(lengths)+1)))
                   for word in seen)
    from weaving_prefix_transfer import count_prefix as dense_count_prefix
    return dense_count_prefix(lengths, prefix)


def digest_word(word):
    return hashlib.sha256(",".join(map(str,word)).encode("ascii")).hexdigest()


def parse_word(path, lengths):
    raw = Path(path).read_bytes()
    if not raw.endswith(b"\n") or raw.count(b"\n") != 1:
        raise ValueError("witness must be one comma-delimited ASCII line")
    content = raw[:-1]
    if not re.fullmatch(rb"[1-9][0-9]*(,[1-9][0-9]*)*", content):
        raise ValueError("noncanonical witness encoding")
    word = tuple(map(int,content.split(b",")))
    if len(word) != sum(lengths) or Counter(word) != Counter({i+1:k for i,k in enumerate(lengths)}):
        raise ValueError("invalid witness cardinality or multiplicity")
    verify_fifo_word(lengths,word)
    return word


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def verify_pair(unrank, rank, word, source_sha, lengths, checkpoints,
                root, root_digest, witness_digest):
    """Check separate Native claims with positional FIFO and exact dense prefix counts."""
    require(len(word)==sum(lengths),"word length")
    require(verify_fifo_word(lengths,word)==len(word),"FIFO witness")
    require(Counter(word)==Counter({i+1:k for i,k in enumerate(lengths)}),"multiplicity")
    expected_hash = digest_word(word)
    require(expected_hash==witness_digest,"independent witness hash")
    require(root > 0 and 0 <= root//2 < root,"root")
    require(hashlib.sha256(root.to_bytes((root.bit_length()+7)//8,"big")).hexdigest()==root_digest,"root digest")
    require(HEX_SHA1.fullmatch(source_sha) is not None,"source SHA syntax")
    observed = {}
    for direction,record in (("unrank",unrank),("rank",rank)):
        require(type(record) is dict,"JSON object")
        require(set(record)=={"schema","source_sha","direction","chapel_version","status",
                              "elapsed_seconds","peak_rss_kib","root_bits","root_sha256",
                              "median_rank","residual","result_rank","witness_sha256",
                              "checkpoints","stage6_acceptance"},"record fields")
        require(record["schema"]==1,"schema")
        require(record["source_sha"]==source_sha,"wrong source SHA")
        require(record["direction"]==direction,"direction swapped")
        require(record["chapel_version"]=="2.10.0","Chapel version")
        require(record["status"]=="COMPLETE","noncomplete direction")
        require(record["stage6_acceptance"]=="NOT_CLAIMED","stage boundary")
        seconds=record["elapsed_seconds"]
        require(type(seconds) in (float,int) and math.isfinite(seconds) and 0<seconds<=MAX_SECONDS,"elapsed time")
        rss=record["peak_rss_kib"]
        require(type(rss) is int and 0<rss<=MAX_RSS_KIB,"peak RSS")
        require(record["root_bits"]==root.bit_length(),"root bits")
        require(record["root_sha256"]==root_digest,"root fingerprint")
        require(str(record["median_rank"])==str(root//2),"median rank")
        require(record["witness_sha256"]==expected_hash,"witness identity")
        if direction=="unrank":
            require(record["residual"]=="0" and record["result_rank"] is None,"unrank residual")
        else:
            require(record["residual"] is None and str(record["result_rank"])==str(root//2),"reverse rank")
        entries=record["checkpoints"]
        require(type(entries) is list and len(entries)==len(checkpoints),"checkpoint cardinality")
        for expected_depth, entry in zip(checkpoints,entries):
            require(type(entry) is dict and set(entry)=={"depth","prefix_sha256","count"},"checkpoint fields")
            require(type(entry["depth"]) is int and entry["depth"]==expected_depth,"checkpoint depth/order")
            require(entry["prefix_sha256"]==digest_word(word[:expected_depth]),"checkpoint hash")
            require(type(entry["count"]) is str and re.fullmatch(r"0|[1-9][0-9]*",entry["count"]) is not None,"count syntax")
            if expected_depth not in observed:
                observed[expected_depth]=count_prefix(lengths,word[:expected_depth])
            require(int(entry["count"])==observed[expected_depth],"independent dense count")
    require(observed[checkpoints[-1]]==1,"complete word must be unique")
    return len(checkpoints)*2


def self_test():
    lengths=(2,2)
    word=(1,2,1,2)
    root=count_prefix(lengths,())
    require(root==2,"fixture total")
    checkpoints=(1,2,3,4)
    base={"schema":1,"source_sha":"a"*40,"direction":"unrank",
          "chapel_version":"2.10.0","status":"COMPLETE",
          "elapsed_seconds":1.0,"peak_rss_kib":2048,
          "root_bits":root.bit_length(),
          "root_sha256":hashlib.sha256(root.to_bytes(1,"big")).hexdigest(),
          "median_rank":str(root//2),"residual":"0","result_rank":None,
          "witness_sha256":digest_word(word),
          "checkpoints":[{"depth":d,"prefix_sha256":digest_word(word[:d]),
                          "count":str(count_prefix(lengths,word[:d]))} for d in checkpoints],
          "stage6_acceptance":"NOT_CLAIMED"}
    reverse=json.loads(json.dumps(base))
    reverse.update(direction="rank",residual=None,result_rank=str(root//2))
    args=(word,base["source_sha"],lengths,checkpoints,root,base["root_sha256"],digest_word(word))
    require(verify_pair(base,reverse,*args)==8,"positive selftest")
    cases=0
    for key,value in (("status","INCONCLUSIVE"),("elapsed_seconds",180.1),
                      ("peak_rss_kib",524289),("source_sha","f"*40),
                      ("witness_sha256","0"*64),("median_rank","0"),
                      ("stage6_acceptance","PASS")):
        altered=json.loads(json.dumps(base))
        altered[key]=value
        try:
            verify_pair(altered,reverse,*args)
        except AssertionError:
            cases+=1
        else:
            raise AssertionError("mutation escaped: "+key)
    for change in (lambda x:x["checkpoints"].pop(),
                   lambda x:x["checkpoints"][2].update(count="0"),
                   lambda x:x["checkpoints"][1].update(prefix_sha256="0"*64)):
        altered=json.loads(json.dumps(base))
        change(altered)
        try:
            verify_pair(altered,reverse,*args)
        except AssertionError:
            cases+=1
        else:
            raise AssertionError("checkpoint mutation escaped")
    require(cases==10,"selftest mutation count")
    print("NATIVE_MEDIAN_EVIDENCE_SELFTEST_POSITIVE=1")
    print("NATIVE_MEDIAN_EVIDENCE_SELFTEST_MUTATIONS=10")
    print("NATIVE_MEDIAN_EVIDENCE_SELFTEST_RESULT=PASS")
    print("NATIVE_MEDIAN_EVIDENCE_NATIVE_4244=NOT_TESTED")
    print("NATIVE_MEDIAN_EVIDENCE_STAGE6_ACCEPTANCE=NOT_CLAIMED")


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--self-test",action="store_true")
    group.add_argument("--verify",action="store_true")
    for name in ("unrank-log","rank-log","word-file","source-sha"):
        parser.add_argument("--"+name)
    args=parser.parse_args()
    if args.self_test:
        self_test()
        return
    require(all((args.unrank_log,args.rank_log,args.word_file,args.source_sha)),"missing evidence input")
    word=parse_word(args.word_file,MONTH_LENGTHS)
    root=count_prefix(MONTH_LENGTHS,())
    require(root.bit_length()==22470,"root size lock")
    checks=verify_pair(json.loads(Path(args.unrank_log).read_text(encoding="utf8")),
                       json.loads(Path(args.rank_log).read_text(encoding="utf8")),
                       word,args.source_sha,MONTH_LENGTHS,CHECKPOINTS,
                       root,ROOT_SHA256,WITNESS_SHA256)
    require(checks==24,"checkpoint count")
    print("NATIVE_MEDIAN_EVIDENCE_INDEPENDENT_DENSE_CHECKS=24")
    print("NATIVE_MEDIAN_EVIDENCE_FIFO_WORD_POSITIONS=4244")
    print("NATIVE_MEDIAN_EVIDENCE_WITNESS_SHA256="+WITNESS_SHA256)
    print("NATIVE_MEDIAN_EVIDENCE_RESULT=PASS")
    print("NATIVE_MEDIAN_EVIDENCE_STAGE6_ACCEPTANCE=NOT_CLAIMED")


if __name__=="__main__":
    main()
