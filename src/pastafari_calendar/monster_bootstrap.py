from dataclasses import dataclass, field
from typing import Any, Callable

from .legacy_arithmetic import LegacyRemainderAdapter
from .legacy_day_counts import LegacyDayTagAdapter
from .legacy_distance import LegacyDistanceAdapter
from .legacy_stones import LegacyStoneBuilderAdapter


class MonsterError(RuntimeError):
    pass


class MonsterValidationError(MonsterError):
    pass


class StageNotIntegratedError(MonsterError):
    pass


@dataclass(slots=True)
class MonsterContext:
    calculation_day: int
    target_day: int
    phase: str = "GİRİŞ"
    sub_phase: int = 0
    mode: str = "AŞAMA_01_TARAFSIZ"
    status: str = "YENİ"
    retry_budget: int = 0
    recovery_depth: int = 0
    current_handler: str | None = None
    previous_handler: str | None = None
    branch_trace: list[Any] = field(default_factory=list)
    metrics: dict[str, int] = field(default_factory=dict)
    logs: list[tuple[Any, ...]] = field(default_factory=list)
    diagnostics: list[Any] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    last_error: Exception | None = None
    validation_failures: list[str] = field(default_factory=list)
    legacy_remainder_input: int | None = None
    legacy_remainder_value: int | None = None
    patch01_input: int | None = None
    patch01_value: int | None = None
    patch01_applied: bool = False
    legacy_action_day_tag_input: int | None = None
    legacy_action_day_tag_value: int | None = None
    legacy_target_day_tag_input: int | None = None
    legacy_target_day_tag_value: int | None = None
    patch02_action_day_tag_input: int | None = None
    patch02_action_day_tag_value: int | None = None
    patch02_action_applied: bool = False
    patch02_target_day_tag_input: int | None = None
    patch02_target_day_tag_value: int | None = None
    patch02_target_applied: bool = False
    patch02_foundation_guard_seen: bool = False
    legacy_distance_calculation_day: int | None = None
    legacy_distance_target_day: int | None = None
    legacy_distance_value: int | None = None
    patch03_chronological_distance: int | None = None
    patch03_distance_value: int | None = None
    patch03_legacy_replaced: bool = False
    patch03_applied: bool = False
    legacy_stone_table: tuple[tuple[int, ...], ...] | None = None
    legacy_stone_rows_built: int = 0


class BaseMetrics:
    def bump(self, ctx: MonsterContext, key: str) -> None:
        ctx.metrics[key] = ctx.metrics.get(key, 0) + 1


class BaseValidator:
    def require_integer_day(self, ctx: MonsterContext, value: Any, field_name: str) -> None:
        if type(value) is not int:
            message = f"{field_name} tam sayı olmalıdır"
            ctx.validation_failures.append(message)
            raise MonsterValidationError(message)

    def require_context_owned(self, ctx: MonsterContext, calculation_day: int, target_day: int) -> None:
        if ctx.calculation_day != calculation_day or ctx.target_day != target_day:
            message = "Çağrı bağlamının sahipliği bozuldu"
            ctx.validation_failures.append(message)
            raise MonsterValidationError(message)


class BaseErrorWrapper:
    def wrap(self, ctx: MonsterContext, error: Exception, phase: str) -> MonsterError:
        wrapped = MonsterError(f"{phase} aşamasında hata: {error}")
        ctx.last_error = wrapped
        return wrapped


class BaseDispatcher:
    def __init__(self) -> None:
        self._handlers: dict[str, Callable[[MonsterContext], None]] = {}

    def register(self, phase: str, handler: Callable[[MonsterContext], None]) -> None:
        if phase in self._handlers:
            raise MonsterValidationError("Aynı aşama için iki temel işleyici kaydedilemez")
        self._handlers[phase] = handler

    def dispatch(self, ctx: MonsterContext) -> None:
        handler = self._handlers.get(ctx.phase)
        if handler is None:
            raise MonsterValidationError("Temel dağıtıcı bilinmeyen bir aşama gördü")
        ctx.previous_handler = ctx.current_handler
        ctx.current_handler = handler.__name__
        handler(ctx)


class MonsterManager:
    def __init__(self) -> None:
        self.metrics = BaseMetrics()
        self.validator = BaseValidator()
        self.error_wrapper = BaseErrorWrapper()
        self.dispatcher = BaseDispatcher()
        self.legacy_arithmetic = LegacyRemainderAdapter()
        self.legacy_day_tags = LegacyDayTagAdapter()
        self.legacy_distance = LegacyDistanceAdapter()
        self.legacy_stones = LegacyStoneBuilderAdapter()
