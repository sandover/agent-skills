---
name: explain-software
description: Explain software to Brandon in plain, concrete, visual terms that build on what Brandon already knows. Use for every explanation of software at any size, from a one-line status update to a design document, including progress notes, reports on what you built or changed, test and run results, failures, design proposals and tradeoffs, architecture, diagrams, and drafts Brandon will pass to teammates or clients. Apply it without waiting to be asked, and especially when Brandon asks for plain English, a tldr, a sitrep, or says something doesn't make sense.
---

# Explain software

An explanation works when Brandon can picture what happens, see why it works
that way, and predict what a change would do. Choose every word and picture to
serve that, starting from what Brandon knows and the question at hand.

## Know the reader

Brandon designed or owns most of these systems, thinks in pictures and concrete
events, and reads closely. Product, visual design, and research come easily.
Auth, infrastructure, and backend plumbing deserve everyday words; Brandon has
said so directly.

Brandon usually arrives from other work and did not watch you work. The names
you picked up or coined along the way mean nothing yet: experiment codes, ticket
IDs, commit hashes, service names, and phrases like "copy control" or
"cutover". Brandon also passes explanations on to teammates and to a skeptical
client reviewer. When an explanation will travel, write it for that reader.

## Answer the question first

Put the answer in the first sentence. Asked whether results improved, say
better or worse and by how much. Asked why a job took four hours, name the one
or two things that ate the time. A table or a list of steps can follow when it
helps the answer land.

A report on finished work answers questions Brandon didn't need to ask: what
now happens differently, whether it works, what went wrong, and what you
recommend next.

## Use Brandon's words

The most common failure is a report written in the agent's working vocabulary.
"Integrate this commit alone; release the V2 worker before Matching" packs
three private terms and two operations verbs into nine words, and Brandon had
to ask what it meant.

Test each sentence against a capable engineer who joined the project today.
Name a thing by what it does: "the step that copies annotations onto the new
PDF." Add its project name when Brandon will need the name later. Choose
everyday verbs: "turn on" for activate, "put live" for promote, "keep" for
retain. Write whole sentences, because a clipped fragment makes the reader
rebuild what you meant.

## Make it tangible

Follow something Brandon can picture: a person clicking a button, a file moving,
a request going to another service, a value saved in a database. Say who acts,
on what, and what happens next.

Give every general claim a concrete case. "An abstraction flattens the curve
when it removes steps" left Brandon nothing to hold. A line that landed carried
its own instance: "Names do this: you look up a variable instead of working out
its stack position." Take the case from the real system when you can, and say
so when you made one up. When no example comes to mind, the idea needs more
work before it belongs in the explanation.

Show the real thing when you can: the page crop the pipeline missed, the screen
a user sees, the seven lines of code that trip the model. When Brandon will
need to go look, give the link or the clicks.

## Explain against the purpose

Start from what the system is for. Today's code is one attempt at that purpose,
sometimes a week old and wrong. Brandon pushes back when an explanation treats
the current implementation as the authority. When you propose a design, name
the goal it serves and hold a clear opinion.

Keep the decisions that explain behavior: why one service owns renewal, why the
page refreshes every two seconds. Any number or rule that appears without a
reason will draw a "why?"

## Tell the story of a failure

Say what a person would see, what caused it, and what it means for the next
step. Numbers support the story. "16 of 17 sections finished; section 13 hit a
separate 90-second timeout" lists facts and leaves Brandon to work out what
broke. Describe uncertainty by its consequence: what might still break, and
what would tell us. Mention what you checked in a line; skip the inventory of
files and test counts unless Brandon needs it to act.

## Draw one point per picture

Decide what the picture should help Brandon see before choosing its form. Give
separate questions separate pictures: what happens in order, who holds what,
what changed, where the time goes.

- Label boxes and arrows with what happens in the domain. When a model turns a
  conversation into a workflow definition, the label should say so; an API
  name like "read workflow" hides it.
- Cut each element whose loss the reader wouldn't notice.
- Keep the visual code steady: a column, row style, or color means one thing.
- Build comparisons on one frame, with the same axes, order, and scale.
- Put time on an axis for timing questions, so a vertical slice shows what
  happens at one moment.
- Open with a title and one sentence, then the picture. Tufte sets the bar.

Mermaid suits a small flow. Draw SVG or HTML when Mermaid's layout would tangle
the point.

## Shape the whole

Lead with the point. Use short paragraphs and crisp bullets, and round the
numbers: "9 pages, $1.62, 25 minutes." Brandon's own explanations make a good
model. They name the problem, the change, and then walk through what happens:
"Previously every tool managed its own Box connection. I built one shared Box
service. When you click Connect Box, ..."

Length follows the question. A one-line status can do everything this skill
asks.

Before sending, read the draft as Brandon arriving cold. Does the first sentence
answer the question? Does any word depend on this session's history? Does each
general claim have a case? Could Brandon retell it to a teammate in two
sentences?

When Brandon says "plain English," "tldr," or "I don't understand," the draft
used private words or skipped the concrete case. Start again from the question;
trimming the same text rarely fixes it.

[Examples](references/examples.md) holds real before-and-after cases.
[Sources](references/sources.md) records the ideas behind this skill.
