from __future__ import annotations
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/'control/pilot_two_engine_source_locks_v001.json'


class SourceLockTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest=json.loads(MANIFEST.read_text(encoding='utf8'))

    def test_two_distinct_original_language_sources(self):
        engines=self.manifest['engines']
        self.assertEqual(len(engines),2)
        self.assertEqual({x['language'] for x in engines},{'Python','JavaScript'})
        self.assertEqual(len({x['id'] for x in engines}),2)
        self.assertEqual(len({(x['repository'],x['commit']) for x in engines}),2)
        self.assertFalse(self.manifest['main_changes_permitted'])

    def test_every_source_has_full_commit_and_matching_digest_shapes(self):
        for engine in self.manifest['engines']:
            self.assertEqual(len(engine['commit']),40)
            self.assertTrue(all(c in '0123456789abcdef' for c in engine['commit']))
            for source in engine['sources']:
                self.assertEqual(len(source['git_blob_sha1']),40)
                self.assertEqual(len(source['sha256']),64)
                self.assertTrue(source['syntax_pass'])
                self.assertGreater(source['bytes'],0)
                self.assertNotIn('..',Path(source['path']).parts)

    def test_source_paths_are_unique_and_closure_is_explicit(self):
        sources=[(x['commit'],s['path']) for x in self.manifest['engines'] for s in x['sources']]
        self.assertEqual(len(sources),3)
        self.assertEqual(len(sources),len(set(sources)))
        self.assertIn('src/source-language-catalog.js',{s['path'] for x in self.manifest['engines'] for s in x['sources']})

    def test_no_false_semantic_or_soak_acceptance(self):
        self.assertTrue(self.manifest['syntactic_only'])
        self.assertFalse(self.manifest['semantics_validated'])
        self.assertFalse(self.manifest['full_year_run'])
        self.assertFalse(self.manifest['converter_execution'])
        self.assertTrue(self.manifest['blocked_until'])


if __name__=='__main__':unittest.main()
