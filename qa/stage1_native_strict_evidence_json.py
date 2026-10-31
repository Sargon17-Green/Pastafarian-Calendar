#!/usr/bin/env python3
"""Fail-closed JSON parsing for Stage-1 Native evidence receipts (QA only).

Python's default json.loads silently accepts duplicate object keys and
nonstandard NaN/Infinity tokens. Those produce ambiguous interpretations of
physical opcode histories, signed input indexes, and checksum manifests.
This reader leaves ordinary JSON values unchanged and never rewrites evidence.
"""
import json


def strict_evidence_loads(data):
    """Decode one native evidence JSON document; reject ambiguous literals."""
    def unique_object(pairs):
        record = {}
        for key, value in pairs:
            if key in record:
                raise ValueError('duplicate Native evidence JSON key: ' + repr(key))
            record[key] = value
        return record

    def forbidden_constant(token):
        raise ValueError('non-finite Native evidence JSON literal: ' + token)

    def forbidden_float(token):
        raise ValueError('floating Native evidence JSON number: ' + token)

    return json.loads(data, object_pairs_hook=unique_object,
                      parse_constant=forbidden_constant,
                      parse_float=forbidden_float)
