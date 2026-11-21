#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31L: only one new original-Native input b'0'; all old observations are reused."""
from __future__ import print_function
import json
import os
import sys
import stage1_qa31g_native_eof_probe as observer

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
LABEL = "single_zero"

def need(ok, message):
    if not ok:
        raise AssertionError(message)

def main(folder):
    need(os.path.isdir(folder), "output directory missing")
    source = open(observer.qa20.SOURCE, "rb").read()
    need(observer.qa20.pin(source) == PIN == observer.PIN,
         "immutable original-source Git blob mismatch")
    need(observer.CAP == 7000, "observer physical STEP cap changed")
    case = observer.run(source, folder, LABEL, "0")
    need(case["label"] == LABEL and case["raw_hex"] == "30",
         "original single-byte input not preserved")
    need(case["status"] in ("HALT", "STEP_LIMIT", "RUNTIME_ERROR"),
         "native status outside contract")
    receipt = {
        "schema": "qa31l-single-zero-original-native-v1",
        "source_blob": PIN,
        "source_modified": False,
        "ip_relocated": False,
        "input_case_count": 1,
        "old_cases_rerun": 0,
        "native_model_proven": False,
        "global_owner_proven": False,
        "stage1_pass": False,
        "cases": [case]
    }
    with open(os.path.join(folder, "qa31l_receipt.json"), "wb") as output:
        output.write(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print("QA31L_NATIVE_NEW_INPUT", LABEL, case["status"],
          "STEPS", case["steps"], "READS", case["reads"])
    print("QA31L_SINGLE_BYTE_ZERO_ONLY")
    print("QA31L_NO_STAGE1_PASS")

if __name__ == "__main__":
    need(len(sys.argv) == 2, "usage: script.py OUTPUT_DIR")
    main(sys.argv[1])
