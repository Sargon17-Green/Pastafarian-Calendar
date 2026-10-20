#!/usr/bin/env python3
"""Seven adversarial, non-native event-log controls for the QA13 auditor.

These prove that plausible rewritten logged events fail semantic checks.
Synthetic examples are NOT Native evidence or an acceptance substitute.
"""
import copy
import stage1_qa13_native_memory_audit as auditor

BASE = [
    'STEP\t1\t1\t10\t10\t1\t0\t112\t3',
    'WRITE_BEFORE\t1\t5\t5\t32\t49',
    'WRITE_AFTER\t1\t5\t5\t49',
    'STEP\t2\t1\t5\t5\t1\t0\t49\t0',
    'STEP\t3\t1\t5\t0\t1\t0\t32\t0',
    'STEP\t4\t1\t6\t5\t1\t0\t103\t2',
    'READ_BEFORE\t4\t5\t5\t49',
    'READ_AFTER\t4\t5\t5\t49',
    'STEP\t5\t1\t7\t5\t1\t0\t112\t3',
    'WRITE_BEFORE\t5\t5\t5\t49\t50',
    'WRITE_AFTER\t5\t5\t5\t50',
]

def result(lines):
    return auditor.scan(('\n'.join(lines) + '\n').encode('ascii'), 'synthetic')

def require(ok, name):
    if not ok:
        raise AssertionError(name)

def main():
    # The unmodified shortened mock should pass event binding, then fail
    # solely for lacking the mandatory genuine p->executed gate at (1500,1860).
    try:
        result(BASE)
    except AssertionError as exc:
        require('missing physical write-then-execute gate' in str(exc),
                'legal mock rejected too early: ' + str(exc))
    else:
        raise AssertionError('incomplete mock falsely passed')
    attacks = [
        ('stale-write-before', 'WRITE_BEFORE\t5\t5\t5\t49\t50', 'WRITE_BEFORE\t5\t5\t5\t48\t50'),
        ('wrong-write-after', 'WRITE_AFTER\t1\t5\t5\t49', 'WRITE_AFTER\t1\t5\t5\t50'),
        ('duplicate-step-tick', 'STEP\t2\t1', 'STEP\t1\t1'),
        ('write-bound-to-g', 'STEP\t1\t1\t10\t10\t1\t0\t112', 'STEP\t1\t1\t10\t10\t1\t0\t103'),
        ('forged-executed-byte', 'STEP\t2\t1\t5\t5\t1\t0\t49', 'STEP\t2\t1\t5\t5\t1\t0\t50'),
        ('forged-read-after', 'READ_AFTER\t4\t5\t5\t49', 'READ_AFTER\t4\t5\t5\t50'),
        ('orphan-write-before', 'WRITE_AFTER\t1\t5\t5\t49', ''),
    ]
    sample='\n'.join(BASE) + '\n'
    for name, old, new in attacks:
        require(old in sample, 'attack fixture missing: ' + name)
        forged=sample.replace(old,new,1)
        try:
            auditor.scan(forged.encode('ascii'), 'forged-' + name)
        except AssertionError as exc:
            require('missing physical write-then-execute gate' not in str(exc),
                    'forgery reached only cosmetic gate check: ' + name)
        else:
            raise AssertionError('forged event accepted: ' + name)
    print('QA13_EVENT_BINDING_7_FORGED_CASES_REJECTED')
    print('SYNTHETIC_SELFTEST_NOT_A_NEW_NATIVE_RUN')

if __name__ == '__main__':
    main()
