import unittest

from pastafari_calendar.acceleration_scars import reset_acceleration_scars_for_tests
from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.source_language_catalog import SOURCE_LANGUAGE_CATALOG


# Eski Python uygulamasının JDN ekseni ile bu dalın dayIndex ekseni arasındaki
# sabit fark.  Örneğin eski Foundation JDN -13_334_246, burada -15_055_671'dir.
LEGACY_JDN_TO_DAY_INDEX_OFFSET = 1_721_425

# Bu tanıklar yalnız geriye dönük diferansiyel regresyon kanıtıdır.
# Kaynak: Sargon17-Green/pastafari-calendar,
# implementations/tests/conformance-vectors.json, blob
# 53e43b8fec448cae3dc44001894accaf43348617.
# Kaynak dosya normativeAuthority=false der; bu nedenle bu tablo normatif oracle
# değildir ve İbranice Tomar'ın veya bağımsız normatif referansın yerine geçemez.
# Adlar, eski core.py içindeki kanonik sıra kullanılarak indekslere çevrilmiştir.
LEGACY_REGRESSION_WITNESSES = {
    "foundation_same": (
        -13_334_246,
        -13_334_246,
        (5000, 10, 503, 20, 56),
    ),
    "foundation_next": (
        -13_334_246,
        -13_334_245,
        (5000, 14, 1, 29, 38),
    ),
    "foundation_previous": (
        -13_334_246,
        -13_334_247,
        (5000, 10, 502, 32, 21),
    ),
    "present_same": (
        2_461_259,
        2_461_259,
        (5000, 3, 306, 42, 23),
    ),
    "present_forward": (
        2_461_259,
        2_461_265,
        (5000, 3, 312, 37, 33),
    ),
    "binding_5778_same": (
        -14_269_936,
        -14_269_936,
        (5000, 5, 1, 5, 93),
    ),
}


def _day_index(legacy_jdn: int) -> int:
    return legacy_jdn - LEGACY_JDN_TO_DAY_INDEX_OFFSET


def _canonical_ids(result) -> tuple[int, int, int, int, int]:
    cutlet_by_text = {
        item.text: item.canonical_index
        for item in SOURCE_LANGUAGE_CATALOG.cutlets
    }
    month_by_text = {
        item.text: item.canonical_index
        for item in SOURCE_LANGUAGE_CATALOG.months
    }
    return (
        result.year_number,
        cutlet_by_text[result.cutlet_name],
        result.day_in_cutlet,
        month_by_text[result.month_name],
        result.day_in_month,
    )


class ReleaseLegacyPythonDifferentialTests(unittest.TestCase):
    def setUp(self):
        # Her tanık gerçek bir soğuk production çağrısı olsun; önceki testin
        # sonuç gömme/cache izleri bir sonraki tanığı maskelemesin.
        reset_acceleration_scars_for_tests()

    def _assert_witness(self, witness_id: str) -> None:
        calculation_jdn, target_jdn, expected = LEGACY_REGRESSION_WITNESSES[
            witness_id
        ]
        result = calendar_date_spaghetti(
            _day_index(calculation_jdn),
            _day_index(target_jdn),
        )
        self.assertEqual(_canonical_ids(result), expected)

    def test_foundation_same(self):
        self._assert_witness("foundation_same")

    def test_foundation_next(self):
        self._assert_witness("foundation_next")

    def test_foundation_previous(self):
        self._assert_witness("foundation_previous")

    def test_present_same(self):
        self._assert_witness("present_same")

    def test_present_forward(self):
        self._assert_witness("present_forward")

    def test_binding_5778_same(self):
        self._assert_witness("binding_5778_same")


if __name__ == "__main__":
    unittest.main()
