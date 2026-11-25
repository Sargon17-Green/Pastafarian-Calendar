"""Post55 prospective byte-binding QA. No CI authentication or OS attestation.
External pins MUST come from an independently authenticated provider readback.
Offline success is conditional on those pins; synthetic success is not CI success.
Run python soak/post55_jar_byte_receipt.py --self-test.
"""
import argparse
import hashlib
import io
import json
import re
import stat
import time
import unittest
import warnings
import zipfile
from pathlib import Path, PurePosixPath

MIB = 1024 * 1024
JAR_LIMIT = 64 * MIB
EVIDENCE_LIMIT = 8 * MIB
JSON_LIMIT = 256 * 1024
OUTER_LIMIT = JAR_LIMIT + EVIDENCE_LIMIT + JSON_LIMIT + MIB
IDENTITY = ("repository", "branch", "source_sha", "run_id", "attempt",
            "job_id", "workflow_path", "workflow_blob_sha",
            "evidence_artifact_id", "receipt_artifact_id")
MEMBERS = {"production.jar": JAR_LIMIT, "receipt.json": JSON_LIMIT,
           "worker-evidence.zip": EVIDENCE_LIMIT}

class Rejected(ValueError):
    pass

def require(condition, code):
    if not condition:
        raise Rejected(code)

def digest(data):
    return hashlib.sha256(data).hexdigest()

def hex_digest(value, length=64):
    return isinstance(value, str) and re.fullmatch("[0-9a-f]{%d}" % length, value) is not None

def json_bytes(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode()

def pairs(items):
    result = {}
    for key, value in items:
        require(key not in result, "DUPLICATE_JSON_KEY")
        result[key] = value
    return result

def parse_json(data):
    require(len(data) <= JSON_LIMIT, "OVERSIZE")
    try:
        value = json.loads(data.decode("utf-8"), object_pairs_hook=pairs,
                           parse_constant=lambda _: (_ for _ in ()).throw(Rejected("BAD_JSON")))
    except (UnicodeError, json.JSONDecodeError, RecursionError) as exc:
        raise Rejected("BAD_JSON") from exc
    require(isinstance(value, dict), "BAD_SCHEMA")
    return value

def safe_path(name):
    return (isinstance(name, str) and bool(name) and "\\" not in name
            and ":" not in name and "\x00" not in name
            and not name.startswith("/") and
            all(p not in ("", ".", "..") for p in name.split("/")))

def read_members(data, limits, deadline):
    require(time.monotonic() < deadline, "TIMEOUT")
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            infos = archive.infolist()
            require(len(infos) <= 128, "OVERSIZE")
            names = [i.filename for i in infos]
            require(len(set(names)) == len(names), "DUPLICATE_MEMBER")
            for info in infos:
                kind = stat.S_IFMT(info.external_attr >> 16)
                require(safe_path(info.filename) and info.orig_filename == info.filename
                        and kind in (0, stat.S_IFREG) and not info.is_dir(),
                        "UNSAFE_MEMBER")
            require(set(names) == set(limits), "MEMBER_SET")
            result = {}
            for info in infos:
                limit = limits[info.filename]
                require(0 < info.file_size <= limit, "OVERSIZE")
                require(info.compress_type in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED)
                        and not info.flag_bits & 1, "UNSUPPORTED_ZIP")
                chunks, count = [], 0
                with archive.open(info) as member:
                    while True:
                        require(time.monotonic() < deadline, "TIMEOUT")
                        chunk = member.read(65536)
                        if not chunk:
                            break
                        count += len(chunk)
                        require(count <= limit, "OVERSIZE")
                        chunks.append(chunk)
                require(count == info.file_size, "SIZE_MISMATCH")
                result[info.filename] = b"".join(chunks)
            return result
    except (zipfile.BadZipFile, RuntimeError, NotImplementedError, OSError) as exc:
        raise Rejected("BAD_ZIP") from exc

def source_manifest(value):
    require(isinstance(value, list) and 0 < len(value) <= 128, "BUILD_DRIFT")
    paths = []
    for item in value:
        require(isinstance(item, dict) and set(item) == {"path", "sha256"}
                and safe_path(item["path"]) and hex_digest(item["sha256"]), "BUILD_DRIFT")
        paths.append(item["path"])
    require(paths == sorted(set(paths)), "BUILD_DRIFT")

