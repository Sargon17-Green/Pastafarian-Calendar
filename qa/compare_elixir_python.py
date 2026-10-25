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
    group_requested = os.environ.get("DIFF_GROUP", "all")
    allowed = {"all", "foundation", "modern_base", "modern_moves", "year_max"}
    if group_requested not in allowed:
        raise ValueError(f"Unrecognized differential group: {group_requested!r}")
    seen = set()
    pairs = []
    for raw in CASE_FILE.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        parts = raw.split("\t")
        if len(parts) != 4:
            raise ValueError(f"Malformed differential case: {raw!r}")
        label, c, t, group = parts
        if group not in allowed - {"all"}:
            raise ValueError(f"Unrecognized case group: {group!r}")
        if label in seen:
            raise ValueError(f"Duplicate case identifier: {label!r}")
        seen.add(label)
        if group_requested == "all" or group == group_requested:
            pairs.append((label, int(c), int(t)))
    if not pairs:
        raise ValueError(f"No differential cases for {group_requested}")
    print("DIFF_GROUP_SELECTED", group_requested, len(pairs), flush=True)
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
    observed = {}
    # Phát log theo từng dòng; không giữ im lặng hàng phút khi Elixir chạy.
    with (OUT / "elixir-raw.log").open("w", encoding="utf-8", buffering=1) as log:
        run = subprocess.Popen(
            ["mix", "run", "qa/elixir_vietnamese_differential.exs"],
            cwd=ROOT, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, bufsize=1,
            env={**os.environ, "MIX_ENV": "dev"},
        )
        try:
            for line in run.stdout:
                print("ELIXIR_OUTPUT", line.rstrip("\n"), flush=True)
                log.write(line)
                log.flush()
                if not line.startswith("DIFF\t"):
                    continue
                cells = line.strip().split("\t")[1:]
                if len(cells) != 8:
                    raise AssertionError(f"Invalid Elixir row: {line!r}")
                label = cells[0]
                if label in observed:
                    raise AssertionError(f"Duplicate record: {label}")
                observed[label] = (label, *(int(v) for v in cells[1:]))
                (OUT / "elixir.tsv").write_text(
                    "\n".join(row_line(row) for row in observed.values()) + "\n",
                    encoding="utf-8",
                )
            exit_code = run.wait(timeout=45)
        finally:
            if run.poll() is None:
                run.kill()
                run.wait(timeout=10)
    print("ELIXIR_SECONDS", round(time.monotonic() - start, 3),
          "returncode", exit_code, flush=True)
    if exit_code:
        raise RuntimeError(f"Elixir execution failed with status {exit_code}")
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
