from __future__ import annotations

from collections import OrderedDict, deque
from contextlib import contextmanager
from dataclasses import dataclass, field
from hashlib import blake2b
from threading import RLock, local
from typing import Any, Generic, Hashable, Iterator, TypeVar

from .legacy_arithmetic import M_OLD
from .legacy_day_counts import FOUNDATION_DAY_OLD
from .source_language_catalog import SOURCE_LANGUAGE_CATALOG


ACCELERATION_ENABLED = True
ACCELERATION_GHOST_VALIDATION = False
ACCELERATION_GHOST_SAMPLE_MODULUS = 1

MAX_FINAL_RESULT_CACHE = 4096
MAX_YEAR_STRUCTURE_CACHE = 2048
MAX_YEAR_CHECKPOINTS = 8192
MAX_GATE_SHARDS = 1024
MAX_SELECTION_ORACLE = 16384

YEAR_CHECKPOINT_STRIDE = 256
GATE_SHARD_SIZE = 512
ACCELERATION_SCAR_GENERATION = 33


@dataclass(slots=True)
class AccelerationScarContext:
    enabled: bool = False
    final_cache_hits: int = 0
    final_cache_misses: int = 0
    final_cache_stale: int = 0
    final_cache_stores: int = 0
    final_cache_evictions: int = 0
    checkpoint_hits: int = 0
    checkpoint_misses: int = 0
    checkpoint_distance_saved: int = 0
    checkpoint_created: int = 0
    checkpoint_rejected: int = 0
    checkpoint_evictions: int = 0
    gate_shard_hits: int = 0
    gate_shard_misses: int = 0
    gate_shard_loaded_days: int = 0
    gate_shard_generated_days: int = 0
    gate_shard_poisoned: int = 0
    gate_shard_evictions: int = 0
    year_structure_hits: int = 0
    year_structure_misses: int = 0
    year_structure_stale: int = 0
    year_structure_stores: int = 0
    year_structure_evictions: int = 0
    oracle_hits: int = 0
    oracle_misses: int = 0
    oracle_false_prophecies: int = 0
    oracle_saved_iterations: int = 0
    oracle_evictions: int = 0
    rollback_legacy_success: int = 0
    rollback_containment_applied: int = 0
    rollback_containment_fields_restored: int = 0
    ghost_validations: int = 0
    ghost_divergences: int = 0
    poisoned_entries: set[Hashable] = field(default_factory=set)
    bypassed_scars: list[str] = field(default_factory=list)
    prophecies: list[str] = field(default_factory=list)
    scar_generation: int = ACCELERATION_SCAR_GENERATION


@dataclass(slots=True)
class BuriedCalendarResult:
    calculation_day: int
    target_day: int
    result: Any
    semantic_fingerprint: tuple[Any, ...]
    scar_generation: int
    created_from_full_monster_run: bool
    poisoned: bool = False
    poison_reason: str | None = None


@dataclass(frozen=True, slots=True)
class YearCheckpoint:
    calculation_day: int
    year_number: int
    first_day: int
    last_day: int
    open_gate_index: int
    close_gate_index: int
    relevant_gate_index: int
    semantic_fingerprint: tuple[Any, ...]


@dataclass(slots=True)
class GateShard:
    start_index: int
    end_index: int
    days: tuple[int, ...]
    semantic_fingerprint: tuple[Any, ...]
    verified: bool
    poisoned: bool = False
    poison_reason: str | None = None


@dataclass(frozen=True, slots=True)
class YearStructureCacheKey:
    calculation_day: int
    year_number: int
    first_day: int
    last_day: int
    gate_identity: tuple[int, int]
    semantic_fingerprint: tuple[Any, ...]


@dataclass(frozen=True, slots=True)
class SelectionOracleKey:
    ring_identity: tuple[int, int]
    family_count: int
    limit: int
    question_identity: Hashable
    semantic_fingerprint: tuple[Any, ...]


@dataclass(slots=True)
class RememberedSelectionOffset:
    offset: int
    accepted_answer: int
    semantic_fingerprint: tuple[Any, ...]
    poisoned: bool = False


