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

PEER_SHA = "b3501b4296403bc33cb36f81a763269e5af97523"
CASE_FILE = ROOT / "qa" / "differential_cases.tsv"

def load_cases():
    seen = set()
    pairs = []
    for raw in CASE_FILE.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        parts = raw.split("\t")
        if len(parts) != 3:
            raise ValueError(f"Malformed differential case: {raw!r}")
        label, c, t = parts
        if label in seen:
            raise ValueError(f"Duplicate case identifier: {label!r}")
        seen.add(label)
        pairs.append((label, int(c), int(t)))
    if not pairs:
        raise ValueError("No differential cases")
    return tuple(pairs)

def verify_peer_revision():
    actual = subprocess.check_output(
        ["git", "-C", str(ROOT / "python-peer"), "rev-parse", "HEAD"],
        text=True, timeout=30,
    ).strip()
    if actual != PEER_SHA:
        raise AssertionError(f"Python peer moved: {actual} != {PEER_SHA}")
    print(f"PEER_REVISION_LOCKED {actual}", flush=True)

CASES = load_cases()

def expected_rows():
    cutlet_ids = {item.text: item.canonical_index for item in SOURCE_LANGUAGE_CATALOG.cutlets}
    month_ids = {item.text: item.canonical_index for item in SOURCE_LANGUAGE_CATALOG.months}
    rows = {}
    for label, c, t in CASES:
        print("PYTHON_PEER_BEGIN", label, c, t, flush=True)
        start = time.monotonic()
        output = calendar_date_spaghetti(c, t)
        row = (label, c, t, output.year_number,
               cutlet_ids[output.cutlet_name], output.day_in_cutlet,
               month_ids[output.month_name], output.day_in_month)
        print("PYTHON_PEER", label, "seconds", round(time.monotonic() - start, 3), flush=True)
        rows[label] = row
        (OUT / "python.tsv").write_text(
            "\n".join(row_line(item) for item in rows.values()) + "\n", encoding="utf-8"
        )
    return rows

def row_line(row):
    return "\t".join(str(v) for v in row)

def main():
    verify_peer_revision()
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
