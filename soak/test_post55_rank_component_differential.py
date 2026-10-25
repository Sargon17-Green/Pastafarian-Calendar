"""Deterministic differential infrastructure tests; not a full-date certificate."""
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
import post55_rank_component_differential as component


class ComponentDifferentialTests(unittest.TestCase):
    def test_deterministic_cases_cover_every_direction_and_boundary(self):
        a = component.build_cases(55)
        self.assertEqual(a, component.build_cases(55))
        self.assertGreater(len(a), 2500)
        self.assertEqual(len(a), len(set(a)))
        self.assertTrue(any(x[0] == "G" and x[1] < 0 for x in a))
        self.assertTrue(any(x[0] == "G" and x[1] > 0 for x in a))
        self.assertTrue(any(x[0] == "Y" and x[1] == 1128 for x in a))
        self.assertTrue(any(x[2] == component.M for x in a))
        self.assertTrue(any(x[3] == -1 for x in a))
        self.assertTrue(any(x[3] == 1 for x in a))

    def test_result_protocol_validation(self):
        case = [("G", -3, 5, 1)]
        correct = "G\t-3\t5\t1\t5\t46\t0"
        self.assertEqual(component.parse_output(correct, case, "MOCK"), [(5, 46, 0)])
        with self.assertRaisesRegex(ValueError, "LINE_COUNT"):
            component.parse_output("", case, "MOCK")
        with self.assertRaisesRegex(ValueError, "FORMAT"):
            component.parse_output("G\t-3\t5\t1\t5\t46\t00", case, "MOCK")
        with self.assertRaisesRegex(ValueError, "INPUT_ECHO"):
            component.parse_output("G\t3\t5\t1\t5\t46\t0", case, "MOCK")
        with self.assertRaisesRegex(ValueError, "RANGE"):
            component.parse_output("G\t-3\t5\t1\t5\t47\t0", case, "MOCK")

    def test_only_one_based_ranges_accepted(self):
        case = [("Y", 3, 5, -1)]
        self.assertEqual(component.parse_output(
            "Y\t3\t5\t-1\t3\t0\t0", case, "MOCK"
        ), [(3, 0, 0)])
        with self.assertRaisesRegex(ValueError, "RANGE"):
            component.parse_output("Y\t3\t5\t-1\t0\t0\t0", case, "MOCK")


if __name__ == "__main__":
    unittest.main()
