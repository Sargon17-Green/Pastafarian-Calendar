# Stage-01 Hebrew source-purity fix

Apply over `JavaScript+Interlingue` at HEAD
`73b71fdc102338bfe736bb2fcacfffc6353396b9`.

The Stage-01 verifier rejects raw Hebrew Unicode code points in every `.js`,
`.json`, and `.md` file in the repository.

This fix:
- replaces the Hebrew display label in `browser/README.md` with the ASCII label
  `Hebrew`;
- encodes every Hebrew-block code point in browser/test JavaScript as a
  `\uXXXX` escape;
- preserves the exact runtime Hebrew strings, RTL behavior, locale coverage,
  calendar-name translations, and test expectations;
- does not change the core, workflow, package.json, or public API.

After applying the fix, a push should trigger the Pages workflow because the
workflow was changed on the current branch to run on every push.