K = TypeVar("K", bound=Hashable)
V = TypeVar("V")


class _BoundedScarStore(Generic[K, V]):
    def __init__(self, maximum: int) -> None:
        self.maximum = maximum
        self._entries: OrderedDict[K, V] = OrderedDict()
        self._lock = RLock()
        self.evictions = 0

    def get(self, key: K) -> V | None:
        with self._lock:
            value = self._entries.get(key)
            if value is not None:
                self._entries.move_to_end(key)
            return value

    def put(self, key: K, value: V) -> bool:
        evicted = False
        with self._lock:
            if key in self._entries:
                self._entries[key] = value
                self._entries.move_to_end(key)
                return False
            self._entries[key] = value
            if len(self._entries) > self.maximum:
                self._entries.popitem(last=False)
                self.evictions += 1
                evicted = True
        return evicted

    def remove(self, key: K) -> V | None:
        with self._lock:
            return self._entries.pop(key, None)

    def items_snapshot(self) -> tuple[tuple[K, V], ...]:
        with self._lock:
            return tuple(self._entries.items())

    def clear(self) -> None:
        with self._lock:
            self._entries.clear()
            self.evictions = 0

    def __len__(self) -> int:
        with self._lock:
            return len(self._entries)


_FINAL_RESULTS = _BoundedScarStore[tuple[int, int], BuriedCalendarResult](
    MAX_FINAL_RESULT_CACHE
)
_YEAR_STRUCTURES = _BoundedScarStore[YearStructureCacheKey, Any](
    MAX_YEAR_STRUCTURE_CACHE
)
_YEAR_CHECKPOINTS = _BoundedScarStore[tuple[int, int], YearCheckpoint](
    MAX_YEAR_CHECKPOINTS
)
_GATE_SHARDS = _BoundedScarStore[tuple[int, int], GateShard](MAX_GATE_SHARDS)
_SELECTION_ORACLE = _BoundedScarStore[SelectionOracleKey, RememberedSelectionOffset](
    MAX_SELECTION_ORACLE
)

_registry_lock = RLock()
_checkpoint_search_counts: OrderedDict[tuple[int, int], int] = OrderedDict()
_poisoned_registry: OrderedDict[Hashable, str] = OrderedDict()
_global_metrics: dict[str, int] = {}
_global_trace: deque[tuple[Any, ...]] = deque(maxlen=4096)
_thread_state = local()
_TEST_FINGERPRINT_SALT: Hashable = ""


def _bump_global(key: str, amount: int = 1) -> None:
    with _registry_lock:
        _global_metrics[key] = _global_metrics.get(key, 0) + amount


def global_acceleration_metrics() -> dict[str, int]:
    with _registry_lock:
        return dict(_global_metrics)


def acceleration_trace_snapshot() -> tuple[tuple[Any, ...], ...]:
    with _registry_lock:
        return tuple(_global_trace)


def _remember_poison(key: Hashable, reason: str) -> None:
    with _registry_lock:
        _poisoned_registry[key] = reason
        _poisoned_registry.move_to_end(key)
        while len(_poisoned_registry) > 4096:
            _poisoned_registry.popitem(last=False)


def poisoned_acceleration_entries() -> tuple[tuple[Hashable, str], ...]:
    with _registry_lock:
        return tuple(_poisoned_registry.items())


def _stable_code_mark(value: Any) -> tuple[str, str] | None:
    code = getattr(value, "__code__", None)
    if code is None:
        return None
    digest = blake2b(code.co_code, digest_size=8).hexdigest()
    return (getattr(value, "__qualname__", getattr(value, "__name__", "?")), digest)


