# Pipeline architecture

The current Markdown workflow uses `scripts/render_branded_docx.py`, which
builds the document with `python-docx` and uses Pillow for image assets. The
renderer owns shared typography, page layout, and branding. Markdown supplies
content and structure; command-line arguments supply document metadata.

The renderer exports a sibling PDF through Pages unless the caller passes
`--no-pdf`. Pages also supplies the visual check for its own DOCX import behavior.
Keep the DOCX editable and preserve the Markdown for future revisions.

Place changes where they belong: content in Markdown, document-specific values
in render inputs, shared appearance and compatibility fixes in the renderer.
Use the [quality bar](quality-bar.md) and its fixtures to check the affected
output. Add another conversion stage only when a demonstrated document need
requires it.
