#!/usr/bin/env python3
"""Issue #29 isolated original Python single-date observation. No original source edits."""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

DAY = -15055671
SCHEMA = "ISSUE29_ONE_DAY_INTERNAL_V187/1"

def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: python_trace.py ORIGINAL_NORMATIVE_REFERENCE.py OUTPUT.json")
    source, output = Path(sys.argv[1]), Path(sys.argv[2])
    spec = importlib.util.spec_from_file_location("issue29_original_python_v187", source)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    v = module
    state: dict[str, object] = {}
    selected: list[object] = []
    actual_sauce: list[object] = []

    def observed_sauce(c: int, t: int):
        result = v.sauce(c, t)  # exactly one original function call for this invocation
        if selected and c == DAY and t == selected[0].open_gate_day + 1:
            if actual_sauce:
                raise AssertionError("duplicate focus Sauce")
            actual_sauce.append(result)
            counts = v.work_counts(c, t)
            hidden = v.build_hidden_drops(counts)
            visible = v.build_visible_drops(counts, hidden)
            initial = v.initial_bowls(counts)
            after, order = v.apply_visible_drops_to_bowls(initial, visible)
            final = v.post_stir12(after)
            assert tuple(final) == tuple(result.bowls)
            assert tuple(order) == tuple(result.order_at_drop_46)
            state.update({
                "work_action": counts.action, "work_target": counts.target,
                "work_distance": counts.distance, "work_connection": counts.connection,
                "work_direction": counts.direction,
                "hidden_drops": list(hidden[1:]), "visible_drops": list(visible[1:]),
                "initial_bowls": list(initial[1:]),
                "bowls_after_drops": list(after[1:]),
                "order46": list(order), "bowls_after_stir": list(final[1:]),
            })
            for seal, bowl in [(30, 3), (31, 3), (32, 4), (33, 5)]:
                stream = v.ask_bowl(result, bowl, seal)
                state[f"seal{seal}_first"] = stream.first
                state[f"seal{seal}_step"] = stream.direction_step
        return result

    calendar = v.NormativeCalendar(sauce_function=observed_sauce)
    find = calendar.find_target_year
    build = calendar.build_year_structure

    def observed_find(c: int, t: int):
        year = find(c, t)
        if selected:
            raise AssertionError("duplicate original target-year selection")
        selected.append(year)
        state.update({
            "year_number": year.number,
            "open_gate_index": year.open_gate_index,
            "close_gate_index": year.close_gate_index,
            "open_gate_day": year.open_gate_day,
            "close_gate_day": year.close_gate_day,
            "first_day": year.open_gate_day + 1,
            "year_length": year.close_gate_day - year.open_gate_day,
            "offset0": t - (year.open_gate_day + 1),
        })
        return year

    def observed_build(c: int, year):
        structure = build(c, year)
        state.update({
            "cutlet_count": structure.cutlet_count,
            "cutlet_partition": list(structure.cutlet_partition),
            "cutlet_names": list(structure.cutlet_name_indices),
            "month_count": structure.month_count,
            "month_lengths": list(structure.month_lengths),
            "month_weave": list(structure.month_weaving),
            "month_names": list(structure.month_name_indices),
        })
        length = int(state["year_length"])
        lo = (length + 122) // 123
        hi = min(47, length // 4)
        state.update({"month_low":lo,"month_high":hi,"month_choice_count":hi-lo+1})
        assert len(actual_sauce) == 1
        r = actual_sauce[0]
        st = v.ask_bowl(r, 3, v.SEAL_MONTH_COUNT)
        state["month_count_rank"] = v.choose_rank(st, hi-lo+1)
        family = v.BoundedCompositionFamily(length,structure.month_count,4,123)
        state["month_length_family_count"] = family.count()
        state["month_length_rank"] = v.choose_rank(
            v.ask_bowl(r,3,v.SEAL_MONTH_LENGTHS), family.count())
        state["month_name_rank"] = v.choose_rank(
            v.ask_bowl(r,5,v.SEAL_MONTH_NAMES),v.falling_factorial(47,structure.month_count))
        return structure

    calendar.find_target_year = observed_find
    calendar.build_year_structure = observed_build
    ids = calendar.calendar_date_ids(DAY, DAY)
    assert len(selected) == 1 and len(actual_sauce) == 1
    structure = state["month_weave"]
    offset0 = int(state["offset0"])
    month_id = structure[offset0]
    state["month_id"] = month_id
    state["month_name_index"] = state["month_names"][month_id-1]
    state["day_in_month"] = sum(1 for x in structure[:offset0+1] if x == month_id)
    state["day_in_cutlet"] = ids.day_in_cutlet
    matched = [
        i for i, cutlet in enumerate(state["cutlet_partition"], start=1)
        if False
    ]
    del matched  # selected cutlet index is reconstructed without a second date call
    open_gate = int(state["open_gate_index"])
    cutlet_start_gate = open_gate
    for index, span in enumerate(state["cutlet_partition"], start=1):
        cutlet_last_gate = cutlet_start_gate + span
        if calendar.gates.gates[cutlet_start_gate] < DAY <= calendar.gates.gates[cutlet_last_gate]:
            state["cutlet_id"] = index
            break
        cutlet_start_gate = cutlet_last_gate
    assert "cutlet_id" in state
    final = [ids.year_number,ids.cutlet_name_index,ids.day_in_cutlet,
             ids.month_name_index,ids.day_in_month]
    assert final == [5000,10,503,20,56], final
    assert state["month_name_index"] == ids.month_name_index
    assert state["day_in_month"] == ids.day_in_month
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = {"schema":SCHEMA,"engine":"Python_original","input":[DAY,DAY],
               "source_commit":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
               "original_date_invocations":1,"observations":state,"final":final}
    blob = (json.dumps(payload,sort_keys=True,separators=(",",":"),ensure_ascii=False)+"\n").encode()
    assert len(blob) <= 2*1024*1024
    output.write_bytes(blob)
    print("ISSUE29_PYTHON_ORIGINAL_ONE_DAY_FINAL",*final)
    print("ISSUE29_PYTHON_TRACE_BYTES",len(blob))

if __name__ == "__main__":
    main()
