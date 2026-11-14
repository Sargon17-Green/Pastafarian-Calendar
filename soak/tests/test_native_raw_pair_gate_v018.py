from __future__ import annotations
import hashlib
import importlib.util
import json
from pathlib import Path
import unittest

FILE=Path(__file__).resolve().parents[1]/"runner/native_raw_pair_gate_v018.py"
spec=importlib.util.spec_from_file_location("native_raw_pair_gate_v018", FILE)
gate=importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

CUT={"scorpion":10,"C1":1}
MON={"pute":20,"M1":1}
C="-15055671"
T="-15055671"


def encode(x):
    return (json.dumps(x,ensure_ascii=False,sort_keys=True,separators=(",",":"))+"\n").encode("utf-8")


def evidence(engine):
    if engine=="REF-41":
        raw={"calculation_day":C,"target_day":T,"native_date_ids":{
            "year_number":"5000","cutlet_name_index":10,"day_in_cutlet":503,
            "month_name_index":20,"day_in_month":56},
            "native_names":{"cutlet":"scorpion","month":"pute"}}
    else:
        raw={"calculation_day":C,"target_day":T,
             "native_tuple":["5000","scorpion","503","pute","56"]}
    b=encode(raw)
    norm={"calculation_day":C,"target_day":T,"year":"5000",
          "cutlet_index":10,"day_in_cutlet":503,"month_index":20,
          "day_in_month":56,"cutlet_name_raw":"scorpion",
          "month_name_raw":"pute","source_raw_sha256":hashlib.sha256(b).hexdigest()}
    return b, norm


class RawPairGateTests(unittest.TestCase):
    def test_good_mock_python_and_js_native_shapes(self):
        for engine in ("REF-41","REF-24"):
            with self.subTest(engine=engine):
                a,row=evidence(engine)
                result=gate.verify_pair(engine,a,encode(row),CUT,MON,C,T)
                self.assertEqual(result["year"],"5000")
                self.assertEqual(result["month_index"],20)

    def test_digest_mismatch_is_blocking(self):
        a,row=evidence("REF-24")
        row["source_raw_sha256"]="0"*64
        with self.assertRaisesRegex(gate.EvidenceError,"does not bind"):
            gate.verify_pair("REF-24",a,encode(row),CUT,MON,C,T)

    def test_spurious_normalized_field_blocked(self):
        a,row=evidence("REF-41")
        row["cutlet_index"]=11
        with self.assertRaisesRegex(gate.EvidenceError,"native/normalized mismatch"):
            gate.verify_pair("REF-41",a,encode(row),CUT,MON,C,T)

    def test_wrong_native_language_name_blocked(self):
        a,row=evidence("REF-24")
        raw=json.loads(a)
        raw["native_tuple"][1]="unmapped"
        a=encode(raw)
        row["cutlet_name_raw"]="unmapped"
        row["source_raw_sha256"]=hashlib.sha256(a).hexdigest()
        with self.assertRaises(gate.EvidenceError):
            gate.verify_pair("REF-24",a,encode(row),CUT,MON,C,T)

    def test_duplicate_json_key_blocked(self):
        a,row=evidence("REF-41")
        doubled=a[:-2]+b',"target_day":"0"}\n'
        row["source_raw_sha256"]=hashlib.sha256(doubled).hexdigest()
        with self.assertRaisesRegex(gate.EvidenceError,"duplicate"):
            gate.verify_pair("REF-41",doubled,encode(row),CUT,MON,C,T)

    def test_missing_newline_and_day_change_blocked(self):
        a,row=evidence("REF-41")
        with self.assertRaises(gate.EvidenceError):
            gate.verify_pair("REF-41",a.rstrip(b"\n"),encode(row),CUT,MON,C,T)
        with self.assertRaisesRegex(gate.EvidenceError,"input coordinates"):
            gate.verify_pair("REF-41",a,encode(row),CUT,MON,C,str(int(T)+1))

    def test_exact_signed_decimal(self):
        for value in ("-0","+1","000","-01","1.0"," 1","1e4"):
            with self.subTest(value=value),self.assertRaises(gate.EvidenceError):
                gate.canonical_decimal(value)
        self.assertEqual(gate.canonical_decimal("-15055671"),-15055671)


if __name__=="__main__":
    unittest.main()
