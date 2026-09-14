from __future__ import annotations

import importlib.metadata
import sys

from pastafari_calendar import SOURCE_LANGUAGE_CATALOG, calendar_date_spaghetti


DISTRIBUTION_NAME = "pastafari-calendar-python"
EXPECTED_VERSION = "1.0.0"


def _as_tuple(result) -> tuple[int, str, int, str, int]:
    return (
        result.year_number,
        result.cutlet_name,
        result.day_in_cutlet,
        result.month_name,
        result.day_in_month,
    )


def main() -> None:
    install_kind = sys.argv[1] if len(sys.argv) > 1 else "unknown"

    installed_version = importlib.metadata.version(DISTRIBUTION_NAME)
    if installed_version != EXPECTED_VERSION:
        raise AssertionError(
            f"Paket sürümü {installed_version!r}; beklenen {EXPECTED_VERSION!r}"
        )

    if SOURCE_LANGUAGE_CATALOG.version != "1.3.2":
        raise AssertionError(
            "Kurulu paketin kaynak dili kataloğu 1.3.2 değil"
        )

    foundation = _as_tuple(
        calendar_date_spaghetti(-15_055_671, -15_055_671)
    )
    if foundation != (5000, "Akrep", 503, "Kuyu", 56):
        raise AssertionError(f"Foundation smoke sonucu beklenmedik: {foundation!r}")

    modern = _as_tuple(
        calendar_date_spaghetti(739_834, 739_834)
    )
    if modern != (5000, "Böbrek", 306, "Dil", 23):
        raise AssertionError(f"Modern smoke sonucu beklenmedik: {modern!r}")

    print(
        "CLEAN_PACKAGE_SMOKE="
        f"PASS kind={install_kind} version={installed_version} "
        "foundation=5000/Akrep/503/Kuyu/56 "
        "modern=5000/Böbrek/306/Dil/23"
    )


if __name__ == "__main__":
    main()
