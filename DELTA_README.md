# Browser interface v7 delta

Apply these files to branch `JavaScript+Interlingue` over verified base HEAD
`221c7af4e672fc11799d1c5582e788ee455cf717`.

This delta does not include `src/**` or generated browser bundles.

Main changes:
- public visual shell closer to the pinned original site;
- large three-line non-interactive day cards and target beacon;
- stable month visual identity derived from current semantic month source name;
- Web Component lifecycle/race hardening, including no-editor/headless modal closure;
- complete UI + current 17 cutlet / 47 month localization for:
  Interlingue, English, Hebrew, Arabic, Russian;
- Hebrew and Arabic RTL;
- raw `value`, `ready`, and `pastafari-change` remain the black-box core result.

The local workspace is not a full repository clone, so the GitHub Actions run after
upload is authoritative for the real Stage-01/core integration.
