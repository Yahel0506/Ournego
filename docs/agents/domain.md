# Domain Docs

This repo uses a multi-context layout. Skills that need domain vocabulary or architectural history should start with `CONTEXT-MAP.md` at the repo root, then follow the mapping to the relevant `CONTEXT.md` file.

## Reading order

- Read `CONTEXT-MAP.md` first.
- Read the relevant `CONTEXT.md` for the area you are working in.
- Read `docs/adr/` for repo-wide decisions.
- If a context has its own ADR folder, also read `src/<context>/docs/adr/`.

## File structure

Multi-context repos organize domain docs like this:

```
/
├── CONTEXT-MAP.md
├── docs/adr/
└── src/
    ├── feature-a/
    │   ├── CONTEXT.md
    │   └── docs/adr/
    └── feature-b/
        ├── CONTEXT.md
        └── docs/adr/
```

## Usage rules

- Use the glossary terms from the relevant `CONTEXT.md` when naming issues, tests, refactors, and design notes.
- If a proposal conflicts with an ADR, call out the conflict instead of silently overriding it.
- If a context does not have docs yet, proceed with the nearest relevant source and note the gap for future documentation.
