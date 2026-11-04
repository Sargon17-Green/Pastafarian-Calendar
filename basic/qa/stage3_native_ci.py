#!/usr/bin/env python3
"""Stage3 isolated UNO runner. Does not touch old Windows workspaces or user files."""
import argparse
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import traceback

import uno

SOURCE_TEST_RESULT = Path("/tmp/pastafari_basic_stage2_discovery01_test_results.txt")
EXPECTED_CORRECTED = {
    "DISCOVERY_01_M", "DISCOVERY_01_2M",
    "DISCOVERY_01_3M", "DISCOVERY_01_M_PLUS_1",
}


def allocated_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def connect_context(port, process, timeout=45):
    local = uno.getComponentContext()
    resolver = local.ServiceManager.createInstanceWithContext(
        "com.sun.star.bridge.UnoUrlResolver", local
    )
    deadline = time.monotonic() + timeout
    last_error = None
    while time.monotonic() < deadline:
        try:
            return resolver.resolve(
                "uno:socket,host=127.0.0.1,port=%d;urp;StarOffice.ComponentContext" % port
            )
        except Exception as exc:
            last_error = exc
            time.sleep(0.3)
    raise RuntimeError("UNO connection timed out: %r; launcher rc=%s" % (
        last_error, process.poll()
    ))


def office_session(profile, log_path):
    port = allocated_port()
    cmd = [
        "libreoffice", "-env:UserInstallation=" + profile.resolve().as_uri(),
        "--headless", "--nodefault", "--norestore", "--nofirststartwizard",
        "--accept=socket,host=127.0.0.1,port=%d;urp;StarOffice.ServiceManager" % port,
    ]
    with log_path.open("ab") as out:
        proc = subprocess.Popen(cmd, stdout=out, stderr=subprocess.STDOUT)
    try:
        context = connect_context(port, proc)
        return proc, context
    except Exception:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=6)
            except subprocess.TimeoutExpired:
                proc.kill()
        raise


def stop_office(proc, context):
    try:
        desktop = context.ServiceManager.createInstanceWithContext(
            "com.sun.star.frame.Desktop", context
        )
        desktop.terminate()
    except Exception:
        pass
    try:
        proc.wait(timeout=12)
    except subprocess.TimeoutExpired:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)


def execute_tests(context):
    factory = context.ServiceManager.createInstanceWithContext(
        "com.sun.star.script.provider.MasterScriptProviderFactory", context
    )
    errors = []
    for provider_context in ("", "user"):
        try:
            provider = factory.createScriptProvider(provider_context)
        except Exception as exc:
            errors.append("provider %r: %s" % (provider_context, exc))
            continue
        for location in ("application", "user"):
            url = (
                "vnd.sun.star.script:Standard.Tests.Main"
                "?language=Basic&location=" + location
            )
            try:
                script = provider.getScript(url)
                script.invoke((), (), ())
                if SOURCE_TEST_RESULT.is_file():
                    return url
                errors.append("%s invoked but result absent" % url)
            except Exception as exc:
                errors.append("%s: %s" % (url, exc))
    raise RuntimeError("No successful native macro: " + " | ".join(errors))


def validate_native(raw):
    lines = raw.splitlines()
    passed = [x[:-5] for x in lines if x.endswith("=PASS") and not x.startswith("OVERALL=")]
    failed = [x[:-5] for x in lines if x.endswith("=FAIL") and not x.startswith("OVERALL=")]
    if len(passed) != 148 or len(set(passed)) != 148 or failed:
        raise AssertionError("148 unique PASS and zero FAIL required; PASS=%d unique=%d FAIL=%s" % (
            len(passed), len(set(passed)), failed
        ))
    if "OVERALL=PASS" not in lines or any(x.startswith("OVERALL=ERROR") for x in lines):
        raise AssertionError("OVERALL=PASS missing or fatal Basic error")
    if not EXPECTED_CORRECTED.issubset(set(passed)):
        raise AssertionError("Corrected DISCOVERY01 checks not green")
    for label in ("CATALOG_CUTLET_8", "PRODUCTION_STAGE", "SAVE_M", "SAVE_M_PLUS_1"):
        if label not in passed:
            raise AssertionError("Baseline control missing: " + label)
    return {"stage": 3, "native": "PASS", "individual_checks": 148,
            "unique_checks": 148, "failures": 0, "corrected": sorted(EXPECTED_CORRECTED)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--basic-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    source = args.basic_dir.resolve()
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    (output / "status.txt").write_text("STARTED\n", encoding="utf-8")
    try:
        if not (source / "Standard" / "Tests.xba").is_file():
            raise FileNotFoundError("Pinned Basic module sources missing")
        if SOURCE_TEST_RESULT.exists():
            # GitHub ephemeral runner only. Never delete data on a user's PC.
            if "GITHUB_ACTIONS" != os.environ.get("GITHUB_ACTIONS"):
                raise RuntimeError("Refusing non-ephemeral /tmp result cleanup")
            SOURCE_TEST_RESULT.unlink()
        with tempfile.TemporaryDirectory(prefix="pc-basic-punjabi-stage3-") as tmp:
            profile = Path(tmp) / "isolated-lo-profile"
            proc, context = office_session(profile, output / "lo-startup.log")
            stop_office(proc, context)
            target = profile / "user" / "basic"
            if target.exists():
                shutil.rmtree(target)  # Only the newly-created profile tree.
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(source, target)
            proc, context = office_session(profile, output / "lo-startup.log")
            try:
                script_url = execute_tests(context)
            finally:
                stop_office(proc, context)
            if not SOURCE_TEST_RESULT.exists():
                raise RuntimeError("Native macro did not produce test output")
            raw = SOURCE_TEST_RESULT.read_text(encoding="utf-8")
            (output / "native_tests.txt").write_text(raw, encoding="utf-8")
            result = validate_native(raw)
            result["script_url"] = script_url
            (output / "assertions.json").write_text(
                json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            (output / "status.txt").write_text("PASS\n", encoding="utf-8")
            print(json.dumps(result, sort_keys=True))
        return 0
    except Exception:
        (output / "status.txt").write_text("FAILED\n", encoding="utf-8")
        (output / "error.txt").write_text(traceback.format_exc(), encoding="utf-8")
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