def validate(bundle, pins):
    """pins are supplied independently, never read from bundle.
    This is an offline parser, not a GitHub API client.
    """
    deadline = time.monotonic() + 120
    require(len(bundle) <= OUTER_LIMIT, "OVERSIZE")
    require(isinstance(pins, dict) and pins.get("schema") == "external-readback-v1",
            "BAD_SCHEMA")
    require(pins.get("run_status") == pins.get("job_status") == "completed"
            and pins.get("run_conclusion") == pins.get("job_conclusion") == "success",
            "PROVIDER_STATUS")
    require(hex_digest(pins.get("receipt_archive_sha256"))
            and digest(bundle) == pins["receipt_archive_sha256"], "PROVIDER_DIGEST")
    outer = read_members(bundle, MEMBERS, deadline)
    receipt = parse_json(outer["receipt.json"])
    require(receipt.get("schema") == "jar-byte-receipt-v1", "BAD_SCHEMA")
    for key in IDENTITY:
        require(key in pins and key in receipt and type(pins[key]) is type(receipt[key])
                and pins[key] == receipt[key], "IDENTITY")
    require(receipt["repository"] == "Sargon17-Green/Pastafarian-Calendar"
            and receipt["branch"] == "Kotlin+Cymraeg"
            and hex_digest(receipt["source_sha"], 40)
            and hex_digest(receipt["workflow_blob_sha"], 40)
            and safe_path(receipt["workflow_path"])
            and all(type(receipt[k]) is int and receipt[k] > 0 for k in
                    ("run_id", "attempt", "job_id", "evidence_artifact_id", "receipt_artifact_id"))
            and receipt["evidence_artifact_id"] != receipt["receipt_artifact_id"], "IDENTITY")
    evidence = outer["worker-evidence.zip"]
    require(hex_digest(pins.get("evidence_archive_sha256")) and
            digest(evidence) == pins["evidence_archive_sha256"], "EVIDENCE_DIGEST")
    jar = outer["production.jar"]
    h = hashlib.sha256()
    for offset in range(0, len(jar), 65536):
        require(time.monotonic() < deadline, "TIMEOUT")
        h.update(jar[offset:offset + 65536])
    actual = h.hexdigest()
    require(type(receipt.get("jar_size")) is int and receipt["jar_size"] == len(jar),
            "JAR_SIZE")
    require(receipt.get("jar_pre_sha256") == receipt.get("jar_post_sha256"), "JAR_DRIFT")
    require(actual == receipt.get("jar_pre_sha256"), "JAR_DIGEST")
    workers = read_members(evidence, {"worker-%d.json" % i: JSON_LIMIT for i in range(1, 4)}, deadline)
    for i in range(1, 4):
        worker = parse_json(workers["worker-%d.json" % i])
        require(worker.get("schema") == "jar-worker-claim-v1"
                and type(worker.get("worker")) is int and worker["worker"] == i,
                "WORKER_SCHEMA")
        require(worker.get("jar_sha256") == actual, "WORKER_DIGEST")
    for key in ("compiler_sha256", "compiler_version", "compile_argv", "sources"):
        require(key in pins and key in receipt and pins[key] == receipt[key], "BUILD_DRIFT")
    require(hex_digest(receipt["compiler_sha256"])
            and isinstance(receipt["compiler_version"], str) and bool(receipt["compiler_version"])
            and isinstance(receipt["compile_argv"], list) and bool(receipt["compile_argv"])
            and all(isinstance(a, str) and a for a in receipt["compile_argv"]), "BUILD_DRIFT")
    source_manifest(receipt["sources"])
    return {"BYTE_BINDING": "PASS_OFFLINE_CONDITIONAL_ON_EXTERNAL_PINS",
            "CI_PROCESS_OBSERVATION": "NOT_ASSESSED", "OS_ATTESTATION": False,
            "jar_sha256": actual, "jar_size": len(jar),
            "CI_AUTHENTICATION_PERFORMED": False}

def historical():
    return {"BYTE_BINDING": "NOT_ASSESSED", "CI_PROCESS_OBSERVATION": "NOT_ASSESSED",
            "OS_ATTESTATION": False, "CI_AUTHENTICATION_PERFORMED": False}

def pack(items):
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for name, value in items:
            z.writestr(name, value)
    return out.getvalue()

