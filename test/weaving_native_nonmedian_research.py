#!/usr/bin/env python3
"""Research-only Chapel 4244 exact ranks median-1 and median+1.

Each of four Native directions is a separate OS-measured process. The median
itself is NOT executed here. Exact independent dense prefix counts and a
separate Python/GMP reverse-rank algorithm validate every completed pair.
A partial/timeout result cannot be accepted; no Stage6 or production claim.
"""
import argparse
import hashlib
import json
import re
import sys
import time
from pathlib import Path

import run_native_4244_research as native
import weaving_native_median_evidence_gate as oracle

DEPTHS = oracle.CHECKPOINTS
LENGTHS = oracle.MONTH_LENGTHS
PAIRS = ((-1, "minus_one"), (1, "plus_one"))
sys.set_int_max_str_digits(10000)


def require(ok, message):
    if not ok:
        raise ValueError(message)


def sha_root(root):
    return hashlib.sha256(root.to_bytes((root.bit_length()+7)//8, "big")).hexdigest()


def parse_trace(raw, direction, expected_rank, expected_root, lengths, depths,
                delta=None):
    require(raw.endswith(b"\n") and b"\r" not in raw and raw.isascii(),
            "noncanonical or incomplete stdout")
    lines = raw.decode("ascii").splitlines()
    extras = ["NATIVE_NONMEDIAN_RANK_DELTA="+str(delta)] if delta else []
    require(len(lines)==len(depths)+4+len(extras), "unexpected transcript lines")
    require(lines[0] == "NATIVE_MEDIAN_ROOT="+str(expected_root), "root mismatch")
    pos=1
    if extras:
        require(lines[pos] == extras[0], "rank offset mismatch")
        pos+=1
    entries=[]
    for depth in depths:
        prefix="NATIVE_MEDIAN_CHECKPOINT="+str(depth)+";"
        require(lines[pos].startswith(prefix), "checkpoint missing/out of order")
        count=lines[pos][len(prefix):]
        require(re.fullmatch(r"[1-9][0-9]*",count) is not None,
                "checkpoint count not canonical/positive")
        entries.append((depth,int(count)))
        pos+=1
    word_prefix="NATIVE_MEDIAN_WORD="
    require(lines[pos].startswith(word_prefix), "missing witness")
    encoded=lines[pos][len(word_prefix):]
    require(re.fullmatch(r"[1-9][0-9]*(,[1-9][0-9]*)*",encoded) is not None,
            "invalid witness encoding")
    word=tuple(int(x) for x in encoded.split(","))
    require(len(word)==sum(lengths), "witness cardinality")
    oracle.verify_fifo_word(lengths,word)
    pos+=1
    if direction=="unrank":
        require(lines[pos]=="NATIVE_MEDIAN_RESIDUAL=0", "nonzero residual")
    else:
        require(lines[pos]=="NATIVE_MEDIAN_RESULT_RANK="+str(expected_rank),
                "reverse rank mismatch")
    require(lines[pos+1]=="NATIVE_MEDIAN_COMPLETE=1", "not complete")
    require(pos+2==len(lines), "unapproved trailing output")
    require(expected_root>0, "invalid root")
    for depth, count in entries:
        require(oracle.count_prefix(lengths,word[:depth])==count,
                "independent dense prefix count mismatch at "+str(depth))
    require(entries[-1][1]==1, "terminal count mismatch")
    return word,entries


def independently_rank(word, expected_root, expected_rank):
    # GMP implementation is separate from Chapel and the dense prefix oracle.
    import weaving_gmpy2_backend_probe as g
    saved=g.dual.sparse_transfer
    try:
        g.dual.sparse_transfer=g.gmp_transfer
        state=g.dual.SparseDualWeaving(LENGTHS)
        require(int(state.total)==expected_root, "GMP root mismatch")
        ordinal=0
        for symbol in word:
            blocks=state.blocks()
            require(sum(blocks)==state.total, "GMP candidate partition")
            require(blocks[symbol]>0, "GMP illegal symbol")
            ordinal+=sum(map(int,blocks[1:symbol]))
            state.take(symbol)
        require(int(state.total)==1, "GMP terminal mismatch")
        require(ordinal==expected_rank, "independent GMP lexical rank mismatch")
        return ordinal
    finally:
        g.dual.sparse_transfer=saved


def synthetic_transcript(direction,word,root,rank,depths,delta=None):
    lines=["NATIVE_MEDIAN_ROOT="+str(root)]
    if delta: lines+=["NATIVE_NONMEDIAN_RANK_DELTA="+str(delta)]
    lines+=["NATIVE_MEDIAN_CHECKPOINT="+str(d)+";"+
            str(oracle.count_prefix((2,2),word[:d])) for d in depths]
    lines+=["NATIVE_MEDIAN_WORD="+",".join(map(str,word))]
    lines+=["NATIVE_MEDIAN_RESIDUAL=0" if direction=="unrank"
            else "NATIVE_MEDIAN_RESULT_RANK="+str(rank)]
    lines+=["NATIVE_MEDIAN_COMPLETE=1"]
    return ("\n".join(lines)+"\n").encode("ascii")


def self_test():
    lengths=(2,2)
    legal=((1,1,2,2),(1,2,1,2))
    root=oracle.count_prefix(lengths)
    require(root==2, "synthetic root")
    depths=(1,2,3,4)
    positives=0
    negatives=0
    for rank,word in enumerate(legal):
        for direction in ("unrank","rank"):
            delta=-1 if direction=="unrank" else None
            raw=synthetic_transcript(direction,word,root,rank,depths,delta)
            got,_=parse_trace(raw,direction,rank,root,lengths,depths,delta)
            require(got==word, "positive selftest")
            positives+=1
            variants=[
                raw[:-1],
                raw.replace(b"NATIVE_MEDIAN_COMPLETE=1",b"NATIVE_MEDIAN_COMPLETE=0"),
                raw.replace(b"NATIVE_MEDIAN_ROOT=2",b"NATIVE_MEDIAN_ROOT=3"),
                raw.replace(b"NATIVE_MEDIAN_CHECKPOINT=1;1",
                            b"NATIVE_MEDIAN_CHECKPOINT=1;2"),
                raw.replace(b"NATIVE_MEDIAN_WORD=",b"NATIVE_MEDIAN_WORD=9,"),
                raw+b"EXTRA=1\n",
            ]
            if direction=="unrank":
                variants.append(raw.replace(b"NATIVE_NONMEDIAN_RANK_DELTA=-1",
                                            b"NATIVE_NONMEDIAN_RANK_DELTA=1"))
            else:
                variants.append(raw.replace(
                    ("NATIVE_MEDIAN_RESULT_RANK="+str(rank)).encode(),
                    b"NATIVE_MEDIAN_RESULT_RANK=3"))
            for variant in variants:
                require(variant!=raw,"non-mutating selftest fixture")
                try:
                    parse_trace(variant,direction,rank,root,lengths,depths,delta)
                except (ValueError,AssertionError):
                    negatives+=1
                else:
                    raise AssertionError("evidence mutation was accepted")
    print("NATIVE_NONMEDIAN_SELFTEST_POSITIVE="+str(positives))
    print("NATIVE_NONMEDIAN_SELFTEST_MUTATION_REJECTS="+str(negatives))
    print("NATIVE_NONMEDIAN_SELFTEST_RESULT=PASS")
    print("NATIVE_NONMEDIAN_4244=NOT_TESTED")
    print("NATIVE_NONMEDIAN_STAGE6=NOT_CLAIMED")


def execute(args):
    actual_sha=native.subprocess.check_output(
        ["git","rev-parse","HEAD"],text=True).strip()
    require(actual_sha==args.source_sha and
            re.fullmatch(r"[a-f0-9]{40}",actual_sha) is not None,
            "source HEAD mismatch")
    version=native.subprocess.check_output(
        ["chpl","--version"],text=True).splitlines()[0]
    require("2.10.0" in version, "wrong Chapel version")
    binary=args.binary.resolve()
    binary_sha=hashlib.sha256(binary.read_bytes()).hexdigest()
    args.outdir.mkdir(parents=True,exist_ok=True)
    (args.outdir/"provenance.json").write_text(json.dumps({
        "source_sha":actual_sha,"binary_sha256":binary_sha,
        "chapel_version":version,"target_offsets":[-1,1],
        "stage6":"NOT_CLAIMED"},sort_keys=True)+"\n")
    root=oracle.count_prefix(LENGTHS)
    require(root.bit_length()==22470 and sha_root(root)==oracle.ROOT_SHA256,
            "independent exact root lock")
    pairs_passed=0
    for delta,name in PAIRS:
        pair_dir=args.outdir/name
        pair_dir.mkdir(parents=True,exist_ok=True)
        target=root//2+delta
        ures,upath=native.run_native(binary,pair_dir,"unrank",rank_delta=delta)
        if ures["status"]!="COMPLETE" or ures["exit_code"]!=0:
            print("NATIVE_NONMEDIAN_"+name.upper()+"="+ures["status"],flush=True)
            print("NATIVE_NONMEDIAN_RESULT=NOT_ACCEPTED")
            return 0 if ures["status"].startswith("INCONCLUSIVE") else 1
        word,ue=parse_trace(upath.read_bytes(),"unrank",target,root,LENGTHS,
                            DEPTHS,delta)
        (pair_dir/"word.txt").write_text(",".join(map(str,word))+"\n",
                                         encoding="ascii")
        rres,rpath=native.run_native(binary,pair_dir,"rank",word=word)
        if rres["status"]!="COMPLETE" or rres["exit_code"]!=0:
            print("NATIVE_NONMEDIAN_"+name.upper()+"_RANK="+rres["status"],
                  flush=True)
            print("NATIVE_NONMEDIAN_RESULT=NOT_ACCEPTED")
            return 0 if rres["status"].startswith("INCONCLUSIVE") else 1
        ranked_word,re=parse_trace(rpath.read_bytes(),"rank",target,root,
                                   LENGTHS,DEPTHS)
        require(word==ranked_word, "roundtrip word differs")
        independent=independently_rank(word,root,target)
        evidence={
            "schema":1,"source_sha":actual_sha,"binary_sha256":binary_sha,
            "chapel_version":"2.10.0","offset":delta,"rank":str(target),
            "root_sha256":oracle.ROOT_SHA256,
            "witness_sha256":oracle.digest_word(word),
            "word_symbols":len(word),"independent_gmp_rank":str(independent),
            "independent_dense_comparisons":len(ue)+len(re),
            "unrank":ures,"rank_direction":rres,
            "unrank_checkpoints":[{"depth":d,"count":str(n)} for d,n in ue],
            "rank_checkpoints":[{"depth":d,"count":str(n)} for d,n in re],
            "status":"PASS_RESEARCH_ONLY","stage6":"NOT_CLAIMED"}
        require(evidence["independent_dense_comparisons"]==24,
                "dense checkpoint cardinality")
        (pair_dir/"validated.json").write_text(
            json.dumps(evidence,sort_keys=True)+"\n")
        pairs_passed+=1
        print("NATIVE_NONMEDIAN_"+name.upper()+"=PASS_RESEARCH_ONLY",flush=True)
    require(pairs_passed==2,"both offsets required")
    print("NATIVE_NONMEDIAN_PAIRS=2")
    print("NATIVE_NONMEDIAN_NATIVE_DIRECTIONS=4")
    print("NATIVE_NONMEDIAN_INDEPENDENT_DENSE_CHECKS=48")
    print("NATIVE_NONMEDIAN_RESULT=PASS_RESEARCH_ONLY")
    print("NATIVE_NONMEDIAN_STAGE6=NOT_CLAIMED")
    return 0


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--self-test",action="store_true")
    p.add_argument("--binary",type=Path)
    p.add_argument("--source-sha")
    p.add_argument("--outdir",type=Path)
    args=p.parse_args()
    if args.self_test:
        require(not (args.binary or args.source_sha or args.outdir),
                "self-test excludes Native options")
        self_test()
        return 0
    require(args.binary is not None and args.source_sha and args.outdir,
            "missing Native input")
    try:
        return execute(args)
    except (ValueError,AssertionError) as exc:
        print("NATIVE_NONMEDIAN_GATE_FAILURE="+str(exc),file=sys.stderr)
        return 1


if __name__=="__main__":
    sys.exit(main())
