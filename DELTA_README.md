# Browser interface v8 delta

Apply over branch `JavaScript+Interlingue` at verified base HEAD:

`d00e3ddf980097e1f390e7ff753171cf2e458d24`

This delta continues the browser/interface port without changing the semantic core.

Highlights:
- one visually flat cutlet grid instead of separate visible month panels;
- original-site style day cards with three boxed date lines;
- strong searched-day badge and outline;
- original paper-gradient shell in the deployed `index.html`;
- 10 complete UI languages: Interlingue, English, Hebrew, Arabic, Russian,
  French, German, Spanish, Italian and Czech;
- every active locale covers all 17 current cutlet names and all 47 current
  month names;
- calendar-name lookup keys are exact current Interlingue source strings,
  never old positional indices.

The old locale resources from pinned commit
`d5cfe77ef7950a9a67ff0e6814833a3eedacae8a` are translation provenance only.
Changed semantic identities such as `larice`, `Palgursh`, `papirus`,
`Karshumb`, `leopard`, `candel` and `lilie` are translated explicitly for
their current meaning/spelling.

Generated browser bundles and `src/**` are intentionally not included.
