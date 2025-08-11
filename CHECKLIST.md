# ExtraKeybinds – ReadAll Robustness Checklist

## Data model (shared/booklist.lua)

- [ ] Add whitelist/blacklist structure
  - [ ] `includedFullTypes`, `excludedFullTypes`
  - [ ] `includedFullTypePatterns`, `excludedFullTypePatterns` (lowercased)
  - [ ] `includedTags`, `excludedTags` (optional)
  - [ ] High-level toggles (start small): `readSkillBooks`, `readMagazines`, `readFiction`, `readNewspapers` (only enable those we use)
- [ ] Remove duplicate keys (e.g., repeated `Basic.generic.mail`)
- [ ] Keep `excludeIlliterate` and `allowPictureBooksForIlliterate` defaults

## Mod Options (client/ExtraKeybindsOptions.lua)

- [ ] Expose simple toggles first
  - [ ] `readSkillBooks`
  - [ ] `excludeMail`, `excludeNewspaper`
- [ ] Add advanced text inputs (optional)
  - [ ] `extraIncludedFullTypes` (comma-separated)
  - [ ] `extraExcludedFullTypes` (comma-separated)
- [ ] (Optional) On-apply hook to refresh merged sets without restart (if Mod Options supports it)

## Logic (client/readall.lua)

- [ ] Safe-require `shared/booklist` + Mod Options
- [ ] Build normalized exclusion/inclusion sets
  - [ ] Start from defaults (booklist)
  - [ ] Merge Mod Options toggles/inputs (augment sets)
  - [ ] Deduplicate patterns/tags (lowercase once)
- [ ] Create a single decision function
  - [ ] `resolveShouldRead(item, player)` with precedence:
    1. matches any include → read
    2. matches any exclude → skip
    3. else apply toggles + vanilla checks (pages, already-read)
- [ ] Replace inline checks with calls to `resolveShouldRead`
- [ ] Keep world/inventory flows unchanged; continue using `getWorldObjects()` for ground items

## Debug/QA

- [ ] (Optional) Debug toggle in Mod Options
  - [ ] Throttled `player:Say()` reason outputs (e.g., “Skip: Mail” / “Read: Skill book OK”)
- [ ] Test matrix
  - [ ] Inventory container, nested containers, and ground items
  - [ ] Skill books at/below/above level
  - [ ] Newspapers/Mail/ID cards (ensure skipped)
  - [ ] Illiterate trait ON/OFF, picture books allowed
  - [ ] Toggle `readSkillBooks` ON/OFF

## Performance & Safety

- [ ] Guard all API calls (nil checks on item/container/world item)
- [ ] Fail fast: category → writeable → exclusions
- [ ] Cache lowercase fullType once per item before pattern checks

## UX & Docs

- [ ] Keep keybinds in Options > Key Bindings (standard)
- [ ] Mods tab for toggles only
- [ ] Update `docs/readall_functions.md` with new decision flow & option precedence

## Future Enhancements (optional)

- [ ] Mods option for scan radius (3x3 → configurable)
- [ ] Per-category toggles (Magazines/Fiction/Newspapers) if needed
- [ ] Export/import presets (JSON string in Mod Options field)