def fixture(jar=b"synthetic jar bytes", receipt_patch=None, worker_patch=None,
            extra=None, omit=None, pin_patch=None):
    d = digest(jar)
    r = dict(schema="jar-byte-receipt-v1", repository="Sargon17-Green/Pastafarian-Calendar",
             branch="Kotlin+Cymraeg", source_sha="a"*40, run_id=10, attempt=1, job_id=11,
             workflow_path=".github/workflows/qa.yml", workflow_blob_sha="b"*40,
             evidence_artifact_id=12, receipt_artifact_id=13, jar_size=len(jar),
             jar_pre_sha256=d, jar_post_sha256=d, compiler_sha256="c"*64,
             compiler_version="synthetic", compile_argv=["compiler", "source.kt"],
             sources=[{"path":"source.kt", "sha256":"d"*64}])
    p = {k:r[k] for k in IDENTITY + ("compiler_sha256","compiler_version","compile_argv","sources")}
    r.update(receipt_patch or {})
    evidence = pack([("worker-%d.json" % i, json_bytes(dict(schema="jar-worker-claim-v1",
                     worker=i, jar_sha256=(worker_patch or {}).get(i, d)))) for i in range(1,4)])
    members = [("production.jar", jar), ("receipt.json", json_bytes(r)),
               ("worker-evidence.zip", evidence)]
    members = [m for m in members if m[0] != omit] + (extra or [])
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", UserWarning)
        bundle = pack(members)
    p.update(schema="external-readback-v1", run_status="completed", job_status="completed",
             run_conclusion="success", job_conclusion="success",
             evidence_archive_sha256=digest(evidence), receipt_archive_sha256=digest(bundle))
    p.update(pin_patch or {})
    return bundle, p

class Controls(unittest.TestCase):
    def reject(self, code, args):
        with self.assertRaisesRegex(Rejected, "^" + code + "$"):
            validate(*args)

    def test_positive(self):
        self.assertEqual(validate(*fixture())["BYTE_BINDING"],
                         "PASS_OFFLINE_CONDITIONAL_ON_EXTERNAL_PINS")

    def test_A1_byte_substitution(self):
        d = digest(b"synthetic jar bytes")
        self.reject("JAR_DIGEST", fixture(jar=b"synthetic jar byteS",
                    receipt_patch={"jar_pre_sha256":d,"jar_post_sha256":d}))

    def test_A2_coherent_resign(self):
        _, p = fixture()
        b, _ = fixture(jar=b"replacement bytes")
        self.reject("PROVIDER_DIGEST", (b,p))

    def test_A3_worker_mismatch(self):
        self.reject("WORKER_DIGEST", fixture(worker_patch={2:"e"*64}))

    def test_A4_identity(self):
        for key in IDENTITY:
            with self.subTest(key=key):
                self.reject("IDENTITY", fixture(receipt_patch={key:"swapped"}))

    def test_A5_drift(self):
        self.reject("JAR_DRIFT", fixture(receipt_patch={"jar_post_sha256":"e"*64}))

    def test_A6_members(self):
        self.reject("MEMBER_SET", fixture(omit="production.jar"))
        self.reject("DUPLICATE_MEMBER", fixture(extra=[("receipt.json",b"x")]))
        self.reject("UNSAFE_MEMBER", fixture(extra=[("../x",b"x")]))
        self.reject("OVERSIZE", fixture(omit="receipt.json",
                    extra=[("receipt.json",b"x"*(JSON_LIMIT+1))]))
        self.reject("DUPLICATE_JSON_KEY", fixture(omit="receipt.json",
                    extra=[("receipt.json",b'{"schema":1,"schema":2}')]))

    def test_A7_build_drift(self):
        self.reject("BUILD_DRIFT", fixture(receipt_patch={"compiler_sha256":"f"*64}))
        self.reject("BUILD_DRIFT", fixture(receipt_patch={"sources":[]}))

    def test_historical(self):
        self.assertEqual(historical()["BYTE_BINDING"], "NOT_ASSESSED")
        self.assertFalse(historical()["OS_ATTESTATION"])

def read_bounded(path, limit):
    with Path(path).open("rb") as f:
        data = f.read(limit+1)
    require(len(data) <= limit, "OVERSIZE")
    return data

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--historical", action="store_true")
    parser.add_argument("--bundle")
    parser.add_argument("--external-pins")
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(Controls)
        return 0 if unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful() else 1
    if args.historical and not args.bundle and not args.external_pins:
        print(json.dumps(historical(), sort_keys=True))
        return 0
    if not args.bundle or not args.external_pins or args.historical:
        parser.error("provide --bundle and --external-pins, or --historical, or --self-test")
    try:
        result = validate(read_bounded(args.bundle, OUTER_LIMIT),
                          parse_json(read_bounded(args.external_pins, JSON_LIMIT)))
        print(json.dumps(result, sort_keys=True))
        return 0
    except (Rejected, OSError) as exc:
        print(json.dumps({"BYTE_BINDING":"REJECTED","error":str(exc),
                          "CI_PROCESS_OBSERVATION":"NOT_ASSESSED","OS_ATTESTATION":False}))
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
