"""So sánh hai trình thực thi độc lập; không dùng dữ liệu peer cho production."""
import os
import pathlib
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]
PEER = ROOT / "python-peer" / "src"
OUT = ROOT / "differential-evidence"
OUT.mkdir(exist_ok=True)
sys.path.insert(0, str(PEER))

from pastafari_calendar import calendar_date_spaghetti, SOURCE_LANGUAGE_CATALOG  # noqa: E402

CASES = (
    ("foundation_same", -15_055_671, -15_055_671),
    ("foundation_next", -15_055_671, -15_055_670),
    ("foundation_previous", -15_055_671, -15_055_672),
    ("foundation_plus_seven", -15_055_664, -15_055_664),
    ("foundation_mixed", -15_055_669, -15_055_668),
)

def expected_rows():
    cutlet_ids = {item.text: item.canonical_index for item in SOURCE_LANGUAGE_CATALOG.cutlets}
    month_ids = {item.text: item.canonical_index for item in SOURCE_LANGUAGE_CATALOG.months}
    rows = {}
    for label, c, t in CASES:
        start = time.monotonic()
        output = calendar_date_spaghetti(c, t)
        row = (label, c, t, output.year_number,
               cutlet_ids[output.cutlet_name], output.day_in_cutlet,
               month_ids[output.month_name], output.day_in_month)
        print("PYTHON_PEER", label, "seconds", round(time.monotonic() - start, 3), flush=True)
        rows[label] = row
    return rows

def row_line(row):
    return "\t".join(str(v) for v in row)

def main():
    print("Python peer pinned to b3501b4296403bc33cb36f81a763269e5af97523", flush=True)
    python_rows = expected_rows()
    (OUT / "python.tsv").write_text(
        "\n".join(row_line(row) for row in python_rows.values()) + "\n", encoding="utf-8"
    )
    start = time.monotonic()
    run = subprocess.run(
        ["mix", "run", "qa/elixir_vietnamese_differential.exs"],
        cwd=ROOT, text=True, capture_output=True, timeout=1500,
        check=False, env={**os.environ, "MIX_ENV": "dev"},
    )
    (OUT / "elixir-raw.log").write_text(run.stdout + "\nSTDERR:\n" + run.stderr, encoding="utf-8")
    print("ELIXIR_SECONDS", round(time.monotonic() - start, 3), "returncode", run.returncode, flush=True)
    if run.returncode:
        print(run.stderr[-4000:], file=sys.stderr)
        raise RuntimeError("Elixir execution failed")
    observed = {}
    for line in run.stdout.splitlines():
        if not line.startswith("DIFF\t"):
            continue
        cells = line.split("\t")[1:]
        if len(cells) != 8:
            raise AssertionError(f"Invalid Elixir row: {line!r}")
        label = cells[0]
        if label in observed:
            raise AssertionError(f"Duplicate record: {label}")
        observed[label] = (label, *(int(v) for v in cells[1:]))
    (OUT / "elixir.tsv").write_text(
        "\n".join(row_line(row) for row in observed.values()) + "\n", encoding="utf-8"
    )
    if set(observed) != set(python_rows):
        raise AssertionError(f"Case sets differ: {sorted(observed)}, {sorted(python_rows)}")
    mistakes = []
    for label in python_rows:
        if python_rows[label] != observed[label]:
            mistakes.append(f"{label}: Python={python_rows[label]}, Elixir={observed[label]}")
        else:
            print("DIFF_PASS", label, row_line(observed[label]), flush=True)
    (OUT / "comparison.txt").write_text(
        "PASS\n" if not mistakes else "FAIL\n" + "\n".join(mistakes) + "\n", encoding="utf-8"
    )
    if mistakes:
        raise AssertionError("\n".join(mistakes))
    print(f"DIFFERENTIAL_PASS {len(python_rows)}/{len(python_rows)}", flush=True)

if __name__ == "__main__":
    main()
