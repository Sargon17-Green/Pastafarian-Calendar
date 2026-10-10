#!/usr/bin/env python3
"""Fail-closed BF98 source-space proof for test-only LF+EOF splice.

The immutable Native-qualified 24-token grammar body must be byte-identical.
Only its terminal success instruction is redirected into the LF-only EOF
reflector, which is positioned in a separate spatial row. No calendar logic.
"""
from pathlib import Path

ORIGINAL=Path("qa/year5000_exact_line_grammar.b98").read_bytes()
INTEGRATED=Path("qa/year5000_integrated_lf_eof_grammar.b98").read_bytes()
ORIGINAL_SHA="0c7d996a3969adb47e8d58cff27c315a3af8145d"

def need(pred,reason):
    if not pred:
        raise AssertionError(reason)

def git_blob(payload):
    import hashlib
    return hashlib.sha1(b"blob "+str(len(payload)).encode("ascii")+b"\0"+payload).hexdigest()

def verify(original,modified):
    need(git_blob(original)==ORIGINAL_SHA,"immutable LF grammar source changed")
    need(original.endswith(b"\n") and original.count(b"\n")==1,
         "original BF98 grammar source is not a single row")
    baseline=original[:-1]
    need(len(baseline)==943 and baseline.endswith(b"01-.@1.@"),
         "original success/reject coordinates drifted")
    caret=len(baseline)-3+5
    expected_row0=baseline[:-3]+b"   1j^~$01-.@"
    expected_row1=b" "*caret+b">1.@"
    expected=expected_row0+b"\n"+expected_row1+b"\n"
    need(modified==expected,
         "integrated BF98 differs outside its exact EOF success splice")
    need(modified[:len(baseline)-3]==original[:len(baseline)-3],
         "original parser path or reject route mutated")
    return caret,len(expected_row0),len(expected_row1)

def main():
    caret,upper,lower=verify(ORIGINAL,INTEGRATED)
    # Fail closed on mutations of live BF98 instructions and spacing.
    mutations=[
      ("bootstrap",0,b"1"),
      ("scratch",10,b"9"),
      ("earlier_parser",128,b"z"),
      ("existing_reject",ORIGINAL[:-1].rfind(b"01-.@")+4,b"x"),
      ("success_bridge",940,b"1"),
      ("skip_caret",944,b"0"),
      ("eof_caret",945,b"v"),
      ("read_raw_eof",946,b"&"),
      ("drop_after_lf",947,b":"),
      ("trailer_reject",948,b"1"),
      ("row_two_redirect",len(INTEGRATED)-5,b"<"),
      ("row_two_accept",len(INTEGRATED)-4,b"0"),
      ("row_two_output",len(INTEGRATED)-3,b","),
    ]
    denied=[]
    for name,pos,replacement in mutations:
        trial=bytearray(INTEGRATED)
        if trial[pos:pos+1]==replacement:
            raise AssertionError("adversarial mutation is inert "+name)
        trial[pos:pos+1]=replacement
        try:verify(ORIGINAL,bytes(trial))
        except AssertionError:denied.append(name)
        else:raise AssertionError("altered executable cell was accepted "+name)
    try:verify(ORIGINAL,INTEGRATED+b"@")
    except AssertionError:denied.append("appended_instruction")
    else:raise AssertionError("unapproved appended instruction was accepted")
    need(len(denied)==14,"some executable-cell mutants were not tested")
    print("NATIVE_YEAR5000_INTEGRATED_LF_EOF_STATIC_SOURCE_MAP_PASS",
          "original_parser_prefix_byte_equal=YES",
          "eof_caret_x="+str(caret),
          "row_lengths="+str((upper,lower)),
          "source_mutants_rejected="+str(len(denied)),
          "stage1_final_acceptance=NO")
if __name__=="__main__":
    main()
