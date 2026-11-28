#!/usr/bin/env python3
"""Apply a disposable exact Mersenne-127 reducer overlay to the pinned BigInt source."""
from __future__ import annotations
import hashlib
import json
import pathlib
import subprocess
import sys

BASELINE = "341927541dccc940bfc5e2b4073c21c647261278"
BIGINT_BLOB = "86581532df7492a236283c5ee9410ca281e2e6f5"
GATE_BLOB = "4b774c90f9a2fcdccaa2baac3ef80b0e8e99489e"
LEGACY_REMAINDER_BLOB = "bf7ec0147b9f3492d1e0db311f0f835a48775e85"
BIGINT_PATH = "src/+pastafari/BigInt.m"


def git(root: pathlib.Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(root), *args],
        check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ).stdout.strip()


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: apply_mersenne127.py CANDIDATE_CHECKOUT MANIFEST_PATH")
    root = pathlib.Path(sys.argv[1]).resolve()
    manifest_path = pathlib.Path(sys.argv[2]).resolve()
    assert git(root, "rev-parse", "HEAD") == BASELINE
    assert git(root, "rev-parse", f"HEAD:{BIGINT_PATH}") == BIGINT_BLOB
    assert git(root, "rev-parse", "HEAD:src/+pastafari/GateQuestionEngine.m") == GATE_BLOB
    assert git(root, "rev-parse", "HEAD:src/+pastafari/LegacyRemainderAdapter.m") == LEGACY_REMAINDER_BLOB

    path = root / BIGINT_PATH
    original = path.read_text(encoding="utf-8")
    old_constants = """        BASE = 10000000
        BASE_DIGITS = 7
"""
    new_constants = """        BASE = 10000000
        BASE_DIGITS = 7
        MERSENNE_127_LIMBS = [4105727 371588 7316873 469231 4118346 1701]
"""
    assert original.count(old_constants) == 1
    updated = original.replace(old_constants, new_constants, 1)

    old_regular_mod = """        function r = regularMod(a, b)
            [~, r] = floorDivMod(a, b);
        end
"""
    new_regular_mod = """        function r = regularMod(a, b)
            a = pastafari.BigInt.coerce(a);
            b = pastafari.BigInt.coerce(b);
            if b.signValue > 0 && isequal( ...
                    b.limbs, pastafari.BigInt.MERSENNE_127_LIMBS)
                remainderLimbs = ...
                    pastafari.BigInt.mersenne127ModMagnitude(a.limbs);
                r = pastafari.BigInt.fromParts(1, remainderLimbs);
                if a.signValue < 0 && ~r.iszero()
                    r = b - r;
                end
                return
            end
            [~, r] = floorDivMod(a, b);
        end
"""
    assert updated.count(old_regular_mod) == 1
    updated = updated.replace(old_regular_mod, new_regular_mod, 1)

    helper = """        function out = mersenne127ModMagnitude(decimalLimbs)
            % Exact reduction modulo 2^127-1. The accumulator is four
            % little-endian uint32 limbs (the top limb has 31 live bits).
            mask32 = uint64(4294967295);
            top31 = uint64(2147483647);
            base32 = uint64(4294967296);
            base10 = uint64(pastafari.BigInt.BASE);
            state = zeros(1, 4, 'uint64');

            for pos = numel(decimalLimbs):-1:1
                carry = uint64(decimalLimbs(pos));
                expanded = zeros(1, 5, 'uint64');
                for k = 1:4
                    current = state(k) * base10 + carry;
                    expanded(k) = bitand(current, mask32);
                    carry = bitshift(current, -32);
                end
                expanded(5) = carry;

                % x = low + high*2^127 and 2^127 == 1 (mod 2^127-1).
                high = bitshift(expanded(4), -31) + ...
                    bitshift(expanded(5), 1);
                low = [expanded(1), expanded(2), expanded(3), ...
                    bitand(expanded(4), top31)];

                carry = high;
                for k = 1:4
                    current = low(k) + carry;
                    low(k) = bitand(current, mask32);
                    carry = bitshift(current, -32);
                end

                % A carry out of bit 126 is another 2^127, hence +1.
                if carry ~= uint64(0)
                    carry = uint64(1);
                    for k = 1:4
                        current = low(k) + carry;
                        low(k) = bitand(current, mask32);
                        carry = bitshift(current, -32);
                        if carry == uint64(0)
                            break
                        end
                    end
                    if carry ~= uint64(0)
                        error('Pastafari:BigInt:MersenneFoldOverflow', ...
                            'Unexpected second carry in Mersenne-127 reduction.');
                    end
                end

                % The sole 127-bit value equal to the modulus maps to zero.
                if low(1) == mask32 && low(2) == mask32 && ...
                        low(3) == mask32 && low(4) == top31
                    low(:) = uint64(0);
                end
                state = low;
            end

            % Convert the four base-2^32 limbs back to base 10^7.
            work = state;
            out = zeros(1, 0);
            while any(work ~= uint64(0))
                remainder = uint64(0);
                for k = 4:-1:1
                    current = remainder * base32 + work(k);
                    work(k) = idivide(current, base10, 'floor');
                    remainder = mod(current, base10);
                end
                out(end + 1) = double(remainder); %#ok<AGROW>
            end
            if isempty(out)
                out = 0;
            end
            out = pastafari.BigInt.trimMagnitude(out);
        end

"""
    needle = "        function [sgn, lm] = parseDecimal(s)\n"
    assert updated.count(needle) == 1
    updated = updated.replace(needle, helper + needle, 1)
    path.write_text(updated, encoding="utf-8", newline="\n")

    changed = git(root, "diff", "--name-only").splitlines()
    assert changed == [BIGINT_PATH], changed
    candidate_blob = git(root, "hash-object", BIGINT_PATH)
    gate_blob_after = git(root, "hash-object", "src/+pastafari/GateQuestionEngine.m")
    legacy_blob_after = git(root, "hash-object", "src/+pastafari/LegacyRemainderAdapter.m")
    assert gate_blob_after == GATE_BLOB
    assert legacy_blob_after == LEGACY_REMAINDER_BLOB
    assert candidate_blob != BIGINT_BLOB

    payload = {
        "source_commit": BASELINE,
        "original_bigint_blob": BIGINT_BLOB,
        "candidate_git_blob": candidate_blob,
        "candidate_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "gate_engine_blob_unchanged": gate_blob_after,
        "legacy_remainder_adapter_blob_unchanged": legacy_blob_after,
        "changed_paths": changed,
        "algorithm": "exact base-2^32 Mersenne fold for modulus 2^127-1",
        "negative_semantics": "r = M - (abs(a) mod M) when a < 0 and remainder != 0",
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, sort_keys=True))


if __name__ == "__main__":
    main()
