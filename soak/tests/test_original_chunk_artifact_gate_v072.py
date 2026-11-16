"""v072 pure tests: generalized original source archive gate, no native calls."""
from __future__ import annotations
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import original_chunk_artifact_gate_v072 as g


class OriginalGeneralizedChunkGateTests(unittest.TestCase):
    def setUp(self):
        self.pin=g.pinned_manifest()

    def test_locked_1017_ordinal_coordinates(self):
        self.assertEqual(g.validate_coordinates(self.pin),
                         ("-15055671","5000","-15055668","-15055667",1017))

    def test_next_1018_coordinates_without_hardcoded_parser(self):
        pin=copy.deepcopy(self.pin)
        year=pin["original_source_year"]
        year["ordinal"]=1018
        year["first_chunk_target_day"]="-15055666"
        year["last_chunk_target_day"]="-15055665"
        self.assertEqual(g.validate_coordinates(pin)[-3:],
                         ("-15055666","-15055665",1018))

    def test_end_of_original_year_2121_allowed(self):
        pin=copy.deepcopy(self.pin)
        year=pin["original_source_year"]
        year["ordinal"]=2121
        year["first_chunk_target_day"]="-15053460"
        year["last_chunk_target_day"]="-15053459"
        self.assertEqual(g.validate_coordinates(pin)[-3:],
                         ("-15053460","-15053459",2121))

    def test_preexisting_1016_cannot_be_mislabeled_new(self):
        pin=copy.deepcopy(self.pin)
        pin["original_source_year"]["ordinal"]=1016
        with self.assertRaises(ValueError):
            g.validate_coordinates(pin)

    def test_out_of_year_last_ordinal_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["original_source_year"]["ordinal"]=2122
        with self.assertRaises(ValueError):
            g.validate_coordinates(pin)

    def test_wrong_target_offset_from_ordinal_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["original_source_year"]["first_chunk_target_day"]="-15055667"
        with self.assertRaisesRegex(ValueError,"not aligned"):
            g.validate_coordinates(pin)

    def test_noninteger_ordinal_rejected(self):
        for x in ("1017",1017.0,True,None):
            with self.subTest(x=x):
                pin=copy.deepcopy(self.pin)
                pin["original_source_year"]["ordinal"]=x
                with self.assertRaises(ValueError):
                    g.validate_coordinates(pin)

    def test_changed_year_gate_provenance_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["original_source_year"]["boundary_evidence_sha256"]="0"*64
        with self.assertRaisesRegex(ValueError,"locked native year"):
            g.validate_coordinates(pin)


if __name__=="__main__":
    unittest.main()
