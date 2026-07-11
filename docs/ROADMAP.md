# Krom Editor Roadmap

Krom is a Flutter desktop code editor targeting a **keyboard-first, motion-polished,
theme-rich** coding experience. This document is the canonical plan for reaching a
full-fledged editor. Status markers: ✅ done · 🚧 in progress · ⬜ planned.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  IdeConceptsPage (shell — title bar, sidebar, tabs, panels) │
├─────────────────────────────────────────────────────────────┤
│  EditorSession (shared backend — tabs, LSP, parser, git)    │
├──────────────────────┬──────────────────────────────────────┤
│  lsp_client (git)    │  parser_client / krom-parser (git)   │
└──────────────────────┴──────────────────────────────────────┘
```

**Rule:** All new editor behavior goes through `EditorSession`. UI shells only render
and forward input. Delete legacy `EditorPage` once feature parity is complete.

---

## Phase 0 — Foundation ✅

| Item | Status |
|------|--------|
| IDE Concepts shell as app entry | ✅ |
| `EditorSession` shared backend | ✅ |
| LSP: diagnostics, completion, hover, go-to-def, refs, format | ✅ |
| Parser syntax highlighting | ✅ |
| Command palette (files + commands) | ✅ |
| Git status in sidebar | ✅ |
| Focus mode, go-to-line, autosave | ✅ |
| Outline panel (`Ctrl+Shift+O`) | ✅ |
| Structural selection (`Shift+Alt+→/←`) | ✅ |
| Theme registry (5 built-in themes) | ✅ |

---

## Phase 1 — Editor Core (Sprint 1) ✅

High-impact features that make Krom a daily driver.

| Feature | Shortcut | Status |
|---------|----------|--------|
| Find in file | `Ctrl+F` | ✅ |
| Find & replace bar | `Ctrl+H` | ✅ |
| Rename symbol (LSP) | `F2` | ✅ |
| LSP document symbols in outline | — | ✅ |
| Theme picker UI (live preview) | palette | ✅ |
| Unified motion tokens (`KromMotion`) | — | ✅ |

### Find & Replace

- Bottom overlay bar with slide-up animation
- Case-sensitive toggle, match count, next/prev (`F3` / `Shift+F3`)
- Replace one / replace all in active file
- Selection-scoped search when text is selected on open

### Rename

- `prepareRename` → dialog with placeholder
- `textDocument/rename` → apply `WorkspaceEdit` across open tabs and disk

### Outline upgrade

- Primary: `LspService.getDocumentSymbols()` hierarchical tree
- Fallback: regex `OutlineService` when LSP unavailable
- Live refresh debounced 400 ms on edit

---

## Phase 2 — Editor Depth ⬜

| Feature | Shortcut |
|---------|----------|
| Workspace search | `Ctrl+Shift+F` |
| Problems panel | `Ctrl+Shift+M` |
| Code actions / quick fixes | `Ctrl+.` |
| Signature help | typing `(` |
| AST structural selection | `Shift+Alt+→` upgrade via parser |
| Multi-cursor | `Ctrl+D`, `Ctrl+Shift+L` |
| Bracket pair colorization | — |
| Minimap | — |
| Split editors | drag tab |

---

## Phase 3 — Themes & Motion ⬜

### Theme system

```
IdeConceptsTheme (design tokens)
  ├── chrome (sidebar, tabs, status, panels)
  ├── editor (bg, gutter, cursor, selection, line highlight)
  ├── syntax map (keyword, string, comment, …)
  └── motion (duration, curve per surface)

IdeConceptsThemes registry
  ├── built-in catalog (target: 10–15 curated themes)
  ├── user themes (~/.config/krom/themes/*.json)
  └── import/export (VS Code theme JSON subset)
```

| Capability | Detail |
|------------|--------|
| Semantic highlighting | LSP `semanticTokens` overrides |
| Font stack | editor + UI fonts, ligatures, size per workspace |
| Accent variants | same base theme, swappable accent |
| High contrast | WCAG AAA auto-generated variant |
| OS sync | follow system light/dark |
| Theme transitions | 280 ms cross-fade on all surfaces |

### Motion spec (`KromMotion`)

| Surface | Spec |
|---------|------|
| Panels | 320 ms `easeOutCubic` width |
| Palette | scale 0.96→1 + `easeOutBack` + backdrop blur |
| Tab pill | 280 ms `AnimatedPositioned` |
| Hover | 120 ms background fade |
| Save flash | dirty dot → checkmark morph 200 ms |
| Go-to-def | target line highlight pulse 1.2 s |

---

## Phase 4 — Workspace Intelligence ⬜

- Git: inline diff gutters, stage hunks, blame toggle
- Terminal panel (`Ctrl+`` `)
- File watcher with external-change prompt
- Per-project `.krom/settings.json` overrides
- Extension manifest for custom panels/commands/themes

---

## Phase 5 — AI & Collaboration ⬜

- Inline ghost completion (`Tab` to accept)
- Context-aware chat sidebar
- Code lens (references count, run test)
- Live share (CRDT / OT — ambitious)

---

## Implementation Order

```
Phase 0  ✅  Shell, LSP, outline, structural selection, themes
Phase 1  ✅  Find/replace, rename, LSP outline, theme picker, motion tokens
Phase 2      Workspace search, problems, code actions, minimap, splits
Phase 3      User themes, semantic tokens, motion polish pass
Phase 4      Terminal, git diff, file watcher
Phase 5      AI inline assist
```

---

## Cleanup

- [ ] Remove `EditorPage` and legacy `PanelHost` / `KromColors` stack
- [ ] Retire regex-only `lib/panels/outline/` once LSP outline is stable
- [ ] Consolidate duplicate `CodeView` widgets into one themed implementation

---

## Commands (dev)

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d linux   # requires DISPLAY=:1
```

Settings: `~/.config/krom/settings.json` — keys include `theme`, `autosave`,
`languageServers`, `parserCommand`, `useTreeSitter`.