def semantic_fingerprint(*implementation_marks: Any) -> tuple[Any, ...]:
    catalog_identity = (
        SOURCE_LANGUAGE_CATALOG.version,
        SOURCE_LANGUAGE_CATALOG.natural_language,
        tuple(item.text for item in SOURCE_LANGUAGE_CATALOG.cutlets),
        tuple(item.text for item in SOURCE_LANGUAGE_CATALOG.months),
    )
    stable_marks = tuple(
        mark
        for mark in (_stable_code_mark(value) for value in implementation_marks)
        if mark is not None
    )
    return (
        "patch27-33-semantic-scar",
        ACCELERATION_SCAR_GENERATION,
        M_OLD,
        FOUNDATION_DAY_OLD,
        922,
        41,
        252,
        5778,
        6,
        17,
        3,
        47,
        4,
        123,
        catalog_identity,
        stable_marks,
        _TEST_FINGERPRINT_SALT,
    )


def set_test_fingerprint_salt(value: Hashable) -> None:
    global _TEST_FINGERPRINT_SALT
    _TEST_FINGERPRINT_SALT = value


def acceleration_enabled() -> bool:
    override = getattr(_thread_state, "acceleration_override", None)
    configured = ACCELERATION_ENABLED if override is None else bool(override)
    return bool(configured) and not bool(
        getattr(_thread_state, "force_legacy_full_walk", False)
    )


@contextmanager
def acceleration_mode(enabled: bool) -> Iterator[None]:
    previous = getattr(_thread_state, "acceleration_override", None)
    _thread_state.acceleration_override = bool(enabled)
    try:
        yield
    finally:
        if previous is None:
            try:
                delattr(_thread_state, "acceleration_override")
            except AttributeError:
                pass
        else:
            _thread_state.acceleration_override = previous


@contextmanager
def forced_legacy_full_walk() -> Iterator[None]:
    previous = bool(getattr(_thread_state, "force_legacy_full_walk", False))
    _thread_state.force_legacy_full_walk = True
    try:
        yield
    finally:
        _thread_state.force_legacy_full_walk = previous


def reset_acceleration_scars_for_tests() -> None:
    _FINAL_RESULTS.clear()
    _YEAR_STRUCTURES.clear()
    _YEAR_CHECKPOINTS.clear()
    _GATE_SHARDS.clear()
    _SELECTION_ORACLE.clear()
    with _registry_lock:
        _checkpoint_search_counts.clear()
        _poisoned_registry.clear()
        _global_metrics.clear()
        _global_trace.clear()


def _trace(ctx: Any, metric: str, branch: tuple[Any, ...], log: tuple[Any, ...]) -> None:
    ctx.metrics[metric] = ctx.metrics.get(metric, 0) + 1
    ctx.branch_trace.append(branch)
    ctx.logs.append(log)
    with _registry_lock:
        _global_trace.append((metric,) + branch)
    _bump_global(metric)


def lookup_final_result(ctx: Any, fingerprint: tuple[Any, ...]) -> BuriedCalendarResult | None:
    key = (ctx.calculation_day, ctx.target_day)
    entry = _FINAL_RESULTS.get(key)
    if entry is None:
        ctx.acceleration_scars.final_cache_misses += 1
        _trace(ctx, "final_result_cache_miss", ("YAMA_27_FINAL_BURIAL_MISS", key), ("yama-27-final-burial-miss", key))
        return None
    if entry.poisoned or entry.semantic_fingerprint != fingerprint:
        stale_reason = (
            entry.poison_reason
            if entry.poisoned
            else "semantic-fingerprint-stale"
        )
        ctx.acceleration_scars.final_cache_stale += 1
        ctx.acceleration_scars.poisoned_entries.add(("patch27", key))
        _remember_poison(("patch27", key), stale_reason or "poisoned")
        _trace(ctx, "final_result_cache_stale", ("YAMA_27_FINAL_BURIAL_STALE", key), ("yama-27-final-burial-stale", key))
        return None
    ctx.acceleration_scars.final_cache_hits += 1
    ctx.acceleration_scars.bypassed_scars.append("patch27:monster-burial-resurrection")
    _trace(ctx, "final_result_cache_hit", ("YAMA_27_FINAL_BURIAL_HIT", key), ("yama-27-final-burial-hit", key))
    return entry


