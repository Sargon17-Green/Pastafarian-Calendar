#!/usr/bin/env python3
"""Compare the PHP Stage56 month-count choice stream with the pinned canonical source."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def read_events(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    events = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path}:{line_number}: invalid JSONL: {exc}") from exc
    return events


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--canonical-repo", required=True)
    parser.add_argument("--reference", required=True)
    parser.add_argument("--profile-dir", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    canonical = Path(args.canonical_repo).resolve()
    sys.path.insert(0, str(canonical / "implementations" / "python"))
    from pastafari_calendar.core import choose_uniform, response_descriptor, sauce

    reference = json.loads(Path(args.reference).read_text(encoding="utf-8"))
    if reference.get("project_id") != "PC-BRANCH-PHP-MALAY":
        raise ValueError("wrong project id in reference")
    if reference.get("calculation_jdn") != -13334246:
        raise ValueError("unexpected calculation JDN")
    if reference.get("source", {}).get("source_commit") != "cc2cf0b422757a5e7c33218ce30cffa8f99c6786":
        raise ValueError("reference source commit is not pinned")

    profile_dir = Path(args.profile_dir)
    results = []
    mismatch = False
    incomplete = False
    for year in reference["years"]:
        number = int(year["number"])
        profile_path = profile_dir / f"{number}.json.profile.jsonl"
        events = read_events(profile_path)
        month_event = next(
            (event for event in events
             if event.get("type") == "end" and event.get("stage") == "month_count_choice"),
            None,
        )
        pending = []
        started = set()
        completed = set()
        for event in events:
            stage = event.get("stage")
            if event.get("type") == "start":
                started.add(stage)
            elif event.get("type") == "end":
                completed.add(stage)
        pending = sorted(started - completed)
        slowest = sorted(
            (event for event in events
             if event.get("type") == "end" and isinstance(event.get("seconds"), (int, float))),
            key=lambda event: event["seconds"],
            reverse=True,
        )[:6]

        if month_event is None:
            incomplete = True
            results.append({
                "year": number,
                "status": "INCOMPLETE",
                "profile_file": str(profile_path),
                "events": len(events),
                "pending_stages": pending,
                "slowest_completed_stages": [
                    {"stage": event.get("stage"), "seconds": event["seconds"]}
                    for event in slowest
                ],
            })
            continue

        days = int(year["close_gate_day"]) - int(year["open_gate_day"])
        minimum = (days + 122) // 123
        maximum = min(47, days // 4)
        option_count = maximum - minimum + 1
        target_jdn = int(year["open_gate_day"]) + 1
        canonical_sauce = sauce(int(reference["calculation_jdn"]), target_jdn)
        descriptor = response_descriptor(canonical_sauce, 2, 30)
        expected_rank = choose_uniform(canonical_sauce, 2, 30, option_count)

        actual_count = int(month_event["count"])
        actual_rank = int(month_event["rank"])
        actual_first = str(month_event["stream_first"])
        actual_step = int(month_event["stream_step"])
        first_match = actual_first == str(descriptor.first)
        step_match = actual_step == int(descriptor.step)
        rank_match = actual_rank == int(expected_rank)
        count_match = actual_count == option_count
        year_result = {
            "year": number,
            "status": "PASS" if first_match and step_match and rank_match and count_match else "MISMATCH",
            "target_jdn": target_jdn,
            "year_days": days,
            "minimum_months": minimum,
            "maximum_months": maximum,
            "choice_count": option_count,
            "actual_choice_count": actual_count,
            "expected_stream_first": str(descriptor.first),
            "actual_stream_first": actual_first,
            "stream_first_match": first_match,
            "expected_stream_step": int(descriptor.step),
            "actual_stream_step": actual_step,
            "stream_step_match": step_match,
            "expected_choice_rank": int(expected_rank),
            "actual_choice_rank": actual_rank,
            "choice_rank_match": rank_match,
            "expected_month_count": minimum + int(expected_rank) - 1,
            "actual_month_count": minimum + actual_rank - 1,
            "choice_seconds": month_event.get("seconds"),
            "slowest_completed_stages": [
                {"stage": event.get("stage"), "seconds": event["seconds"]}
                for event in slowest
            ],
        }
        results.append(year_result)
        if year_result["status"] != "PASS":
            mismatch = True

    status = "MISMATCH" if mismatch else ("INCOMPLETE" if incomplete else "PASS")
    report = {
        "project_id": "PC-BRANCH-PHP-MALAY",
        "status": status,
        "reference_source_commit": "cc2cf0b422757a5e7c33218ce30cffa8f99c6786",
        "calculation_jdn": -13334246,
        "years": results,
    }
    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for item in results:
        print(json.dumps(item, ensure_ascii=False, sort_keys=True))
    print(f"STAGE56_PHP_MONTH_COUNT_TRACE status={status} years={len(results)}")
    if mismatch:
        return 1
    if incomplete:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
