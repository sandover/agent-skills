# Pages Compatibility

Use these rules when changing layout or page furniture for Strike Valley DOCX output.

## Safe Patterns

- Use a single footer paragraph.
- Put the watermark on the left as one combined PNG.
- Put the page number on the same footer paragraph with a right tab stop.
- Use a generated PNG for the top horizontal rule and descender motif.
- Verify in Pages, not only in Word-compatible reasoning.

## Unsafe Patterns

- Footer tables.
- Nested tables in headers or footers.
- Border-only tricks for the branded top rule.
- Tiny geometry tweaks that depend on cell margins being honored by Pages.

## Known Good Footer Pattern

- Watermark image contains both logo and studio name so they remain axis-aligned.
- Page number is rendered in the same footer paragraph.
- If the page number appears lower than the watermark, lower the watermark art inside the image instead of chasing paragraph-level spacing.

## Known Good Header Pattern

- Keep the logo block and the top rule visually separate.
- If the rule feels like it cuts the logo, create more vertical separation before pushing the rule far right.
- Tighten title-to-rule distance by reducing empty height in the rule image, not only by paragraph spacing.

## TOC Notes

- For report documents, put the TOC after the first section, not immediately after the cover.
- Keep TOC entry formatting close to the stable default.
- If shifting the TOC right, do it conservatively. Do not redesign the entry styles unless necessary.
