#!/usr/bin/env python3
"""Cold isolated *reference* process. No audited-Kotlin algorithm imports.

Called only under python -I from the 3x5 differential orchestrator.
Its historical static checkpoint structures belong to the pinned reference;
they are never imported into the independent candidate process.
"""
from __future__ import annotations
import argparse
import hashlib
import importlib
import json
from pathlib import Path
import subprocess
import sys

PINNED_SHA = '7cb12bf355461e5a179e0deadb7365689288bf29'
FOUNDATION = -15055671
TARGETS = (-278523, -278522, -278521)


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument('--source-root', type=Path, required=True)
    p.add_argument('--day', type=int, required=True)
    args = p.parse_args(argv)
    if not sys.flags.isolated or args.day not in TARGETS:
        raise ValueError('E_REFERENCE_NOT_ISOLATED_OR_BAD_TARGET')
    source_root = args.source_root.resolve(strict=True)
    commit = subprocess.check_output(
        ['git', '-C', str(source_root.parent), 'rev-parse', 'HEAD'],
        text=True, timeout=10).strip()
    if commit != PINNED_SHA or source_root.name != 'src':
        raise ValueError('E_REFERENCE_GIT_PROVENANCE')
    sys.path.insert(0, str(source_root))
    calendar = importlib.import_module('pastafari_calendar.calendar')
    integration = importlib.import_module('pastafari_calendar.final_integration')
    names = importlib.import_module('pastafari_calendar.source_language_catalog')
    scars = importlib.import_module('pastafari_calendar.acceleration_scars')
    for module in (calendar, integration, names, scars):
        if not Path(module.__file__).resolve(strict=True).is_relative_to(source_root):
            raise ValueError('E_REFERENCE_IMPORT_ESCAPE')
    if integration.FOUNDATION_DAY_INTEGRATED != FOUNDATION:
        raise ValueError('E_REFERENCE_ORIGIN_DRIFT')
    cat = names.SOURCE_LANGUAGE_CATALOG
    cutlets = {item.text:item.canonical_index for item in cat.cutlets}
    months = {item.text:item.canonical_index for item in cat.months}
    if (len(cutlets),len(months)) != (17,47):
        raise ValueError('E_REFERENCE_CATALOG')
    # New process for every requested day; clear even process-local acceleration
    # stores. Reference may reconstruct its own pinned static gate checkpoints.
    scars.reset_acceleration_scars_for_tests()
    with scars.acceleration_mode(True):
        result = calendar.calendar_date_spaghetti(FOUNDATION, args.day)
    if not isinstance(result, integration.SpaghettiDateResult):
        raise ValueError('E_REFERENCE_RESULT_TYPE')
    try:
        fields = [result.year_number,cutlets[result.cutlet_name],
                  result.day_in_cutlet,months[result.month_name],result.day_in_month]
    except (KeyError, AttributeError) as exc:
        raise ValueError('E_REFERENCE_RESULT_CATALOG') from exc
    if any(type(value) is not int or value < 1 for value in fields):
        raise ValueError('E_REFERENCE_RESULT_RANGE')
    module_sha = hashlib.sha256(Path(integration.__file__).read_bytes()).hexdigest()
    print(json.dumps({'day':args.day,'five_fields':fields,'reference_commit':commit,
                      'pinned_integration_sha256':module_sha,'isolation_mode':'python_-I',
                      'process_cache_reset':True,'pinned_static_checkpoints_may_be_used':True},
                     sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