def store_final_result(ctx: Any, result: Any, fingerprint: tuple[Any, ...], *, full_monster_run: bool) -> None:
    key = (ctx.calculation_day, ctx.target_day)
    existing = _FINAL_RESULTS.get(key)
    if existing is not None and existing.semantic_fingerprint == fingerprint and not existing.poisoned:
        return
    entry = BuriedCalendarResult(
        calculation_day=ctx.calculation_day,
        target_day=ctx.target_day,
        result=result,
        semantic_fingerprint=fingerprint,
        scar_generation=ACCELERATION_SCAR_GENERATION,
        created_from_full_monster_run=full_monster_run,
    )
    evicted = _FINAL_RESULTS.put(key, entry)
    ctx.acceleration_scars.final_cache_stores += 1
    _trace(ctx, "final_result_cache_store", ("YAMA_27_FINAL_BURIAL_STORE", key), ("yama-27-final-burial-store", key))
    if evicted:
        ctx.acceleration_scars.final_cache_evictions += 1
        _trace(ctx, "final_result_cache_eviction", ("YAMA_27_FINAL_BURIAL_EVICTION",), ("yama-27-final-burial-eviction",))


def poison_final_result(ctx: Any, reason: str) -> None:
    key = (ctx.calculation_day, ctx.target_day)
    _FINAL_RESULTS.remove(key)
    ctx.acceleration_scars.poisoned_entries.add(("patch27", key))
    _remember_poison(("patch27", key), reason)


def should_ghost_validate(calculation_day: int, target_day: int) -> bool:
    if not ACCELERATION_GHOST_VALIDATION:
        return False
    modulus = max(1, int(ACCELERATION_GHOST_SAMPLE_MODULUS))
    deterministic = (calculation_day * 1000003 + target_day * 9176 + 33) % modulus
    return deterministic == 0


def checkpoint_note_search(calculation_day: int, year_number: int) -> int:
    key = (calculation_day, year_number)
    with _registry_lock:
        count = _checkpoint_search_counts.get(key, 0) + 1
        _checkpoint_search_counts[key] = count
        _checkpoint_search_counts.move_to_end(key)
        while len(_checkpoint_search_counts) > MAX_YEAR_CHECKPOINTS * 2:
            _checkpoint_search_counts.popitem(last=False)
        return count


def store_year_checkpoint(ctx: Any, checkpoint: YearCheckpoint, *, forced: bool = False) -> None:
    if not ctx.acceleration_scars.enabled:
        return
    if not forced and checkpoint.year_number % YEAR_CHECKPOINT_STRIDE != 0:
        return
    key = (checkpoint.calculation_day, checkpoint.year_number)
    if _YEAR_CHECKPOINTS.get(key) is not None:
        return
    evicted = _YEAR_CHECKPOINTS.put(key, checkpoint)
    ctx.acceleration_scars.checkpoint_created += 1
    if evicted:
        ctx.acceleration_scars.checkpoint_evictions += 1
        ctx.metrics["year_checkpoint_eviction"] = (
            ctx.metrics.get("year_checkpoint_eviction", 0) + 1
        )
    _trace(ctx, "year_checkpoint_created", ("YAMA_28_CHECKPOINT_CREATED", checkpoint.year_number, checkpoint.first_day, checkpoint.last_day), ("yama-28-checkpoint-created", checkpoint.year_number, checkpoint.first_day, checkpoint.last_day))


