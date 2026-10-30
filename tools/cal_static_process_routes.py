#!/usr/bin/env python3
"""Source-only, pinned audit of CAL process launch/stop routes.

Evidence is restricted to explicit statements in six hash-verified Plain
English source files. This is NOT an exhaustive call graph, runtime trace,
executable safety assessment, or permission to launch CAL.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import json
from pathlib import Path
import re
import sys

import cal_source_provenance as provenance

ROUTINE_HEADER = re.compile(r"^To\s+", re.IGNORECASE)

ROUTES = {
    "desktop_editor_run": (
        "the desktop", "To handle run:", (
            'If the current tab\'s mode is "finder", handle run given the current tab\'s node; exit.',
            'If the current tab\'s mode is not "editor", cluck; exit.',
            "Handle save all.",
            "Find a directory to compile.",
            "Compile the directory.",
            "If the compiler's abort flag is set, handle compile or list or run error; exit.",
            'Show status "Running...".',
            "Start the current process given the compiler's exe path.",
        )
    ),
    "finder_exe_run": (
        "the finder", "To handle run given a node:", (
            "Put the node's first selected nodette into a nodette.",
            'If the nodette\'s extension is not ".exe", show error',
            'Show status "Running...".',
            "Start the current process given the nodette's path.",
        )
    ),
    "desktop_stop": (
        "the desktop", "To handle stop:", (
            "If the current process is 0, cluck; exit.",
            'Show status "Stopping...".',
            "Stop the current process.",
        )
    ),
    "noodle_process_start": (
        "the noodle", "To start a process given a path:", (
            "If the process is not 0,",
            "Put a startupinfo's magnitude into the startupinfo's cb.",
            "Extract a directory from the path.",
            'Call "kernel32.dll" "CreateProcessA" with the path\'s first',
            "Put the processinfo's hprocess into the process.",
            "Point a pointer to routine wait for a process pointer.",
            'Call "kernel32.dll" "CreateThread" with',
        )
    ),
    "noodle_process_stop": (
        "the noodle", "To stop a process:", (
            "If the process is 0, exit.",
            'Call "kernel32.dll" "TerminateProcess" with the process and 0.',
            "Put 0 into the process.",
        )
    ),
    "noodle_process_wait": (
        "the noodle", "To compatibly wait for a process pointer:", (
            'Call "kernel32.dll" "WaitForSingleObject"',
            'Call "kernel32.dll" "CloseHandle" with the process pointer\'s target.',
            "Put 0 into the process pointer's target.",
        )
    ),
}

ENTRY_MARKERS = {
    "desktop_run_menu_finder": ("the desktop", 'If the current tab\'s mode is "finder", add "Run" and "R" and "handle run" to the submenu.'),
    "desktop_run_menu_editor": ("the desktop", 'If the current tab\'s mode is "editor", add "Run" and "R" and "handle run" to the submenu.'),
    "desktop_stop_menu_finder": ("the desktop", 'If the current tab\'s mode is "finder", add "Stop" and "handle stop" to the submenu.'),
    "desktop_stop_menu_editor": ("the desktop", 'If the current tab\'s mode is "editor", add "Stop" and "handle stop" to the submenu.'),
    "desktop_dispatch_run": ("the desktop", 'If the command\'s handler is "handle run", handle run; exit.'),
    "desktop_dispatch_stop": ("the desktop", 'If the command\'s handler is "handle stop", handle stop; exit.'),
    "desktop_key_run_finder": ("the desktop", 'If the event\'s key is the r-key and the current tab\'s mode is "finder", handle run; exit.'),
    "desktop_key_run_editor": ("the desktop", 'If the event\'s key is the r-key and the current tab\'s mode is "editor", handle run; exit.'),
}

EXPECTED_SITE_COUNTS = {
    "start_current_process_statement": 2,
    "stop_current_process_statement": 1,
    "CreateProcessA_quoted_api": 1,
    "TerminateProcess_quoted_api": 1,
    "CreateThread_quoted_api": 1,
    "WaitForSingleObject_quoted_api": 1,
}


def active_lines(data: bytes) -> list[tuple[int, str]]:
    return [(i, text.strip()) for i, text in
            enumerate(data.decode("latin-1").splitlines(), 1)
            if text.strip() and not text.lstrip().startswith("\\")]


def routine_body(lines: list[tuple[int, str]], header: str) -> list[tuple[int, str]]:
    matches = [i for i, (_, line) in enumerate(lines) if line.startswith(header)]
    if len(matches) != 1:
        raise ValueError("Expected one routine declaration: " + header)
    start = matches[0]
    end = next((i for i in range(start + 1, len(lines))
                if ROUTINE_HEADER.match(lines[i][1])), len(lines))
    return lines[start:end]


def ordered_markers(lines: list[tuple[int, str]], phrases: tuple[str, ...]) -> list[int]:
    found = []
    cursor = 0
    for phrase in phrases:
        candidate = next((i for i in range(cursor, len(lines))
                          if phrase in lines[i][1]), None)
        if candidate is None:
            raise ValueError("Missing or reordered process-route marker: " + phrase)
        found.append(lines[candidate][0])
        cursor = candidate + 1
    return found


def locate_unique(lines: list[tuple[int, str]], needle: str) -> int:
    rows = [row for row, text in lines if text == needle]
    if len(rows) != 1:
        raise ValueError("Expected one menu/dispatch statement: " + needle)
    return rows[0]


def surface_counts(sources: dict[str, list[tuple[int, str]]]) -> dict:
    rows = [(filename, line, statement)
            for filename, content in sources.items()
            for line, statement in content]
    patterns = {
        "start_current_process_statement": re.compile(r"^Start the current process given\b", re.I),
        "stop_current_process_statement": re.compile(r"^Stop the current process\.$", re.I),
        "CreateProcessA_quoted_api": re.compile(r'\bCall\s+"kernel32\.dll"\s+"CreateProcessA"', re.I),
        "TerminateProcess_quoted_api": re.compile(r'\bCall\s+"kernel32\.dll"\s+"TerminateProcess"', re.I),
        "CreateThread_quoted_api": re.compile(r'\bCall\s+"kernel32\.dll"\s+"CreateThread"', re.I),
        "WaitForSingleObject_quoted_api": re.compile(r'\bCall\s+"kernel32\.dll"\s+"WaitForSingleObject"', re.I),
    }
    return {key: [{"file": filename, "line": line}
                  for filename, line, statement in rows if pattern.search(statement)]
            for key, pattern in patterns.items()}


def audit(reader) -> dict:
    sources = {}
    for filename in provenance.FILES:
        blob = reader("release", filename)
        checked = provenance.inspect(blob, "release", filename)
        if not checked["ok"]:
            raise ValueError("Pinned Plain English source mismatch: " + filename)
        sources[filename] = active_lines(blob)
    paths = {}
    for name, (filename, routine, markers) in ROUTES.items():
        paths[name] = {
            "file": filename,
            "routine": routine,
            "lines": ordered_markers(routine_body(sources[filename], routine), markers),
        }
    entry = {key: {"file": filename, "line": locate_unique(sources[filename], text)}
             for key, (filename, text) in ENTRY_MARKERS.items()}
    sites = surface_counts(sources)
    for key, count in EXPECTED_SITE_COUNTS.items():
        if len(sites[key]) != count:
            raise ValueError(
                "Process execution API or caller surface changed: " + key +
                " expected " + str(count) + " got " + str(len(sites[key])))
    return {
        "kind": "PINNED_STATIC_CAL_PROCESS_EXECUTION_ROUTES_NOT_SAFETY_CLEARANCE",
        "source_commit": provenance.COMMIT,
        "verified_text_modules": len(sources),
        "paths": paths,
        "menu_and_keyboard_entries": entry,
        "process_calls_and_apis": sites,
        "static_process_route_gate_pass": True,
        "observed_execution": False,
        "full_control_flow_proven": False,
        "absence_of_unlisted_execution_paths_proven": False,
        "compiler_executed": False,
        "stage_zero_verified": False,
        "malware_clearance": False,
        "native_qa_99_pass": False,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--fetch", action="store_true",
                      help="Fetch six pinned plain-text modules only")
    mode.add_argument("--directory", type=Path,
                      help="Read local root/release/* with symlink guard")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    reader = (provenance.download_source if args.fetch else
              lambda group, filename: provenance.read_directory_source(
                  args.directory, group, filename))
    try:
        result = audit(reader)
    except (OSError, ValueError, TypeError, KeyError) as exc:
        failed = {"kind": "STATIC_CAL_PROCESS_ROUTES_REJECTED",
                  "static_process_route_gate_pass": False,
                  "observed_execution": False,
                  "malware_clearance": False,
                  "native_qa_99_pass": False,
                  "error": str(exc)}
        if args.output:
            args.output.write_text(json.dumps(failed, indent=2) + "\n",
                                   encoding="utf-8")
        print(json.dumps(failed), file=sys.stderr)
        return 2
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + "\n",
                               encoding="utf-8")
    print(json.dumps({
        "static_process_route_gate_pass": True,
        "verified_text_modules": result["verified_text_modules"],
        "process_route_names": sorted(result["paths"]),
        "executable_run_source_calls": len(result["process_calls_and_apis"]["start_current_process_statement"]),
        "compiler_executed": False,
        "observed_execution": False,
        "native_qa_99_pass": False,
        "malware_clearance": False,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
