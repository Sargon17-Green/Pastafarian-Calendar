#!/usr/bin/env python3
"""Crash-durable, fail-closed chunk ledger for full-year differential soak.

No engines are launched here. One supervisor owns the ledger at a time.
A chunk covers a contiguous subsection of one *complete planned year*, never a
substitute for complete-year acceptance. The five numeric canonical fields are
compared immediately after each candidate chunk becomes durable; whole-year
PASS is committed only after all chunks of both engines are present and equal.

This is a foundational ledger, not a production-certified Windows scheduler.
"""
from __future__ import annotations

import hashlib
import json
import os
import pathlib
import sqlite3
import threading
from dataclasses import dataclass
from typing import Any

from year_validator import YearCase, parse_line


CONTRACT = "PASTAFARI_SOAK_RECOVERY/1"
KEYS = ("calculation_day", "target_day", "year", "cutlet_index", "day_in_cutlet", "month_index", "day_in_month", "cutlet_name_raw", "month_name_raw", "source_raw_sha256")


def canonical_bytes(data: Any) -> bytes:
    return json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False).encode("utf-8")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _duplicates_error(pairs):
    d = {}
    for key, value in pairs:
        if key in d:
            raise ValueError("duplicate JSON key: " + key)
        d[key] = value
    return d


def _integer_string(s: str) -> bool:
    return isinstance(s, str) and (s == "0" or (s.lstrip("-").isdigit() and not s.startswith("0") and not s.startswith("-0")))


def validate_plan(plan: dict) -> None:
    if not isinstance(plan, dict) or plan.get("contract") != CONTRACT:
        raise ValueError("wrong run-plan contract")
    if not _integer_string(plan.get("calculation_day")):
        raise ValueError("invalid calculation day")
    if type(plan.get("chunk_days")) is not int or not 1 <= plan["chunk_days"] <= 3650:
        raise ValueError("invalid checkpoint chunk size")
    engines = plan.get("engines")
    years = plan.get("years")
    if not isinstance(engines, list) or len(engines) < 2:
        raise ValueError("at least two engines required")
    if not isinstance(years, list) or not years:
        raise ValueError("full-year boundaries required")
    seen_engines = set()
    seen_algo = set()
    for engine in engines:
        if not isinstance(engine, dict):
            raise ValueError("invalid engine descriptor")
        engine_id, algorithm_id = engine.get("id"), engine.get("algorithm_id")
        if not isinstance(engine_id, str) or not engine_id or engine_id in seen_engines:
            raise ValueError("repeated or blank engine ID")
        if not isinstance(algorithm_id, str) or not algorithm_id or algorithm_id in seen_algo:
            raise ValueError("duplicate/blank underlying algorithm; a wrapper is not an independent engine")
        for field in ("source_sha256", "binary_sha256", "name_map_sha256"):
            v = engine.get(field)
            if not isinstance(v, str) or len(v) != 64 or any(c not in "0123456789abcdef" for c in v):
                raise ValueError("unpinned engine: " + engine_id + "/" + field)
        seen_engines.add(engine_id)
        seen_algo.add(algorithm_id)
    seen_years = set()
    previous_last = None
    for y in years:
        if not isinstance(y, dict) or not _integer_string(y.get("year")):
            raise ValueError("invalid year entry")
        key = y["year"]
        if key in seen_years:
            raise ValueError("duplicate year")
        case = YearCase(plan["calculation_day"], key, y.get("first_target_day"),
                        y.get("last_target_day"), y.get("boundary_evidence_sha256"))
        case.validate()
        # Adjacent target ranges, if consecutive years are selected in calendar order.
        if previous_last is not None and int(y["first_target_day"]) != previous_last + 1:
            raise ValueError("gaps/overlap in consecutive-year plan")
        previous_last = int(y["last_target_day"])
        seen_years.add(key)


class Halted(RuntimeError):
    """Run has irreversibly halted pending operator investigation."""


class PlanMismatch(RuntimeError):
    pass


@dataclass(frozen=True)
class Chunk:
    engine_id: str
    year: str
    first_day: str
    last_day: str
    ordinal: int


