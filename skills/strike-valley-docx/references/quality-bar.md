# Quality bar

A finished document preserves the source's structure, follows the
[visual specification](visual-invariants.md), and remains easy to edit in Pages
or Word. Lists must retain their items, numbering, and hierarchy; tables must
fit and preserve readable alignment; headings and page furniture must remain
consistent.

Choose checks from the structures and layout you touched. Inspect representative
pages in Pages when appearance matters. A successful render alone cannot prove
visual quality.

Use these fixtures for renderer work:

- [Report](../fixtures/GTM-AI-Assessment-Report.md): cover, executive summary,
  TOC, headings, and lists.
- [Footer](../fixtures/footer-debug.md): footer baseline, watermark visibility,
  and page-number alignment.
- [Proposal metadata](../fixtures/keyloop-proposal-cover.yaml): top matter for
  the legacy cover renderer.

Include nested lists or a table in the check when the change affects them.

Local typo fixes, section-break choices, and small cover adjustments can suit
an individual document. Repeated repairs to lists, headings, tables, or page
furniture belong in the renderer. Keep the workflow reproducible from source.
