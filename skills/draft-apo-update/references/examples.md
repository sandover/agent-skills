# Posted APO Examples

Use these posted Claims Library updates to calibrate focus, granularity, and
voice. They are concrete project logs, not executive summaries or commit
changelogs. Their project vocabulary is illustrative only; derive vocabulary and
subject matter from the current project.

## Tuesday July 14

**Achievements** (Claims Library)

- Claims Library kickoff with pilot users
- UX improvements in Acrobat windows
- Added more structured testing for rectangle selection feature
- Created GitHub release page

**Priorities**

- Rectangle selection testing for Mac and Windows
- Interviews with pilot users

## Monday July 13

**Achievements** (Claims Library)

- Met and helped onboard first set of pilot users
- To make ongoing upgrades easier for these users, started work on Mac install
  script and Windows install wizard
- Planned fixes for a couple major issues flagged by pilot user Brian Doty
- Made progress ironing out issues in my Windows setup (32 bit vs 64 bit Acrobat)

**Priorities**

- Continue work on Mac and Windows install experience
- Pilot kickoff meeting tomorrow

## Friday July 10

**Achievements** (Claims Library)

- Created a more realistic automated test pass, based around real PDFs, so that
  we build confidence before releasing
- Started working on an issue where users could lose local comment text because
  it gets stomped by the server version. Will continue Monday.
- Set up Windows VM and installed a million things, closer to the goal of local
  Windows build and test
- Cleaned up Claims Library repo documentation

**Priorities**

- Working local Windows build and test
- Implement solution for how to better manage user edits to annotation comments
- Cut another release Monday morning

## Thursday July 9

**Achievements** (Claims Library)

- Shipped v1.0.0 build 15 dev 42dbb78
- Deployed new data model to dev server
- CLUI improvements to copy and design, deployed to dev server
- Hardened Acrobat export feature
- Baked a version number into Acrobat plugin
- Created a bug report feature in Acrobat plugin that links to a Google form
- Created new automated testing workflows so releasing becomes easier

**Priorities**

- Fix any issues that arise
- Update docs

## Calibration Notes

- Prefer `Created GitHub release page` to an inferred explanation about durable
  downloads.
- When a real deliverable is available, preserve a useful direct breadcrumb such
  as the GitHub release page, pull request, deployed application, or Google Doc.
  Add it to the relevant line; do not manufacture a citation pattern around it.
- Prefer `Made progress ironing out issues in my Windows setup` to excluding the
  work because it is unfinished or operational.
- Prefer `UX improvements in Acrobat windows` to enumerating viewport and layout
  implementation details.
- Include meetings when they represent kickoff, onboarding, interviews, decisions,
  or user feedback. Do not include routine attendance.
- Keep specific release, environment, feature, and user details when they make the
  progress recognizable to the team.

## Completion Boundary Example

On July 15, commits added Citation and Annotation editor APIs and shared forms,
but Ergo epic `7MFP4M` still had unfinished native right-click, locking, and
cutover tasks.

Too broad:

- Added direct editing of Citations and Annotations from their Acrobat comments

Accurate:

- Built the first pieces of direct Citation and Annotation editing: shared
  create/edit forms and safe save/delete APIs; native Acrobat integration remains
  in progress

Commit subjects can describe implementation-shaped work before the owning feature
is complete. Check the epic and report only the completed boundary.
