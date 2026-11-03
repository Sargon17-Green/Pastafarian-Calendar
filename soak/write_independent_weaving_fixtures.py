#!/usr/bin/env python3
"""Write deterministic independent weaving witnesses for Kotlin native comparison."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from independent_month_weaving_oracle import IndependentMonthWeavingOracle

def main(output: Path) -> None:
    cases = ((1,), (1,2), (2,1), (2,2), (2,2,2),
             (3,1,2), (4,5,6), (7,5,4,4), (4,)*47)
    rows = []
    for lengths in cases:
        oracle = IndependentMonthWeavingOracle(lengths)
        count = oracle.count_all()
        offsets = (0, sum(lengths)//2, sum(lengths)-1)
        ranks = (1, (count+1)//2, count)
        if len(lengths) == 47:  # Bound native CI work, retain a large rank.
            offsets = (0,1)
        for rank in sorted(set(ranks)):
            for offset in sorted(set(offsets)):
                day = oracle.day_at(rank, offset)
                rows.append("|".join((
                    ",".join(map(str,lengths)), str(rank), str(offset),
                    str(count), str(day.ordinal), str(day.day_in_month)
                )))
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text("\n".join(rows)+"\n",encoding="ascii")
    print("INDEPENDENT_WEAVING_WITNESSES",len(rows))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: write_independent_weaving_fixtures.py OUTPUT")
    main(Path(sys.argv[1]))
