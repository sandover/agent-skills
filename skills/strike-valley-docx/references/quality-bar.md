# Quality Bar

Do not call the output good enough if any of these are true:

- Bullet lists flatten, split, or require hand-fixing item by item.
- Numbered lists restart incorrectly or lose hierarchy.
- Heading styles are generic or inconsistent.
- Tables overflow, collapse, or lose alignment.
- Page numbers, header/footer, or logo placement look accidental.
- The document still looks like default `pandoc`.

## Acceptable manual cleanup

- typo fixes
- one-off judgment calls on section breaks
- small cover-page tweaks

## Unacceptable manual cleanup

- fixing every bullet
- redoing heading styles paragraph by paragraph
- reformatting all tables by hand
- rebuilding page furniture manually
- restyling every exported document from scratch

## Visual targets

- body font and heading font follow the template exactly
- branded page furniture is present and unobtrusive
- spacing feels intentional and consultancy-grade
- TOC, when enabled, is structurally correct
- the document remains easy to edit in Pages or Word

## Test fixtures to keep using

- a report with many nested bullets
- a document with a table of contents
- a report with multiple heading levels
- a document with at least one table
- a proposal-style document with a custom first page
