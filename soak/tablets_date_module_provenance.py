#!/usr/bin/env python3
"""Fail-closed identity preflight for a *future* independent TABLETS date oracle.

Checks bytes against the corresponding Git HEAD blob and SHA256, distinct pinned
commit/worktree, and some obvious imports of the pinned date algorithm.
This is neither proof of algorithmic independence nor a five-field comparison.
"""
from __future__ import annotations

import ast
from dataclasses import dataclass
import hashlib
from pathlib import Path
import re
import subprocess

PINNED_SHA = '7cb12bf355461e5a179e0deadb7365689288bf29'
STATUS = 'PASS_DATE_MODULE_IDENTITY_PREFLIGHT_NOT_CERTIFIED'
_HEX40 = re.compile(r'[0-9a-f]{40}\Z')
_HEX64 = re.compile(r'[0-9a-f]{64}\Z')
_FORBIDDEN = ('pastafari_calendar', 'final_integration',
              'verify_pinned_gate_checkpoints', 'post55_differential')


class DateSourceError(ValueError):
    pass


@dataclass(frozen=True)
class DateModule:
    repo_root: Path
    relative_path: str
    commit_sha: str
    module_sha256: str
    date_function: str


def _git(root: Path, *args: str) -> str:
    try:
        return subprocess.check_output(
            ['git', '-C', str(root), *args], text=True,
            stderr=subprocess.DEVNULL, timeout=10).strip()
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
        raise DateSourceError('E_DATE_SOURCE_GIT') from exc



def _audit_local_closure(root: Path, entry: Path) -> dict:
    """Git-check every statically resolvable in-repository Python dependency.

    This is a bounded STATIC closure only. Arbitrary runtime Python behavior,
    external dependencies, shared caches, and mathematical independence are
    deliberately NOT claimed to be audited.
    """
    visited = {}

    def visit(relative: Path) -> None:
        key = relative.as_posix()
        if key in visited:
            return
        if len(visited) >= 64:
            raise DateSourceError('E_INDEPENDENT_DEPENDENCY_BUDGET')
        full = root / relative
        if (full.is_symlink() or not full.is_file()
                or not full.resolve().is_relative_to(root)):
            raise DateSourceError('E_INDEPENDENT_DEPENDENCY_PATH')
        data = full.read_bytes()
        if len(data) > 1024 * 1024:
            raise DateSourceError('E_INDEPENDENT_DEPENDENCY_BUDGET')
        if _git(root, 'rev-parse', f'HEAD:{key}') != _git(
                root, 'hash-object', '--no-filters', str(full)):
            raise DateSourceError('E_INDEPENDENT_DEPENDENCY_DIRTY')
        try:
            tree = ast.parse(data.decode('utf-8'), filename=key)
        except (SyntaxError, UnicodeError) as exc:
            raise DateSourceError('E_INDEPENDENT_DEPENDENCY_PARSE') from exc
        visited[key] = {
            'git_blob_sha': _git(root, 'rev-parse', f'HEAD:{key}'),
            'module_sha256': hashlib.sha256(data).hexdigest(),
        }

        def follow(module: str, base: Path) -> None:
            if not module:
                return
            if any(module == banned or module.startswith(banned + '.')
                   for banned in _FORBIDDEN):
                raise DateSourceError('E_INDEPENDENT_TRANSITIVE_PINNED_IMPORT')
            parts = module.split('.')
            if not all(part.isidentifier() for part in parts):
                raise DateSourceError('E_INDEPENDENT_DEPENDENCY_MODULE')
            tail = Path(*parts)
            for prefix in (base, root):
                candidates = (prefix / tail.with_suffix('.py'),
                              prefix / tail / '__init__.py')
                for candidate in candidates:
                    if candidate.exists() or candidate.is_symlink():
                        if not candidate.resolve().is_relative_to(root):
                            raise DateSourceError('E_INDEPENDENT_DEPENDENCY_PATH')
                        visit(candidate.relative_to(root))

        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                func = node.func
                if (isinstance(func, ast.Name)
                        and func.id in ('__import__', 'eval', 'exec')):
                    raise DateSourceError('E_INDEPENDENT_TRANSITIVE_DYNAMIC_SOURCE')
                if (isinstance(func, ast.Attribute) and func.attr in (
                        'import_module', 'spec_from_file_location',
                        'run_module', 'run_path', 'SourceFileLoader',
                        'exec_module', 'load_module')):
                    raise DateSourceError('E_INDEPENDENT_TRANSITIVE_DYNAMIC_SOURCE')
            if isinstance(node, ast.Import):
                for alias in node.names:
                    follow(alias.name, full.parent)
            elif isinstance(node, ast.ImportFrom):
                if any(alias.name == '*' for alias in node.names):
                    raise DateSourceError('E_INDEPENDENT_WILDCARD_IMPORT')
                base = full.parent
                if node.level:
                    for _ in range(node.level - 1):
                        base = base.parent
                    if not base.is_relative_to(root):
                        raise DateSourceError('E_INDEPENDENT_DEPENDENCY_PATH')
                else:
                    base = root
                module = node.module or ''
                follow(module, base)
                for alias in node.names:
                    follow(module + '.' + alias.name if module else alias.name,
                           base)

    visit(entry)
    return dict(sorted(visited.items()))

