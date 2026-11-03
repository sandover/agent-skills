# Examples

These cases come from real sessions where Brandon pushed back on an
explanation, and they span several kinds of work on purpose. Each shows the
draft that failed, why it failed, and a rewrite. Take the move each rewrite
makes and apply it to your own system; check its facts before you write.

## A status line in private words

Brandon asked: "what does 'Integrate this commit alone; release the V2 worker
before Matching' mean?"

> Implemented locally in commit `51d742b`. Adds one bounded crop retry per
> page, with strict checks after rereading. Retains model costs, including
> failed calls. Passes 82 focused checks. Not pushed or deployed. Integrate
> this commit alone; release the V2 worker before Matching.

Every sentence needs the session's history. "Bounded crop retry," "V2 worker,"
and "Matching" are working names; "integrate," "release," and "retain" are
operations verbs; nothing says what a user would notice.

> Some annotations failed to copy because a math sign, such as ≥, read
> differently on the old and new PDFs. Now, when a match fails only on a sign,
> the pipeline crops that spot on both pages and asks the model to read each
> crop again. It copies the annotation only if the new readings agree with
> everything else on the page. On page 26, this recovers the missing footnote,
> and it still refuses to copy when the new PDF changes "≥30" to ">30".
>
> It's one local commit; nothing is live. When we deploy, the page worker goes
> first. It has to know how to record what failed model calls cost before the
> matching service starts making them.

## Measurements without meaning

In a color-theme project, Brandon asked: "without jargon, tell me what we've
got here and why this set of colors."

> All twelve are six now. Most are roughly twice as separated as Solarized,
> with 55° of clearance around the ground instead of 36. Contrast unchanged at
> 4.71–4.77. Merges: errors + preprocessor share a colour, numbers + type
> names share another.

The numbers are accurate, and none of them says what Brandon would see on
screen.

> Each theme now uses six accent colors where Solarized uses eight. Fewer
> colors can sit farther apart, so two of them are harder to confuse: in most
> themes, the two most similar accents differ about twice as much as
> Solarized's closest pair. To get down to six, errors and preprocessor lines
> now share a color, and so do numbers and type names. Text is exactly as
> readable against the background as before.

## The heart of a long story

Brandon asked why a research job had run for four hours. The draft listed
every part of the job: the writing calls, the local scoring, the remaining
model calls at 18 seconds each, and the agent's own work. Brandon replied:
"from this description, i don't understand why it was four hours. give me the
heart of it."

> Most of the time went to the agent running the experiment. At its highest
> effort setting, it writes code, tests it, and reviews it between every step.
> The model calls added the rest: each took about 18 seconds, against 4 in
> earlier runs, because the command-line tool spends most of each call
> starting up.

Name the one or two causes that ate the time, then stop. The full accounting
can follow if Brandon asks.

## A principle with nothing to hold

In a research project, Brandon said: "this is abstract, let's bring this back
down to earth."

> An abstraction flattens the curve when it removes steps, but only if what's
> left is something the model can do reliably.

> When a notation lets the model take one step where it used to take many, the
> model stops getting worse as the problem grows. With named building blocks,
> the model changed a drawing with one edit in place of sixteen coordinate
> edits, and its accuracy held as the drawings got bigger. The one remaining
> step still has to be easy for that model. A small model given the even/odd
> shortcut had to find one even number in a long product, and it missed
> unless that number sat near the end.

## Numbers in place of the story

Brandon asked: "you haven't explained the failure in plain language, why not?"

> **The tall-page test did not pass.** Time: 6 minutes 18 seconds. Result: 16
> of 17 sections finished. Section 13 hit a separate 90-second timeout. The
> worker stayed connected beyond the old five-minute limit, so that fix worked.

> The tall page still fails, for a new reason. The pipeline cuts a tall page
> into 17 strips and sends each to the model. Sixteen came back. Strip 13 took
> longer than the 90 seconds we allow one model call, so the page never got a
> complete result. The fix we were testing works: the worker now stays
> connected past the old five-minute limit. Next I'd find out why strip 13 is
> slow before raising the limit.

## Diagram labels that hide what happens

A sequence diagram showed a person describing a business process to a chat
model, which then sent "Read workflow" to a server. Brandon asked why
"describe a process" became "read workflow," and said what happens: the model
turns the person's description into a formal workflow, which the server saves
as a definition. The arrow labels should tell that story: "describes the
process," "turns the description into a workflow definition," "checks and
saves the definition." The same review removed a browser page and a storage
box that added nothing to the point.

## Reporting a change: shared Box access

Brandon explained this change aloud before anyone wrote it down. It shows the
order to follow: the problem, the change, then what happens.

> Each tool used to keep its own Box connection, and none of them held on to
> your permission well. Now one shared service keeps your Box connection, and
> the tools ask it to fetch files for you.
>
> When you click Connect Box and approve access, the service trades Box's
> approval code for two keys: one to make requests, and one to get a fresh key
> later. It saves them, encrypted, under your identity. When Review needs a
> file, it asks the service, which fetches the file with your keys.
>
> Launcher and Review never receive your Box keys. The shared service keeps
> them and uses them when it contacts Box. So one place handles renewal, and
> the tools share your connection without each holding its own.

A picture for this explanation should show where the keys stay. Arrows mean
requests; the picture leaves out the approval flow and the returning file.

```mermaid
flowchart LR
    T["Launcher or Review"] -->|"Fetch this file for Brandon"| S["Shared Box service<br/>Keeps Brandon's keys"]
    S -->|"Uses Brandon's saved access"| B["Box"]
```

Renewal deserves its own explanation and its own picture. Box's renewal key
works once, so if two requests try to renew at the same moment, one fails. The
service marks renewal as underway in the saved record before it calls Box, and
other requests wait for the new key.

## A small fix

> The editor cleared your draft as soon as it sent the save. Now it clears the
> draft after the server confirms the save. If the save fails, your text stays
> in the editor so you can try again.

Three sentences give the trigger, the change, and what you'd notice. A diagram
would add nothing.