def nearest_year_checkpoint(ctx: Any, calculation_day: int, target_day: int, fingerprint: tuple[Any, ...], anchor_first_day: int, anchor_last_day: int) -> YearCheckpoint | None:
    candidates: list[tuple[int, YearCheckpoint]] = []
    for (calc, _year), checkpoint in _YEAR_CHECKPOINTS.items_snapshot():
        if calc != calculation_day:
            continue
        if checkpoint.semantic_fingerprint != fingerprint:
            ctx.acceleration_scars.checkpoint_rejected += 1
            ctx.acceleration_scars.poisoned_entries.add(("patch28", calc, checkpoint.year_number))
            _remember_poison(("patch28", calc, checkpoint.year_number), "semantic-fingerprint-stale")
            _trace(ctx, "year_checkpoint_rejected", ("YAMA_28_CHECKPOINT_REJECTED", checkpoint.year_number), ("yama-28-checkpoint-rejected", checkpoint.year_number))
            continue
        if checkpoint.first_day <= target_day <= checkpoint.last_day:
            distance = 0
        elif target_day < checkpoint.first_day:
            distance = checkpoint.first_day - target_day
        else:
            distance = target_day - checkpoint.last_day
        candidates.append((distance, checkpoint))
    if not candidates:
        ctx.acceleration_scars.checkpoint_misses += 1
        _trace(ctx, "year_checkpoint_miss", ("YAMA_28_CHECKPOINT_MISS", target_day), ("yama-28-checkpoint-miss", target_day))
        return None
    candidates.sort(key=lambda item: (item[0], abs(item[1].year_number - 5000)))
    distance, checkpoint = candidates[0]
    if anchor_first_day <= target_day <= anchor_last_day:
        anchor_distance = 0
    elif target_day < anchor_first_day:
        anchor_distance = anchor_first_day - target_day
    else:
        anchor_distance = target_day - anchor_last_day
    if distance >= anchor_distance:
        ctx.acceleration_scars.checkpoint_misses += 1
        _trace(ctx, "year_checkpoint_miss", ("YAMA_28_CHECKPOINT_NOT_CLOSER", checkpoint.year_number, distance, anchor_distance), ("yama-28-checkpoint-not-closer", checkpoint.year_number, distance, anchor_distance))
        return None
    ctx.acceleration_scars.checkpoint_hits += 1
    saved = abs(checkpoint.year_number - 5000)
    ctx.acceleration_scars.checkpoint_distance_saved += saved
    ctx.acceleration_scars.bypassed_scars.append("patch28:prophetic-year-checkpoint")
    _trace(ctx, "year_checkpoint_hit", ("YAMA_28_CHECKPOINT_HIT", checkpoint.year_number, saved), ("yama-28-checkpoint-hit", checkpoint.year_number, saved))
    if saved:
        ctx.metrics["year_checkpoint_distance_saved"] = ctx.metrics.get("year_checkpoint_distance_saved", 0) + saved
        _bump_global("year_checkpoint_distance_saved", saved)
    return checkpoint


def poison_year_checkpoint(ctx: Any, checkpoint: YearCheckpoint, reason: str) -> None:
    key = (checkpoint.calculation_day, checkpoint.year_number)
    _YEAR_CHECKPOINTS.remove(key)
    ctx.acceleration_scars.checkpoint_rejected += 1
    ctx.acceleration_scars.poisoned_entries.add(("patch28",) + key)
    _remember_poison(("patch28",) + key, reason)
    _trace(ctx, "year_checkpoint_rejected", ("YAMA_28_CHECKPOINT_POISONED", checkpoint.year_number, reason), ("yama-28-checkpoint-poisoned", checkpoint.year_number, reason))


