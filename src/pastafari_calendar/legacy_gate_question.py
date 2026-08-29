from .legacy_day_counts import FOUNDATION_DAY_OLD


def oldGateQuestionDay(
    n: int,
) -> int:
    if n < 0:
        raise ValueError("Legacy gate uzaklığı negatif olamaz")

    # Tarihsel kusur: yön işareti yok sayılır ve her gate sorusu
    # Foundation'ın pozitif tarafına taşınır.
    return FOUNDATION_DAY_OLD + n


class LegacyGateQuestionAdapter:
    def call(
        self,
        ctx,
        signed_step: int,
    ) -> int:
        if type(signed_step) is not int:
            raise TypeError("İmzalı gate adımı tam sayı olmalıdır")

        magnitude = abs(
            signed_step,
        )

        ctx.branch_trace.append(
            (
                "ESKİ_GATE_SORU_GÜNÜ",
                signed_step,
                magnitude,
            )
        )
        ctx.logs.append(
            (
                "eski-gate-soru-günü",
                signed_step,
                magnitude,
            )
        )

        question_day = oldGateQuestionDay(
            magnitude,
        )

        ctx.legacy_gate_signed_step = signed_step
        ctx.legacy_gate_magnitude = magnitude
        ctx.legacy_gate_question_day = question_day

        return question_day
