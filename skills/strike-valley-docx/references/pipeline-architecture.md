# Pipeline Architecture

## Goal

Turn Markdown into polished, editable Strike Valley Studio `.docx` documents with minimal manual cleanup.

## Preferred v1 pipeline

1. Author in Markdown with stable heading and list structure.
2. Convert Markdown to `.docx` with `pandoc`, using a branded `reference.docx`.
3. Post-process the `.docx` with Python code under `uv` when `pandoc` alone is not enough.
4. Open in Pages or Word only for spot checks and rare judgment calls, not routine formatting.

## Why this is the preferred v1

- Keeps Markdown as the source of truth.
- Produces editable `.docx`, not a dead-end PDF.
- Avoids LibreOffice.
- Pushes recurring formatting rules into a reusable template.
- Gives a clean path to later automation for branding, TOC, page numbers, and metadata.

## When to move beyond `pandoc`

Use post-processing or a template-first generator when any of these happen:

- Lists come through incorrectly.
- Tables lose intended structure.
- Headers/footers/page numbers need repeatable branding.
- The first page or section openers require consultancy-specific layout.
- Manual cleanup in Pages takes more than a few minutes.

## Likely v1 components

- `assets/reference.docx`
- `assets/logo.*`
- `scripts/render_markdown_docx.py`
- optional `scripts/postprocess_docx.py`

## Likely v2 components

- frontmatter-driven document metadata
- optional table of contents insertion
- cover-page variants
- proposal/report/memo presets
- stronger structural validation for lists, tables, and heading hierarchy