def _check_module(source: DateModule, *, independent: bool) -> dict:
    role = 'INDEPENDENT' if independent else 'PINNED'
    if (not isinstance(source, DateModule)
            or not isinstance(source.repo_root, Path)
            or type(source.relative_path) is not str
            or type(source.date_function) is not str
            or not source.date_function.isidentifier()
            or type(source.commit_sha) is not str
            or not _HEX40.fullmatch(source.commit_sha)
            or type(source.module_sha256) is not str
            or not _HEX64.fullmatch(source.module_sha256)):
        raise DateSourceError(f'E_{role}_SOURCE_DESCRIPTOR')
    root = source.repo_root.resolve(strict=True)
    if _git(root, 'rev-parse', '--show-toplevel') != str(root):
        raise DateSourceError(f'E_{role}_ROOT')
    if _git(root, 'rev-parse', 'HEAD') != source.commit_sha:
        raise DateSourceError(f'E_{role}_HEAD_MISMATCH')
    rel = Path(source.relative_path)
    if rel.is_absolute() or not rel.parts or any(p in ('.', '..') for p in rel.parts):
        raise DateSourceError(f'E_{role}_PATH')
    path = root.joinpath(rel)
    if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root):
        raise DateSourceError(f'E_{role}_PATH')
    expected_blob = _git(root, 'rev-parse', f'HEAD:{rel.as_posix()}')
    actual_blob = _git(root, 'hash-object', '--no-filters', str(path))
    if not _HEX40.fullmatch(expected_blob) or expected_blob != actual_blob:
        raise DateSourceError(f'E_{role}_WORKTREE_DIRTY')
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if digest != source.module_sha256:
        raise DateSourceError(f'E_{role}_DIGEST_MISMATCH')
    try:
        tree = ast.parse(data.decode('utf-8'), filename=source.relative_path)
    except (SyntaxError, UnicodeError) as exc:
        raise DateSourceError(f'E_{role}_PARSE') from exc
    defs = {node.name for node in tree.body
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))}
    if source.date_function not in defs:
        raise DateSourceError(f'E_{role}_FUNCTION_MISSING')
    if independent:
        for node in ast.walk(tree):
            names = []
            if isinstance(node, ast.Import):
                names = [a.name for a in node.names]
            elif isinstance(node, ast.ImportFrom):
                names = [node.module or '']
            for name in names:
                if any(name == banned or name.startswith(banned + '.')
                       for banned in _FORBIDDEN):
                    raise DateSourceError('E_INDEPENDENT_PINNED_IMPORT')
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) \
                    and node.func.id in ('__import__', 'eval', 'exec'):
                raise DateSourceError('E_INDEPENDENT_DYNAMIC_SOURCE')
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) \
                    and node.func.attr == 'import_module':
                raise DateSourceError('E_INDEPENDENT_DYNAMIC_SOURCE')
    closure = _audit_local_closure(root, rel) if independent else {}
    return {'commit_sha': source.commit_sha, 'module_sha256': digest,
            'git_blob_sha': expected_blob, 'date_function': source.date_function,
            'relative_path': rel.as_posix(), 'repo_root': str(root),
            'static_local_dependency_closure': closure}


def verify_date_module_identities(independent: DateModule,
                                  pinned: DateModule) -> dict:
    """Validate code *identity*, never infer correctness or independence."""
    if not isinstance(independent, DateModule) or not isinstance(pinned, DateModule):
        raise DateSourceError('E_DATE_SOURCE_DESCRIPTOR')
    if pinned.commit_sha != PINNED_SHA:
        raise DateSourceError('E_PINNED_COMMIT_LOCK')
    a = _check_module(independent, independent=True)
    b = _check_module(pinned, independent=False)
    if (a['commit_sha'] == b['commit_sha']
            or a['module_sha256'] == b['module_sha256']
            or a['repo_root'] == b['repo_root']
            or (a['repo_root'], a['relative_path']) == (b['repo_root'], b['relative_path'])):
        raise DateSourceError('E_DATE_SOURCE_NOT_SEPARATE')
    return {'status': STATUS, 'independent': a, 'pinned': b,
            'algorithmic_independence_certified': False,
            'cache_independence_certified': False,
            'full_date_verified': False, 'certifiable': False,
            'note': 'Git-verified static in-repository import closure only; runtime imports, third-party dependencies, cache isolation and algorithmic independence remain unproven.'}
