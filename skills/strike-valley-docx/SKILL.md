---
name: strike-valley-docx
description: Convert Markdown into polished, branded Strike Valley Studio DOCX documents that remain editable in Pages or Word. Use when the user wants a consultancy-style report, proposal, memo, or assessment from Markdown, especially when cover design, bullet fidelity, TOC layout, page furniture, or Pages compatibility matter.
---

# Strike Valley DOCX

Render Markdown into branded `.docx` using the bundled renderer, then spot-check the result in Pages when layout matters. The renderer also exports a sibling `.pdf` via Pages by default.

## Use This Skill By Default

- Use [`scripts/render_branded_docx.py`](scripts/render_branded_docx.py) for normal Markdown -> DOCX work.
- Use `uv run --with python-docx --with Pillow python ...`, not `pip install ...`.
- Expect a sibling PDF to be generated automatically unless `--no-pdf` is passed.
- Keep the Markdown as the source of truth. Fix the renderer or inputs before doing repetitive manual cleanup in Pages.

## Gather Only What You Need

Infer sensible defaults from the Markdown, then confirm only the fields that are actually ambiguous:

- title
- prepared for
- author, if relevant
- date
- TOC placement

For consultancy reports, default to:

- `--toc after-first-section`
- no author unless the user wants it on the cover
- no version number unless explicitly requested

## Render

```bash
UV_CACHE_DIR=/tmp/uv-cache uv run --with python-docx --with Pillow python scripts/render_branded_docx.py INPUT.md \
  -o OUTPUT.docx \
  --title "Document Title" \
  --prepared-for "Name, Role" \
  --date "26 Mar 2026" \
  --toc after-first-section
```

All flags are optional except the input and output paths. By default this writes both `OUTPUT.docx` and `OUTPUT.pdf`. Pass `--no-pdf` to skip the PDF export.

## Defaults And Invariants

These are not ad hoc preferences. Treat them as defaults unless the user asks otherwise.

- Fonts: Eurostile / Eurostile Bold for title, labels, and headings; IBM Plex Sans for body and metadata; Inconsolata for URLs.
- Page color: warm off-white `#FAF8F2`.
- Cover logo: use the deep navy logo variant when available.
- Cover rule: use the branded rule image with a short right descender.
- Cover ordering for reports: cover block, executive summary, then TOC.
- TOC alignment: contents label and TOC entries should sit on the same left edge as body text, not flush to the margin.
- Footer: watermark and page number must read as one deliberate line.

If any of those drift, fix the renderer rather than accepting the output.

## Pages Compatibility Rules

Read [references/pages-compatibility.md](references/pages-compatibility.md) before changing header/footer mechanics or trying a new layout trick.

The short version:

- Do not use footer tables.
- Do not rely on paragraph borders for the branded top rule.
- Prefer generated image assets for the header rule and descender motif.
- Prefer a single footer paragraph with a combined watermark image on the left and a right tab stop for the page number.
- Automatic PDF export depends on Pages automation being available and permitted on the machine.

## Visual Rules

Read [references/visual-invariants.md](references/visual-invariants.md) when tuning the cover, TOC, or footer.

Important examples:

- A line that merely “technically clears” the logo can still read as if it cuts the logo. Optimize for perception, not geometry arguments.
- Widening a line is usually better solved by creating vertical separation, not by pushing the line far right and weakening the composition.
- TOC styling should echo the cover motif, not fall back to a generic rule.

## Fixtures

Use the bundled fixtures instead of testing only on tiny synthetic inputs:

- [`fixtures/GTM-AI-Assessment-Report.md`](fixtures/GTM-AI-Assessment-Report.md): real report with cover, executive summary, TOC, headings, lists
- [`fixtures/footer-debug.md`](fixtures/footer-debug.md): fast loop for footer geometry and watermark alignment
- [`fixtures/keyloop-proposal-cover.yaml`](fixtures/keyloop-proposal-cover.yaml): proposal-style top matter reference for the legacy cover renderer

Use `footer-debug.md` when tuning footer baseline, watermark visibility, or page-number alignment. Use the report fixture when tuning cover spacing, TOC placement, or report-level defaults.

## Verification Loop

When appearance matters, do a short Pages verification loop:

1. Render the DOCX.
2. Open it in Pages.
3. Check the first page.
4. Check the TOC page.
5. Check a later body page footer.

Minimum visual checks:

- executive summary appears before the TOC for report-style documents
- the top rule is strong and does not read as cutting the logo
- title sits close enough to the top rule to feel connected
- version number is absent unless explicitly requested
- TOC is indented to the body column
- TOC rule starts at the same left position as the cover rule and includes the descender motif
- watermark and page number sit on the same visual line

## When To Edit Inputs vs Renderer

Edit the Markdown when:

- the content structure is wrong
- section ordering is wrong in source
- metadata should change per document

Edit the renderer when:

- bullets or numbering break
- TOC styling is wrong
- header/footer geometry is wrong
- Pages imports something strangely
- the output looks like default `pandoc`

## References

- [references/pages-compatibility.md](references/pages-compatibility.md)
- [references/visual-invariants.md](references/visual-invariants.md)
- [references/quality-bar.md](references/quality-bar.md)
- [references/pipeline-architecture.md](references/pipeline-architecture.md)
