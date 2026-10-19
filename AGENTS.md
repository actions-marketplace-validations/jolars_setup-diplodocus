# Repository guidance

This repository contains a composite GitHub Action that installs the Diplodocus CLI.
`action.yml` orchestrates version resolution, caching, installation, and PATH
updates. The scripts in `scripts/` handle release resolution and Unix and
Windows downloads. `fixtures/site/` is a Markdown-only integration site.

Keep installation separate from documentation builds and runtime preparation.
Accept exact CLI versions with or without `v`, and resolve `latest` before cache
lookup. Cache and install each version and target separately. Match the archive
names and layouts published by `jolars/diplodocus`: Unix `.tar.xz` archives have
a containing directory; Windows ZIP archives contain the binary at the root.
Downloaded archives require matching checksums, and provenance verification
failures must stop installation.

Enter `devenv shell` for development tools. Run `node --test tests/*.test.mjs`
for installer and resolver tests. Before pushing, run `shellcheck scripts/*.sh`,
`shfmt -d scripts/*.sh`, `actionlint`, `panache format --check .`, and
`panache lint .`. CI also parses the PowerShell installer and runs the action on
the supported runner platforms. Update the README with action API changes.

Versionary owns `version.txt` and `CHANGELOG.md`; do not hand-edit release
entries. Its configuration uses the simple strategy and release PR review. The
tag workflow maintains floating major and minor action tags only for stable
releases. Do not copy release manifests or Git history from the reference action
repositories.
