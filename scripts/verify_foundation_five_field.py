#!/usr/bin/env python3
"""Stage1 Foundation-only integration. Reuse accepted native H/word, never regenerate H."""
import argparse
import csv
import hashlib
import pathlib
import re
import resource
import subprocess
import zipfile

BASE = "65224e549190167995d6022ed4c3f58a76e231a8"
QA = "50aac9c476ac853b7c67cb37a6f4ebcb052fd43c"
ZIP_SHA = "a03f8fce34ec083190889cec72f5a2361e5c3e4b27727a090e8d35f5926bb8aa"
WORD_SHA = "e1a291eafc34153031a0fba5e8ae0bc99a06cf0c59f4a65665c5b027b56c3a29"
NORM = (5000, 10, 503, 20, 56)
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "foundation_five_field"
JOIN = r"""
module foundation_five_field_join;
 integer g,n,w,i,k,rc,opn,cls,cutlet,cutday,pos,ordinal,occurrence,symbol,extra;
 integer names[1:45],seen[1:47],counts[1:45];
 initial begin
   g=$fopen("gate.txt","r");
   n=$fopen("names.txt","r");
   w=$fopen("word.bin","rb");
   if(!g || !n || !w) $fatal(1,"JOIN_OPEN");
   rc=$fscanf(g,"%d %d %d %d",opn,cls,cutlet,cutday);
   if(rc!=4 || cls-opn!=4244) $fatal(1,"JOIN_GATE");
   pos=-15055671-opn;
   if(pos<1 || pos>4244) $fatal(1,"JOIN_POSITION");
   for(i=1;i<=47;i=i+1) seen[i]=0;
   for(i=1;i<=45;i=i+1) begin
     rc=$fscanf(n,"%d",names[i]);
     if(rc!=1 || names[i]<1 || names[i]>47) $fatal(1,"JOIN_NAME_RANGE");
     if(seen[names[i]]) $fatal(1,"JOIN_NAME_DUPLICATE");
     seen[names[i]]=1; counts[i]=0;
   end
   rc=$fscanf(n,"%d",extra);
   if(rc==1) $fatal(1,"JOIN_EXTRA_NAME");
   for(i=1;i<=4244;i=i+1) begin
     symbol=$fgetc(w);
     if(symbol<1 || symbol>45) $fatal(1,"JOIN_WORD_LENGTH_OR_RANGE");
     counts[symbol]=counts[symbol]+1;
     if(i==pos) begin ordinal=symbol; occurrence=counts[symbol]; end
   end
   if($fgetc(w)!=-1) $fatal(1,"JOIN_EXTRA_WORD");
   $fclose(g); $fclose(n); $fclose(w);
   // Year label is the Foundation normative anchor, not a derived arbitrary year.
   if(opn!=-15057703 || cls!=-15053459 || pos!=2032 ||
      ordinal!=8 || cutlet!=10 || cutday!=503 ||
      names[ordinal]!=20 || occurrence!=56)
     $fatal(1,"JOIN_NORM_MISMATCH");
   $display("FOUNDATION_FIVE_FIELD_TUPLE 5000 %0d %0d %0d %0d",cutlet,cutday,names[ordinal],occurrence);
   $finish;
 end
endmodule
"""

def require(ok, message):
    if not ok:
        raise RuntimeError(message)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def run(label, argv, seconds, failure=None):
    with (OUT / (label + ".log")).open("w") as log:
        p = subprocess.run(argv, cwd=OUT, stdout=log, stderr=subprocess.STDOUT,
                           timeout=seconds, check=False)
    data = (OUT / (label + ".log")).read_text(errors="replace")
    if failure is None:
        require(p.returncode == 0, f"{label} exit={p.returncode}")
    else:
        require(p.returncode != 0 and failure in data, f"{label} mutant not rejected")
    return data

def instrument(path, addition):
    original = (ROOT / path).read_text()
    anchor = "        $finish;"
    require(original.count(anchor) == 1, f"instrumentation anchor drift {path}")
    target = OUT / pathlib.Path(path).name
    target.write_text(original.replace(anchor, addition + "\n" + anchor))
    return target

