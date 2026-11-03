---
name: less-is-more
description: Keep front-end work spare, clear, and purposeful. Use whenever designing, building, revising, or reviewing interfaces, including websites, app screens, dashboards, charts and data pages, wireframes, interactions, and UI copy.
---

# Less is more

Adapted from Jakub Krehel's
[Less is more, more or less](https://jakub.kr/writing/less-is-more).

Agents make adding things cheap, so most pages fail by carrying too much.
Simplicity comes from understanding: once you know who uses the page, what
they came to do, and how often they do it, most removals become obvious. A
menu opened two hundred times a day should open instantly; an animation there
costs its user hours a year. Before you add an element, a line of copy, an
animation, or a dependency, ask whether it makes the outcome better for that
person. Keep the features, style, and scope the user asked for.

## Cut

- Open with the title and the content. Remove the stacked layers above it:
  eyebrows, provenance lines, headline cards, intro paragraphs, and summary
  blocks.
- Drop a section header that covers one item, and a border or card that
  separates nothing.
- Delete copy that repeats what the picture already shows. "Nearly three
  hours" next to a timeline adds nothing. So does a "What this shows" caption.
- Leave off implementation details this reader won't use. "That run came
  before Sol judgment" was noise on a page about timing. On a page built to
  compare models, the model name belongs.
- Put detail where it belongs. A small figure beside the row it describes beats
  a summary block above the chart. Fuller detail can wait behind a hover or a
  click.

## Write copy for the person

Read each label and sentence as the person in that situation, who knows only
what the screen has shown them. "Review another event" means nothing to a
study participant. A Copy button should say what it copies. Write friendly,
plain words, and stop when the person has what they need to act.

For flows, work out what the site knows and what the person knows at each
step, and make each screen claim only what the site knows then. Keep that
reasoning, and any test or preview controls, off the client-facing page.

## Keep it legible

Spare pages still need clear structure. A panel that opens over a list should
stand apart from it. A command should look different from the message beside
it. New elements should match the page's existing type, color, and spacing, or
they look tacked on. Reuse familiar patterns and existing components, and keep
the main path obvious. Use motion only to show a change or give feedback.

When a design falls flat, rethink the form before decorating it. Ask whether a
line needs to be a line at all. Aim for pages that feel precise and look good.
For charts, follow Tufte: label the data directly in place of a legend, and
drop gridlines, borders, and shading that carry no information.

## Build small

Choose the smallest readable implementation that does the job. Prefer system
fonts to loaded ones, plain HTML and CSS to a framework, and existing code to a
new dependency.

## Check the result

Look at the rendered page and click through the paths people will take. Check
that the copy matches what the page does. Then read the page once more, asking
of each element what the person would lose without it, and remove what fails.
Say what you didn't check before calling the work ready to share.