class CrashStore:
    """Single-process SQLite/WAL ledger; all file receipts are content-verified.

    Single-writer lock persists in root/OWNED_SUPERVISOR.lock, never deleted.
    Abnormally terminated OS processes release the advisory lock automatically.
    """
    def __init__(self, root: pathlib.Path, plan: dict):
        validate_plan(plan)
        self.root = pathlib.Path(root).resolve()
        self.plan = plan
        self.plan_bytes = canonical_bytes(plan)
        self.plan_sha = sha256(self.plan_bytes)
        self.engines = [engine["id"] for engine in plan["engines"]]
        self.years = {y["year"]: y for y in plan["years"]}
        self.root.mkdir(parents=True, exist_ok=True)
        self.lock_file = (self.root / "OWNED_SUPERVISOR.lock").open("a+b")
        try:
            self._acquire_lock()
            self._init_plan_file()
            (self.root / "chunks").mkdir(exist_ok=True)
            (self.root / "evidence").mkdir(exist_ok=True)
            self.db = sqlite3.connect(str(self.root / "ledger.sqlite"), timeout=15, isolation_level=None)
            self.db.execute("PRAGMA journal_mode=WAL")
            self.db.execute("PRAGMA synchronous=FULL")
            self.db.execute("PRAGMA foreign_keys=ON")
            self.db.execute("PRAGMA busy_timeout=15000")
            self._init_schema()
        except BaseException:
            self._release_lock()
            raise

    def _acquire_lock(self):
        self.lock_file.seek(0)
        if os.name == "nt":
            import msvcrt
            self.lock_file.write(b"0") if self.lock_file.read(1) == b"" else None
            self.lock_file.flush()
            self.lock_file.seek(0)
            try:
                msvcrt.locking(self.lock_file.fileno(), msvcrt.LK_NBLCK, 1)
            except OSError as exc:
                raise RuntimeError("another soak supervisor owns this folder") from exc
        else:
            import fcntl
            try:
                fcntl.flock(self.lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError as exc:
                raise RuntimeError("another soak supervisor owns this folder") from exc
        self.locked = True

    def _release_lock(self):
        if getattr(self, "locked", False):
            try:
                if os.name == "nt":
                    import msvcrt
                    self.lock_file.seek(0)
                    msvcrt.locking(self.lock_file.fileno(), msvcrt.LK_UNLCK, 1)
                else:
                    import fcntl
                    fcntl.flock(self.lock_file.fileno(), fcntl.LOCK_UN)
            finally:
                self.locked = False
        self.lock_file.close()

    def close(self):
        if hasattr(self, "db"):
            self.db.close()
            del self.db
        if not self.lock_file.closed:
            self._release_lock()

    def __enter__(self): return self
    def __exit__(self, *_): self.close()

    def _init_plan_file(self):
        path = self.root / "run-plan.json"
        if path.exists():
            if path.read_bytes() != self.plan_bytes:
                raise PlanMismatch("run plan differs from immutable plan pinned on disk")
            return
        tmp = path.with_suffix(".json.part")
        if tmp.exists():
            if tmp.read_bytes() != self.plan_bytes:
                raise PlanMismatch("uncommitted run-plan different from requested plan")
        else:
            self._durable_write(tmp, self.plan_bytes)
        os.replace(tmp, path)
        self._sync_dir(path.parent)

    def _init_schema(self):
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS chunks(
              engine TEXT NOT NULL, year TEXT NOT NULL, ordinal INTEGER NOT NULL,
              first_day TEXT NOT NULL, last_day TEXT NOT NULL,
              file_sha256 TEXT NOT NULL, bytes INTEGER NOT NULL,
              PRIMARY KEY(engine,year,ordinal));
            CREATE TABLE IF NOT EXISTS comparisons(
              year TEXT NOT NULL, candidate TEXT NOT NULL,
              verified_days INTEGER NOT NULL, stream_sha256 TEXT NOT NULL,
              PRIMARY KEY(year,candidate));
            CREATE TABLE IF NOT EXISTS incident(
              id INTEGER PRIMARY KEY CHECK(id=1), kind TEXT NOT NULL,
              evidence_json TEXT NOT NULL);
        """)
        row = self.db.execute("SELECT value FROM meta WHERE key='plan_sha256'").fetchone()
        if row is not None and row[0] != self.plan_sha:
            raise PlanMismatch("database plan digest mismatch")
        self.db.execute("INSERT OR IGNORE INTO meta(key,value) VALUES('plan_sha256',?)", (self.plan_sha,))

    @staticmethod
    def _durable_write(path: pathlib.Path, contents: bytes):
        with path.open("xb") as f:
            f.write(contents)
            f.flush()
            os.fsync(f.fileno())

    @staticmethod
    def _sync_dir(path: pathlib.Path):
        if os.name != "nt":
            fd = os.open(path, os.O_RDONLY)
            try: os.fsync(fd)
            finally: os.close(fd)

    def _case(self, year: str) -> YearCase:
        y = self.years[year]
        return YearCase(self.plan["calculation_day"], year, y["first_target_day"],
                        y["last_target_day"], y["boundary_evidence_sha256"])

    def _chunk(self, engine: str, year: str, ordinal: int) -> Chunk:
        if engine not in self.engines or year not in self.years or type(ordinal) is not int or ordinal < 0:
            raise ValueError("unplanned chunk")
        y = self.years[year]
        first, last = int(y["first_target_day"]), int(y["last_target_day"])
        start = first + ordinal * self.plan["chunk_days"]
        if start > last:
            raise ValueError("chunk ordinal past end of year")
        end = min(start + self.plan["chunk_days"] - 1, last)
        return Chunk(engine, year, str(start), str(end), ordinal)

    def _chunk_path(self, chunk: Chunk) -> pathlib.Path:
        key = canonical_bytes([self.plan_sha, chunk.engine_id, chunk.year, chunk.ordinal,
                               chunk.first_day, chunk.last_day])
        return self.root / "chunks" / (sha256(key) + ".jsonl")

    def expected_chunks(self, engine: str, year: str) -> list[Chunk]:
        y = self.years[year]
        count = int(y["last_target_day"]) - int(y["first_target_day"]) + 1
        return [self._chunk(engine, year, i) for i in range((count+self.plan["chunk_days"]-1)//self.plan["chunk_days"])]

    def _parse_chunk(self, chunk: Chunk, content: bytes):
        try:
            decoded = content.decode("utf-8", errors="strict")
        except UnicodeError as exc:
            raise ValueError("chunk must be exact UTF-8") from exc
        if not decoded.endswith("\n"):
            raise ValueError("chunk lacks final newline; may be truncated")
        lines = decoded.splitlines(keepends=True)
        expected = int(chunk.last_day) - int(chunk.first_day) + 1
        if len(lines) != expected:
            raise ValueError("incomplete or extra days in chunk")
        normalized = []
        case = self._case(chunk.year)
        for i, line in enumerate(lines):
            parsed = json.loads(line, object_pairs_hook=_duplicates_error, parse_constant=lambda v: (_ for _ in ()).throw(ValueError("non-finite JSON number: "+v)))
            if not isinstance(parsed, dict) or set(parsed) != set(KEYS):
                raise ValueError("unexpected/missing JSON field")
            day = parse_line(line, i+1, case, int(chunk.first_day)+i)
            normalized.append(day)
        return normalized

    def incident(self):
        row = self.db.execute("SELECT kind,evidence_json FROM incident WHERE id=1").fetchone()
        return {"kind": row[0], "evidence": json.loads(row[1])} if row else None

    def _record_incident(self, kind: str, evidence: dict):
        self.db.execute("INSERT OR IGNORE INTO incident(id,kind,evidence_json) VALUES(1,?,?)",
                        (kind, canonical_bytes(evidence).decode("utf-8")))

    def _require_active(self):
        if self.incident() is not None:
            raise Halted("first incident is preserved; operator review required before new dispatch")

    def _chunk_registered(self, chunk: Chunk):
        return self.db.execute("SELECT file_sha256,bytes FROM chunks WHERE engine=? AND year=? AND ordinal=?",
                               (chunk.engine_id,chunk.year,chunk.ordinal)).fetchone()

    def _full_engine(self, engine: str, year: str) -> bool:
        for chunk in self.expected_chunks(engine, year):
            if self._chunk_registered(chunk) is None:
                return False
        return True

    def _check_engine_order(self, chunk: Chunk):
        ix = self.engines.index(chunk.engine_id)
        if ix and not self._full_engine(self.engines[ix-1],chunk.year):
            raise ValueError("complete previous engine year before computing this engine")

    def commit_chunk(self, engine: str, year: str, ordinal: int, content: bytes,
                     *, inject_crash_at: str | None = None):
        """Commit one exact chunk; crash injection is test-only, never use on real workloads.

        Crash stages: after_payload_fsync / after_payload_publish /
        after_db_commit. SQLite + the deterministic blob allow replay without
        re-computing a complete durable chunk.
        """
        self._require_active()
        chunk = self._chunk(engine, year, ordinal)
        self._check_engine_order(chunk)
        if not isinstance(content, bytes):
            raise TypeError("content must be raw UTF-8 bytes")
        parsed = self._parse_chunk(chunk, content)
        checksum = sha256(content)
        prior = self._chunk_registered(chunk)
        if prior is not None:
            if prior != (checksum,len(content)):
                self.db.execute("BEGIN IMMEDIATE")
                try:
                    self._record_incident("CONFLICTING_REPLAY", {"chunk":chunk.__dict__,"old":prior,"new_sha256":checksum})
                    self.db.execute("COMMIT")
                except BaseException:
                    self.db.execute("ROLLBACK")
                    raise
                raise Halted("conflicting replay; preserved first incident")
            self._check_registered_file(chunk, prior)
            return "ALREADY_COMMITTED"
        path = self._chunk_path(chunk)
        temp = path.with_name(path.name + ".part")
        if not path.exists():
            if temp.exists():
                if temp.read_bytes() != content:
                    raise ValueError("uncommitted part file conflicts; manual recovery required")
            else:
                self._durable_write(temp, content)
            if inject_crash_at == "after_payload_fsync": os._exit(73)
            os.replace(temp, path)
            self._sync_dir(path.parent)
        else:
            if path.read_bytes() != content:
                raise ValueError("pre-existing unindexed payload conflicts with current chunk")
        if inject_crash_at == "after_payload_publish": os._exit(74)
        self._commit_validated(chunk,checksum,len(content),parsed)
        if inject_crash_at == "after_db_commit": os._exit(75)
        return "COMMITTED"

    def _commit_validated(self, chunk: Chunk, checksum: str, length: int, parsed):
        self.db.execute("BEGIN IMMEDIATE")
        try:
            self._require_active()
            self._check_engine_order(chunk)
            existing = self._chunk_registered(chunk)
            if existing is not None:
                if existing != (checksum,length):
                    raise ValueError("unreadable concurrent chunk version")
                self.db.execute("COMMIT")
                return
            self.db.execute("INSERT INTO chunks(engine,year,ordinal,first_day,last_day,file_sha256,bytes) VALUES(?,?,?,?,?,?,?)",
                            (chunk.engine_id,chunk.year,chunk.ordinal,chunk.first_day,chunk.last_day,checksum,length))
            ix = self.engines.index(chunk.engine_id)
            if ix:
                reference = self.engines[0]
                baseline = self._chunk(reference,chunk.year,chunk.ordinal)
                ref_row = self._chunk_registered(baseline)
                if ref_row is None:
                    raise ValueError("baseline chunk missing")
                ref_data = self._chunk_path(baseline).read_bytes()
                if sha256(ref_data) != ref_row[0] or len(ref_data) != ref_row[1]:
                    raise ValueError("baseline chunk is corrupt")
                originals = self._parse_chunk(baseline,ref_data)
                for offset,(a,b) in enumerate(zip(originals,parsed)):
                    if a.normalized != b.normalized:
                        self._record_incident("FIRST_DIFFERENCE", {
                          "year":chunk.year, "calculation_day":self.plan["calculation_day"],
                          "target_day":b.t,"first_different_field":next((i for i,(u,v) in enumerate(zip(a.normalized,b.normalized)) if u!=v),None),
                          "baseline_engine":reference,"candidate_engine":chunk.engine_id,
                          "baseline_row":{"canonical":a.normalized,"names_raw":a.raw_names,"native_sha256":a.source_raw_sha256},
                          "candidate_row":{"canonical":b.normalized,"names_raw":b.raw_names,"native_sha256":b.source_raw_sha256},
                          "baseline_chunk_sha256":ref_row[0],"candidate_chunk_sha256":checksum,
                          "year_boundary_sha256":self._case(chunk.year).boundary_evidence_sha256,
                          "plan_sha256":self.plan_sha,
                        })
                        break
                if self.incident() is None and self._full_engine(chunk.engine_id, chunk.year):
                    # All ordered chunks are committed; rebuild the complete
                    # canonical digest and verify exact whole-year cardinality.
                    h = hashlib.sha256()
                    n = 0
                    for part in self.expected_chunks(chunk.engine_id, chunk.year):
                        payload = self._chunk_path(part).read_bytes()
                        receipt = self._chunk_registered(part)
                        if receipt is None or sha256(payload) != receipt[0] or len(payload) != receipt[1]:
                            raise ValueError("missing/corrupt chunk before year PASS")
                        for day in self._parse_chunk(part,payload):
                            h.update(canonical_bytes(day.normalized)+b"\n")
                            n += 1
                    yearlen=int(self.years[chunk.year]["last_target_day"])-int(self.years[chunk.year]["first_target_day"])+1
                    if n != yearlen:
                        raise ValueError("year count mismatch")
                    self.db.execute("INSERT OR IGNORE INTO comparisons(year,candidate,verified_days,stream_sha256) VALUES(?,?,?,?)",
                                    (chunk.year,chunk.engine_id,n,h.hexdigest()))
            self.db.execute("COMMIT")
        except BaseException:
            self.db.execute("ROLLBACK")
            raise

    def _check_registered_file(self, chunk: Chunk, receipt):
        path=self._chunk_path(chunk)
        try:
            data=path.read_bytes()
        except OSError as exc:
            raise ValueError("committed chunk is missing") from exc
        if sha256(data)!=receipt[0] or len(data)!=receipt[1]:
            raise ValueError("committed chunk failed integrity check")
        self._parse_chunk(chunk,data)

    def verify_and_recover(self) -> dict:
        """Audit all committed data, re-adopt full orphan `.part` / final files.

        Never deletes prior evidence; invalid items fail closed. Cannot adopt a
        running child or resume within an adapter's *single* uncheckpointed call.
        """
        already=0
        adopted=0
        staged=0
        # Files are traversed by year and engine order, preserving the engine gate.
        for year in self.years:
            for engine in self.engines:
                for chunk in self.expected_chunks(engine, year):
                    receipt=self._chunk_registered(chunk)
                    path=self._chunk_path(chunk)
                    temp=path.with_name(path.name+".part")
                    if receipt:
                        self._check_registered_file(chunk,receipt)
                        already+=1
                        if temp.exists():
                            raise ValueError("ambiguous committed + .part file; preserve for investigation")
                        continue
                    # An interrupted write may be complete but not yet indexed.
                    if not path.exists() and temp.exists():
                        data=temp.read_bytes()
                        parsed=self._parse_chunk(chunk,data)
                        os.replace(temp,path)
                        self._sync_dir(path.parent)
                        staged+=1
                    elif path.exists():
                        data=path.read_bytes()
                        parsed=self._parse_chunk(chunk,data)
                    else:
                        continue
                    self._check_engine_order(chunk)
                    if self.incident() is not None:
                        break
                    self._commit_validated(chunk,sha256(data),len(data),parsed)
                    adopted+=1
        return {"verified_existing_chunks":already,"recovered_chunks":adopted,
                "recovered_staged_files":staged,"incident":self.incident(),
                "progress":self.progress()}

    def pending_jobs(self) -> list[Chunk]:
        self._require_active()
        result=[]
        for year in self.years:
            for engine in self.engines:
                if not self._full_engine(engine,year):
                    if self.engines.index(engine)>0 and not self._full_engine(self.engines[self.engines.index(engine)-1],year):
                        break
                    result.extend(c for c in self.expected_chunks(engine,year) if self._chunk_registered(c) is None)
                    break
        return result

    def progress(self) -> dict:
        rows=self.db.execute("SELECT year,candidate,verified_days FROM comparisons").fetchall()
        successful=len(rows)
        days=sum(row[2] for row in rows)
        known={(year,candidate) for year,candidate,_ in rows}
        fully_verified=[]
        for year in self.years:
            if all((year,e) in known for e in self.engines[1:]):
                fully_verified.append(year)
        prefix=0
        for year in self.years:
            if year not in fully_verified: break
            prefix+=1
        committed=self.db.execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
        return {"verified_comparisons_completed":successful,
                "verified_day_pair_comparisons":days,
                "fully_verified_years":len(fully_verified),
                "contiguous_verified_years":prefix,
                "committed_chunks":committed,
                "incident_present":self.incident() is not None,
                "all_verified":len(fully_verified)==len(self.years) and self.incident() is None}
