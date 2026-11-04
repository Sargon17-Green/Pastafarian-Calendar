#!/usr/bin/env python3
"""Synthetic tests for strict 3x5 matching; real reference remains CI-only."""
from __future__ import annotations
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parent))
from tablets_pinned_five_field_differential import (
    TARGETS, PASS, DifferentialError, compare_rows, strict_rows,
    verify_candidate_document, SOURCE_SHA, PINNED_SHA,
    PINNED_MODULE_SHA256, EXPECTED_TRACE_SHA256)


def rows():
    return [{'day':d,'five_fields':[8453,7,934+i,12,100]}
            for i,d in enumerate(TARGETS)]


def evidence():
    return {'rows':rows(),'status':'PASS_REAL_UNSEEDED_FIVE_FIELDS_PINNED_DATE_NOT_COMPARED_NOT_CERTIFIED',
            'independent_commit':SOURCE_SHA,'pinned_commit':PINNED_SHA,
            'pinned_module_sha256':PINNED_MODULE_SHA256,
            'signed_transcript_sha256':EXPECTED_TRACE_SHA256,
            'cases':3,'fields_per_case':5,'total_unique_gap_questions':29523,
            'production_gate_limit_unchanged':8192,'segment_limit':4096,
            'checkpoint_seed_used':False,'pinned_date_comparison_performed':False,
            'full_date_certified':False,'certifiable':False,'targets':TARGETS}

class PinnedDifferentialTests(unittest.TestCase):
    def test_matching_fifteen_fields(self):
        comparison=compare_rows(rows(),rows())
        self.assertEqual(len(comparison),3)
        self.assertTrue(all(x['matched'] for x in comparison))
    def test_mismatch_is_detected_without_normalization(self):
        ref=rows()
        ref[1]['five_fields'][3]+=1
        mismatch=compare_rows(rows(),ref)
        self.assertEqual([x['matched'] for x in mismatch],[True,False,True])
    def test_wrong_order_rejected(self):
        with self.assertRaisesRegex(DifferentialError,'E_PINNED_FIELD_SHAPE'):
            strict_rows(list(reversed(rows())),label='PINNED')
    def test_missing_boolean_or_invalid_number_rejected(self):
        bad=rows()
        bad[0]['five_fields'][2]=True
        with self.assertRaisesRegex(DifferentialError,'E_INDEPENDENT_FIELD_SHAPE'):
            strict_rows(bad,label='INDEPENDENT')
    def test_valid_source_contract(self):
        self.assertEqual(len(verify_candidate_document(evidence())),3)
    def test_fail_closed_on_certified_claim(self):
        doc=evidence();doc['certifiable']=True
        with self.assertRaisesRegex(DifferentialError,'E_EVIDENCE_DRIFT_CERTIFIABLE'):
            verify_candidate_document(doc)
    def test_fail_closed_on_source_drift(self):
        doc=evidence();doc['independent_commit']='0'*40
        with self.assertRaisesRegex(DifferentialError,'E_EVIDENCE_DRIFT_INDEPENDENT_COMMIT'):
            verify_candidate_document(doc)
    def test_fail_closed_on_false_replay(self):
        doc=evidence();doc['checkpoint_seed_used']=True
        with self.assertRaisesRegex(DifferentialError,'E_EVIDENCE_DRIFT_CHECKPOINT_SEED_USED'):
            verify_candidate_document(doc)

if __name__=='__main__':unittest.main()
