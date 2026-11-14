#!/usr/bin/env python3
"""Deterministic state-machine prototype for a no-kill two-lane soak scheduler.

This module intentionally does not launch or terminate operating-system
processes. Production Popen/Windows Job Object supervision is a later gate.
"""
from __future__ import annotations
from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Optional
from year_validator import robust_slow_threshold


@dataclass(frozen=True)
class Job:
    year: int
    engine: str
    expected_days: int


@dataclass
class Active:
    job: Job
    started: float
    lane: str
    overdue: bool = False


class TwoLaneCoordinator:
    """At most one job per lane, at most two jobs across both lanes.

    Every year advances through exactly one engine at a time. The *caller*
    must verify full-year output before invoking finish(..., verified=True).
    Each engine beyond the baseline increments successful comparisons once
    per completely matched year. No internal operation kills a process.
    """
    def __init__(self, years: list[int], engines: list[str], year_lengths: dict[int, int]):
        if not years or len(years) != len(set(years)):
            raise ValueError("years must be nonempty and unique")
        if len(engines) < 2 or len(set(engines)) != len(engines):
            raise ValueError("two or more distinct engines are required")
        if any(y not in year_lengths or year_lengths[y] <= 0 for y in years):
            raise ValueError("each year needs independently verified positive length")
        self.years = list(years)
        self.engines = list(engines)
        self.year_lengths = dict(year_lengths)
        self.queues = {"normal": deque(), "slow": deque()}
        self.active: dict[str, Optional[Active]] = {"normal": None, "slow": None}
        self.history: dict[tuple[str,int], list[float]] = defaultdict(list)
        self.slow_engines: set[str] = set()
        self.year_next_index = {year: 0 for year in years}
        self.completed_years: set[int] = set()
        self.verified_comparisons_completed = 0
        self.verified_day_pair_comparisons = 0
        self.halt_new_work = False
        self.incident: Optional[dict] = None
        self.events = []
        for year in years:
            self._enqueue(Job(year, engines[0], year_lengths[year]))

    def _enqueue(self, job: Job) -> None:
        lane = "slow" if job.engine in self.slow_engines else "normal"
        self.queues[lane].append(job)
        self.events.append({"type": "ENQUEUED", "lane": lane, "year": job.year, "engine": job.engine})

    def count_active(self) -> int:
        return sum(x is not None for x in self.active.values())

    def _eligible(self, lane: str) -> Optional[Job]:
        q = self.queues[lane]
        years_in_flight = {x.job.year for x in self.active.values() if x is not None}
        for _ in range(len(q)):
            job = q.popleft()
            if job.year not in years_in_flight:
                return job
            q.append(job)
        return None

    def dispatch(self, now: float) -> list[Active]:
        if self.halt_new_work:
            return []
        started = []
        # Reserve the slow lane for known long-running jobs. Never create a
        # third process, even if an overdue normal process cannot be promoted.
        for lane in ("slow", "normal"):
            if self.active[lane] is not None or self.count_active() >= 2:
                continue
            job = self._eligible(lane)
            if job is None:
                continue
            item = Active(job=job, started=now, lane=lane)
            self.active[lane] = item
            started.append(item)
            self.events.append({"type": "STARTED", "lane": lane, "year": job.year, "engine": job.engine})
        assert self.count_active() <= 2
        return started

    def inspect_overdue(self, now: float) -> None:
        item = self.active["normal"]
        if item is None:
            return
        bucket = (item.job.engine, item.job.expected_days)
        threshold = robust_slow_threshold(self.history[bucket])
        if item.overdue or now - item.started < threshold:
            return
        item.overdue = True
        self.slow_engines.add(item.job.engine)
        self.events.append({"type": "CLASSIFIED_SLOW_IN_FLIGHT", "year": item.job.year,
                            "engine": item.job.engine, "threshold_seconds": threshold})
        # Logical transfer only. The actual process continues with the same
        # PID and handles; this method does NOT cancel/relaunch it.
        if self.active["slow"] is None:
            self.active["normal"] = None
            self.active["slow"] = item
            item.lane = "slow"
            self.events.append({"type": "LOGICAL_LANE_TRANSFER_NO_RESTART",
                                "year": item.job.year, "engine": item.job.engine})
        assert self.count_active() <= 2

    def finish(self, lane: str, now: float, *, verified: bool, incident: Optional[dict] = None) -> None:
        if lane not in self.active or self.active[lane] is None:
            raise ValueError("finish called for non-running lane")
        item = self.active[lane]
        self.active[lane] = None
        job = item.job
        if now < item.started:
            raise ValueError("time moved backward")
        if not verified or incident is not None:
            self.halt_new_work = True
            self.incident = incident or {"type": "INVALID_EVIDENCE", "year": job.year,
                                        "engine": job.engine}
            self.events.append({"type": "HALTED_ON_FIRST_MISMATCH_OR_INVALID_EVIDENCE",
                                "year": job.year, "engine": job.engine})
            return
        duration = now - item.started
        self.history[(job.engine, job.expected_days)].append(duration)
        index = self.year_next_index[job.year]
        if self.engines[index] != job.engine:
            raise AssertionError("unexpected engine order")
        self.year_next_index[job.year] = index + 1
        # Baseline output is not counted as a *comparison*.
        if index > 0:
            self.verified_comparisons_completed += 1
            self.verified_day_pair_comparisons += job.expected_days
        if index + 1 == len(self.engines):
            self.completed_years.add(job.year)
        else:
            following = Job(job.year, self.engines[index + 1], job.expected_days)
            self._enqueue(following)
        self.events.append({"type": "COMPLETE_VALIDATED", "year": job.year,
                            "engine": job.engine, "seconds": duration})

    @property
    def contiguous_verified_years(self) -> int:
        complete = 0
        for year in self.years:
            if year not in self.completed_years:
                break
            complete += 1
        return complete

    @property
    def all_verified(self) -> bool:
        return (not self.halt_new_work and len(self.completed_years) == len(self.years)
                and self.count_active() == 0 and not any(self.queues.values()))
