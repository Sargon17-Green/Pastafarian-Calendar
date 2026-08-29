from .legacy_day_counts import FOUNDATION_DAY_OLD


def oldGateQuestionDay(
    n: int,
) -> int:
    if n < 0:
        raise ValueError("Legacy gate uzaklığı negatif olamaz")

    # Tarihsel kusur: yön işareti yok sayılır ve her gate sorusu
    # Foundation'ın pozitif tarafına taşınır.
    return FOUNDATION_DAY_OLD + n


class NegativeGatePatchWrapper:
    def repair(
        self,
        ctx,
        signed_step: int,
        magnitude: int,
    ) -> int:
        legacy_positive_day = oldGateQuestionDay(
            magnitude,
        )

        ctx.branch_trace.append(
            (
                "YAMA_15_NEGATİF_GATE",
                signed_step,
                magnitude,
            )
        )
        ctx.logs.append(
            (
                "yama-15-negatif-gate",
                signed_step,
                magnitude,
            )
        )

        if signed_step < 0:
            corrected_day = (
                FOUNDATION_DAY_OLD
                - magnitude
            )
            used_negative_detour = True
        else:
            corrected_day = legacy_positive_day
            used_negative_detour = False

        ctx.patch15_signed_step = signed_step
        ctx.patch15_legacy_positive_day = legacy_positive_day
        ctx.patch15_corrected_day = corrected_day
        ctx.patch15_used_negative_detour = used_negative_detour
        ctx.patch15_applied = True

        return corrected_day


class LegacyGateQuestionAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = NegativeGatePatchWrapper()

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

        question_day = self.patch_wrapper.repair(
            ctx,
            signed_step,
            magnitude,
        )

        ctx.legacy_gate_signed_step = signed_step
        ctx.legacy_gate_magnitude = magnitude
        ctx.legacy_gate_question_day = question_day

        return question_day