def main():
    p = argparse.ArgumentParser()
    p.add_argument("archive", type=pathlib.Path)
    args = p.parse_args()
    resource.setrlimit(resource.RLIMIT_AS, (3 * 1024**3, 3 * 1024**3))
    # Compare the entire existing source tree relevant to the accepted witness.
    # New QA runner/workflow/docs may coexist, but old tests/RTL/catalog must match.
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    subprocess.run(["git", "diff", "--exit-code", BASE, "HEAD", "--",
                    "tests", "rtl", "catalog", "scripts/verify_native_H_transfer.sh",
                    "scripts/verify_native_lex_full.sh",
                    "docs/FOUNDATION_WEAVE_FULL_YEAR_TRANSFER.md",
                    "docs/FOUNDATION_MONTH_NAME_45_INDICES.csv"], cwd=ROOT, check=True)
    subprocess.run(["git", "diff", "--exit-code", "HEAD", "--",
                    "tests", "rtl", "catalog", "docs/FOUNDATION_WEAVE_FULL_YEAR_TRANSFER.md",
                    "docs/FOUNDATION_MONTH_NAME_45_INDICES.csv"], cwd=ROOT, check=True)
    OUT.mkdir(parents=True, exist_ok=False)
    require(sha(args.archive.read_bytes()) == ZIP_SHA, "archive SHA")
    with zipfile.ZipFile(args.archive) as z:
        require(len(z.namelist()) == 56 and z.testzip() is None, "archive CRC")
        require(z.read("native_ci_head.txt").decode().strip() == BASE, "source SHA")
        require(z.read("native_ci_runner_sha.txt").decode().strip() == QA, "runner SHA")
        word = z.read("native_lex_full.bin")
    require(len(word) == 4244 and sha(word) == WORD_SHA, "native word SHA")
    (OUT / "word.bin").write_bytes(word)
    (OUT / "provenance.txt").write_text(
        f"head={head}\naccepted_source={BASE}\naccepted_runner={QA}\n"
        f"run=46026008152\nartifact=15212979730\narchive_sha={ZIP_SHA}\nword_sha={WORD_SHA}\n"
        "H_REUSED_NOT_RERUN\nYEAR_LABEL_FOUNDATION_ANCHOR_ONLY\n")
    gate = instrument("tests/tb_gate_gap_oracle.sv",
        '        $display("JOIN_GATE_DATA %0d %0d %0d %0d", cand_open[year_ordinal-1], cand_close[year_ordinal-1], name_values[chosen_cutlet_pos-1], chosen_day);')
    names = instrument("tests/tb_foundation_month_names.sv",
        '        for(i=0;i<45;i=i+1) $display("JOIN_NAME_DATA %0d %0d",i+1,selected_index[i]);')
    pkg = ROOT / "tests"
    run("toolchain", ["iverilog", "-V"], 15)
    run("gate_compile", ["iverilog","-g2012","-s","tb_gate_gap_oracle","-Wall",
        "-o","gate.vvp",str(pkg/"pcal_stage1_oracle_pkg.sv"),
        str(pkg/"pcal_exact_division_pkg.sv"),str(gate)], 120)
    glog = run("gate_native", ["vvp","gate.vvp"], 240)
    require("STAGE1_YEAR5000_REFERENCE_PASS candidates=43 rank=15" in glog, "gate marker")
    require("STAGE1_FOUNDATION_CUTLET_REFERENCE_PASS index=10 day=503" in glog, "cutlet marker")
    gs = re.findall(r"^JOIN_GATE_DATA (-?\d+) (-?\d+) (\d+) (\d+)$",glog,re.M)
    require(len(gs)==1,"gate data cardinality")
    gate_data = tuple(map(int,gs[0]))
    (OUT/"gate.txt").write_text(" ".join(gs[0])+"\n")
    run("names_compile", ["iverilog","-g2012","-s","tb_foundation_month_names","-Wall",
        "-o","names.vvp",str(pkg/"pcal_exact_division_pkg.sv"),str(names)], 120)
    nlog=run("names_native",["vvp","names.vvp"],120)
    require("STAGE1_FOUNDATION_47P45_MONTH_NAME_UNRANK_PASS count=45 unused=21,47" in nlog,"names marker")
    pairs=[tuple(map(int,x)) for x in re.findall(r"^JOIN_NAME_DATA (\d+) (\d+)$",nlog,re.M)]
    with (ROOT/"docs/FOUNDATION_MONTH_NAME_45_INDICES.csv").open() as f:
        reference=[(int(x["month_ordinal"]),int(x["canonical_name_index"])) for x in csv.DictReader(f)]
    require(len(pairs)==45 and pairs==reference and len({v for _,v in pairs})==45,
            "native permutation vs independent reference")
    name_data=[v for _,v in pairs]
    (OUT/"names.txt").write_text("\n".join(map(str,name_data))+"\n")
    # Independent host-side join; never supply expected tuple to the native arithmetic benches.
    opn,cls,cutlet,cutday=gate_data
    pos=-15055671-opn
    require(cls-opn==len(word) and 1<=pos<=len(word),"host gate geometry")
    ordinal=word[pos-1]
    require(1<=ordinal<=45,"host ordinal")
    calculated=(5000,cutlet,cutday,name_data[ordinal-1],word[:pos].count(ordinal))
    require(calculated==NORM,"independent host join")
    (OUT/"join.sv").write_text(JOIN)
    run("join_compile",["iverilog","-g2012","-s","foundation_five_field_join",
        "-Wall","-o","join.vvp","join.sv"],30)
    log=run("join_native",["vvp","join.vvp"],30)
    require(re.findall(r"^FOUNDATION_FIVE_FIELD_TUPLE (.*)$",log,re.M)==
            [" ".join(map(str,NORM))],"native tuple")
    # Mutants are separate from the immutable positive witness.
    positives={n:(OUT/n).read_bytes() for n in ("gate.txt","names.txt","word.bin")}
    cases=[
        ("mutant_cutlet","gate.txt",f"{opn} {cls} {cutlet} {cutday+1}\n".encode(),"JOIN_NORM_MISMATCH"),
        ("mutant_names","names.txt",("\n".join(map(str,name_data[:7]+[name_data[8],name_data[7]]+name_data[9:]))+"\n").encode(),"JOIN_NORM_MISMATCH"),
        ("mutant_word","word.bin",word[:pos-1]+bytes([9])+word[pos:],"JOIN_NORM_MISMATCH"),
        ("mutant_short","word.bin",word[:-1],"JOIN_WORD_LENGTH_OR_RANGE"),
    ]
    for label,name,data,marker in cases:
        try:
            (OUT/name).write_bytes(data)
            run(label,["vvp","join.vvp"],30,marker)
        finally:
            (OUT/name).write_bytes(positives[name])
    run("join_positive_after_mutants",["vvp","join.vvp"],30)
    print("STAGE1_FOUNDATION_FIVE_FIELD_TEST_ONLY_PASS tuple=5000,10,503,20,56 mutants=4 H_REUSED")
    print("STAGE1_OVERALL_NOT_ACCEPTED GENERALIZED_P_NOT_PROVEN ASIC_NOT_TESTED")

if __name__=="__main__":
    main()
