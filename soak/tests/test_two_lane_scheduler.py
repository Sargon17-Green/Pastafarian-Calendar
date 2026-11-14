import pathlib
import sys
import unittest
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "runner"))
from two_lane_scheduler import TwoLaneCoordinator, Job


class TwoLaneSchedulerTests(unittest.TestCase):
    def test_full_year_engines_are_strictly_sequential(self):
        s = TwoLaneCoordinator([5000], ["a", "b", "c"], {5000: 3})
        a = s.dispatch(0)
        self.assertEqual(len(a),1)
        self.assertEqual((a[0].job.year,a[0].job.engine),(5000,"a"))
        self.assertEqual(s.verified_comparisons_completed,0)
        s.finish("normal",1,verified=True)
        b = s.dispatch(1)
        self.assertEqual([(x.job.year,x.job.engine) for x in b],[(5000,"b")])
        s.finish("normal",2,verified=True)
        self.assertEqual(s.verified_comparisons_completed,1)
        s.dispatch(2);s.finish("normal",3,verified=True)
        self.assertEqual(s.verified_comparisons_completed,2)
        self.assertEqual(s.verified_day_pair_comparisons,6)
        self.assertEqual(s.contiguous_verified_years,1)
        self.assertTrue(s.all_verified)

    def test_single_mismatch_stops_new_scheduling_without_killing_inflight(self):
        s = TwoLaneCoordinator([1,2,3],["a","b"],{1:2,2:2,3:2})
        self.assertEqual(s.count_active(),0)
        jobs = s.dispatch(0)
        self.assertEqual(s.count_active(),1)
        s.finish("normal",1,verified=True)
        # A second year could already be queued. A new engine b on year 1
        # has no privilege to bypass the queue, but both must be sequential.
        jobs = s.dispatch(1)
        self.assertEqual(s.count_active(),1)
        s.finish("normal",2,verified=False,incident={"type":"MISMATCH","day":12})
        self.assertTrue(s.halt_new_work)
        self.assertEqual(s.dispatch(3),[])
        self.assertEqual(s.incident["day"],12)

    def test_slow_classification_transfers_inflight_without_restarting(self):
        s=TwoLaneCoordinator([1,2],["a","b"],{1:1,2:1})
        first=s.dispatch(0)[0]
        self.assertEqual(first.lane,"normal")
        s.inspect_overdue(301)
        self.assertEqual(s.active["slow"],first)
        self.assertIsNone(s.active["normal"])
        self.assertEqual(s.count_active(),1)
        self.assertTrue(first.overdue)
        self.assertEqual(len([v for v in s.events if v["type"]=="STARTED"]),1)
        s.dispatch(301)
        self.assertEqual(s.count_active(),2)
        self.assertIsNotNone(s.active["normal"])
        self.assertNotEqual(s.active["slow"].job.year,s.active["normal"].job.year)

    def test_when_slow_worker_busy_do_not_start_third_process(self):
        s = TwoLaneCoordinator([1, 2, 3], ["a", "b"], {1: 1, 2: 1, 3: 1})
        # Test the cap with a known slow job on another year, before processing.
        from collections import deque
        s.queues["normal"] = deque([Job(1,"a",1), Job(2,"a",1)])
        s.queues["slow"] = deque([Job(3,"a",1)])
        jobs = s.dispatch(0)
        self.assertEqual(s.count_active(), 2)
        self.assertEqual(len(jobs), 2)
        s.inspect_overdue(301)
        self.assertTrue(s.active["normal"].overdue)
        self.assertIsNotNone(s.active["slow"])
        self.assertEqual(s.dispatch(302), [])
        self.assertEqual(s.count_active(), 2)

    def test_verified_prefix_not_overstated_for_out_of_order_years(self):
        s=TwoLaneCoordinator([1,2,3],["a","b"],{1:1,2:1,3:1})
        s.completed_years.update([2,3])
        self.assertEqual(s.contiguous_verified_years,0)
        s.completed_years.add(1)
        self.assertEqual(s.contiguous_verified_years,3)

    def test_invalid_configuration_rejected(self):
        with self.assertRaises(ValueError):
            TwoLaneCoordinator([1,1],["a","b"],{1:3})
        with self.assertRaises(ValueError):
            TwoLaneCoordinator([1],["a","a"],{1:3})

if __name__=="__main__":unittest.main()