def _shard_key_for_index(index: int) -> tuple[int, int]:
    if index > 0:
        start = ((index - 1) // GATE_SHARD_SIZE) * GATE_SHARD_SIZE + 1
        return (start, start + GATE_SHARD_SIZE - 1)
    if index < 0:
        end = -(((-index - 1) // GATE_SHARD_SIZE) * GATE_SHARD_SIZE + 1)
        start = end - GATE_SHARD_SIZE + 1
        return (start, end)
    return (0, 0)


def lookup_gate_shard(ctx: Any, index: int, fingerprint: tuple[Any, ...]) -> GateShard | None:
    if index == 0:
        return None
    key = _shard_key_for_index(index)
    shard = _GATE_SHARDS.get(key)
    if shard is None:
        ctx.acceleration_scars.gate_shard_misses += 1
        _trace(ctx, "gate_shard_miss", ("YAMA_29_GATE_SHARD_MISS", key), ("yama-29-gate-shard-miss", key))
        return None
    if shard.poisoned or not shard.verified or shard.semantic_fingerprint != fingerprint:
        poison_reason = "semantic-fingerprint-or-verification-stale"
        _GATE_SHARDS.remove(key)
        ctx.acceleration_scars.gate_shard_poisoned += 1
        ctx.acceleration_scars.poisoned_entries.add(("patch29", key))
        _remember_poison(("patch29", key), poison_reason)
        _trace(ctx, "gate_shard_poisoned", ("YAMA_29_GATE_SHARD_POISONED", key), ("yama-29-gate-shard-poisoned", key))
        return None
    ctx.acceleration_scars.gate_shard_hits += 1
    ctx.acceleration_scars.bypassed_scars.append("patch29:gate-shard-resurrection")
    _trace(ctx, "gate_shard_hit", ("YAMA_29_GATE_SHARD_HIT", key), ("yama-29-gate-shard-hit", key))
    return shard


def store_gate_shard(ctx: Any, start_index: int, days: tuple[int, ...], fingerprint: tuple[Any, ...]) -> None:
    if len(days) != GATE_SHARD_SIZE:
        return
    end_index = start_index + len(days) - 1
    key = (start_index, end_index)
    existing = _GATE_SHARDS.get(key)
    if existing is not None and existing.semantic_fingerprint == fingerprint and existing.verified and not existing.poisoned:
        return
    shard = GateShard(start_index, end_index, days, fingerprint, True)
    evicted = _GATE_SHARDS.put(key, shard)
    if evicted:
        ctx.acceleration_scars.gate_shard_evictions += 1
        ctx.metrics["gate_shard_eviction"] = (
            ctx.metrics.get("gate_shard_eviction", 0) + 1
        )
    ctx.acceleration_scars.gate_shard_generated_days += len(days)
    ctx.metrics["gate_shard_generated_days"] = ctx.metrics.get("gate_shard_generated_days", 0) + len(days)
    _bump_global("gate_shard_generated_days", len(days))
    ctx.branch_trace.append(("YAMA_29_GATE_SHARD_BURIED", start_index, end_index))
    ctx.logs.append(("yama-29-gate-shard-buried", start_index, end_index))


def year_structure_lookup(ctx: Any, key: YearStructureCacheKey) -> Any | None:
    value = _YEAR_STRUCTURES.get(key)
    if value is not None:
        ctx.acceleration_scars.year_structure_hits += 1
        ctx.acceleration_scars.bypassed_scars.append("patch30:semantic-year-structure-resurrection")
        _trace(ctx, "year_structure_cache_hit", ("YAMA_30_STRUCTURE_HIT", key.year_number), ("yama-30-structure-hit", key.year_number))
        return value
    stale_same_shape = False
    for candidate_key, _candidate in _YEAR_STRUCTURES.items_snapshot():
        if (
            candidate_key.calculation_day == key.calculation_day
            and candidate_key.year_number == key.year_number
            and candidate_key.first_day == key.first_day
            and candidate_key.last_day == key.last_day
            and candidate_key.gate_identity == key.gate_identity
            and candidate_key.semantic_fingerprint != key.semantic_fingerprint
        ):
            stale_same_shape = True
            _remember_poison(("patch30", candidate_key), "semantic-fingerprint-stale")
            break
    if stale_same_shape:
        ctx.acceleration_scars.year_structure_stale += 1
        _trace(ctx, "year_structure_cache_stale", ("YAMA_30_STRUCTURE_STALE", key.year_number), ("yama-30-structure-stale", key.year_number))
    else:
        ctx.acceleration_scars.year_structure_misses += 1
        _trace(ctx, "year_structure_cache_miss", ("YAMA_30_STRUCTURE_MISS", key.year_number), ("yama-30-structure-miss", key.year_number))
    return None


def year_structure_store(ctx: Any, key: YearStructureCacheKey, value: Any) -> None:
    evicted = _YEAR_STRUCTURES.put(key, value)
    ctx.acceleration_scars.year_structure_stores += 1
    _trace(ctx, "year_structure_cache_store", ("YAMA_30_STRUCTURE_STORE", key.year_number), ("yama-30-structure-store", key.year_number))
    if evicted:
        ctx.acceleration_scars.year_structure_evictions += 1
        _trace(ctx, "year_structure_cache_eviction", ("YAMA_30_STRUCTURE_EVICTION",), ("yama-30-structure-eviction",))


def oracle_lookup(ctx: Any, key: SelectionOracleKey) -> RememberedSelectionOffset | None:
    remembered = _SELECTION_ORACLE.get(key)
    if remembered is None:
        ctx.acceleration_scars.oracle_misses += 1
        _trace(ctx, "selection_oracle_miss", ("YAMA_31_ORACLE_MISS", key.question_identity), ("yama-31-oracle-miss", key.question_identity))
        return None
    if remembered.poisoned or remembered.semantic_fingerprint != key.semantic_fingerprint:
        _SELECTION_ORACLE.remove(key)
        ctx.acceleration_scars.oracle_false_prophecies += 1
        _remember_poison(("patch31", key), "semantic-fingerprint-stale")
        _trace(ctx, "selection_oracle_false_prophecy", ("YAMA_31_ORACLE_STALE", key.question_identity), ("yama-31-oracle-stale", key.question_identity))
        return None
    return remembered


def oracle_false_prophecy(ctx: Any, key: SelectionOracleKey, remembered: RememberedSelectionOffset) -> None:
    _SELECTION_ORACLE.remove(key)
    ctx.acceleration_scars.oracle_false_prophecies += 1
    ctx.acceleration_scars.poisoned_entries.add(("patch31", key))
    _remember_poison(("patch31", key), "remembered-offset-no-longer-accepted")
    _trace(ctx, "selection_oracle_false_prophecy", ("YAMA_31_ORACLE_FALSE_PROPHECY", key.question_identity, remembered.offset), ("yama-31-oracle-false-prophecy", key.question_identity, remembered.offset))


def oracle_accept_hit(ctx: Any, key: SelectionOracleKey, remembered: RememberedSelectionOffset) -> None:
    ctx.acceleration_scars.oracle_hits += 1
    ctx.acceleration_scars.oracle_saved_iterations += remembered.offset
    ctx.acceleration_scars.prophecies.append(f"patch31:{key.question_identity!r}@{remembered.offset}")
    ctx.acceleration_scars.bypassed_scars.append("patch31:remembered-selection-offset")
    _trace(ctx, "selection_oracle_hit", ("YAMA_31_ORACLE_HIT", key.question_identity, remembered.offset), ("yama-31-oracle-hit", key.question_identity, remembered.offset))
    if remembered.offset:
        ctx.metrics["selection_oracle_saved_iterations"] = ctx.metrics.get("selection_oracle_saved_iterations", 0) + remembered.offset
        _bump_global("selection_oracle_saved_iterations", remembered.offset)


def oracle_store(ctx: Any, key: SelectionOracleKey, offset: int, accepted_answer: int) -> None:
    remembered = RememberedSelectionOffset(offset, accepted_answer, key.semantic_fingerprint)
    evicted = _SELECTION_ORACLE.put(key, remembered)
    if evicted:
        ctx.acceleration_scars.oracle_evictions += 1
        ctx.metrics["selection_oracle_eviction"] = (
            ctx.metrics.get("selection_oracle_eviction", 0) + 1
        )
    ctx.branch_trace.append(("YAMA_31_ORACLE_REMEMBERED", key.question_identity, offset))
    ctx.logs.append(("yama-31-oracle-remembered", key.question_identity, offset))


def cache_sizes() -> dict[str, int]:
    return {
        "final_results": len(_FINAL_RESULTS),
        "year_structures": len(_YEAR_STRUCTURES),
        "year_checkpoints": len(_YEAR_CHECKPOINTS),
        "gate_shards": len(_GATE_SHARDS),
        "selection_oracle": len(_SELECTION_ORACLE),
    }
