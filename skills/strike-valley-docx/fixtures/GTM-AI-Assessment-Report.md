# GTM AI Assessment: Keyloop CRO Organization

Prepared for Megan Harvey, Chief Revenue Officer, and leadership team.

by: Brandon Harvey, Strike Valley Studio


---

## Executive Summary

We spoke with 16 people across the CRO organization, from individual sellers to the CIO, to understand where AI could benefit Keyloop's sales operations in the short and medium term.

The interviews painted a consistent picture: sellers spend hours per week on post-meeting admin, enter the same data into three or four systems per deal, and lose customers in the gap between "yes" and paperwork. The quoting process alone adds weeks to deal cycles. One team starts building quotes a full month before they need them. Sellers have lost deals because the business couldn't produce documents fast enough.

AI can help with some of this, and there is meaningful progress to be made within a quarter, without waiting for a new data foundation.

**We recommend two near-term projects:**

1. **Customer encounter support**: AI-assisted meeting prep, capture, and follow-up. This is the broadest source of admin overhead in the CRO org, and some working prototype material already exists.
2. **Quoting support**: assistive tooling that helps sellers assemble accurate quote inputs faster and reduces the correction cycles that slow every deal. We found some prototyping in this direction as well.

**But to make these work, the organization needs three enablers:**

- **Copilot Premium rollout** across the CRO org (~£240/user/year). This gates almost any effective use of AI.
- **Practical AI capability-building**: hands-on sessions for leaders and the wider org, plus lightweight structure so grassroots innovation can spread.
- **A focused review of data permissions** so AI tools can reach the knowledge people need, not just a user's own documents.

Clarity on Claude access policy is also needed, to resolve the perception of unfairness and bring support and enthusiam to the small cohort who are pathbreaking or doing particularly sophisticated manipulation of data and documents.

**Six specific leadership decisions** are required to move forward. They are detailed at the end of this report.

None of this requires waiting for Kilimanjaro or a new data foundation. Longer-term data and systems work and de-siloing still matters, and will unlock further AI opportunities, but it is not a prerequisite for starting.

Getting full value from AI also means understanding how it differs from a normal technology rollout. The next section covers three properties that shaped this report's recommendations.

---

## How is AI different?

We believe that deploying AI requires a very different playbook from a conventional technology rollout. Three AI factors matter most for Keyloop.

### 1. AI is fast

The AI landscape today looks very different than it did twelve months ago, and in twelve months time we can expect it to look even more different, because AI will begin affecting knowledge work more directly, not just coding.

Therefore a project that takes a year to build risks irrelevance. We should prefer quick-win, fail-fast initiatives over long programs. We want lightweight tools that can evolve rather than large systems designed to be permanent fixtures.

### 2. AI is fraught

Nobody lay awake at night wondering whether Salesforce would take their job. AI is different. Many people don't feel that they understand it; many people don't feel they are "keeping up". There are moral questions — is using AI "cheating"? People want psychological safety, and they want meaning in their work, and AI prompts the question of whether these will be taken away.

Keyloop can be on the right side of this narrative and excite its people with AI by *assisting and augmenting* them. Everyone I spoke with was able to name examples of capable Keyloop people wasting their time doing work that is not core to their mission or role — often work that shouldn't need a human at all. AI is how people get back that time. There is a clear, credible message to send here.

### 3. AI requires participation, not just adoption

Enterprise technology is generally centralized: IT selects a platform, configures it, rolls it out. That works for CRM and ERP, where value comes from standardization and consistency. AI, on the other hand, gives unusually wide scope to the individual worker, and its low barrier to entry means people closest to the work can act on opportunities without waiting for a central plan.

But that only happens if people engage actively — noticing where time is being wasted, experimenting, evaluating outputs critically. The grassroots adoption already happening at Keyloop shows that this happens organically. The opportunity for the organization is to support and extend that behavior, and capitalize on the value creation it implies.

**The organization may not know in advance where AI creates the most value.** This report recommends two near-term initiatives based on what the interviews turned up. But the interviews also turned up proof points nobody predicted: a dealer-data matching tool, a pipeline triage agent, an RFP analyzer. These were not planned centrally. They were built by individuals who saw an opportunity in their own work and acted on it. If the next high-value use case follows the same pattern, it will come from someone at the edge, not from a steering committee. That means the organization needs a way to hear about it, a way to adopt the best ideas, and a clear signal that this kind of initiative matters.

---

## Organizational Findings

This section shares findings about the organizational challenges which either put a limit on what AI can accomplish, or present opportunities for AI to help.

This report draws on structured interviews with 16 people across the CRO organization and adjacent functions (see appendix for the full list). The approach was qualitative by design: understanding how work actually happens day to day, told by the people doing it, surfaces problems that dashboards and audits tend to miss. Findings are ordered from root cause through consequences. The first explains why most of the others exist.
### Fragmented data, inconsistent governance

The interviews turned up two distinct data challenges that tend to get bundled together but require different responses.

**Data fragmentation** — the data exists, but it's dispersed. For example, Zara Wells cannot determine a customer's ARR from the CRM because invoicing runs through two separate systems. Richard Johnston's strategy team had to scrape every manufacturer website globally to build a dealer dataset because internal data from eight acquisitions couldn't provide it. Kate Whiting enters the same information into three or four different systems across a single deal lifecycle. The data is out there somewhere — the problem is that no one system holds it.

**Data governance** — the data isn't captured at all, or isn't captured consistently. CRM activity logging has no standards — what gets logged might simply be "I visited the customer". Critical commercial terms sometimes survive as undocumented agreements — handshake deals from years ago. Meeting notes may live in handwritten notebooks, a few lines in Keyforce, or separate Word documents.

**People patch both problems with their own time.** Declan Irwin's team tracks deals in a canonical OneDrive spreadsheet. Zara's team maintains their own customer data spreadsheet. Richard manages 157 sales plays in a personal spreadsheet. Kate navigates by mental model of which system to enter data into when. People have resorted to emailing customers to ask whether Keyloop's own records are correct — meaning the data problem is visible to customers at the moment the AM team is trying to build trust. Richard described his team's operating mode as "hacking together order from chaos." When multiple teams at different levels independently build parallel tracking outside the official systems, that is itself a finding.

Kilimanjaro addresses *some* sources of fragmentation — consolidating CRMs so that data lives in fewer places. But governance is a broader question: what gets captured, how consistently, and to what standard. Both problems showed up in nearly every interview.

### The quoting bottleneck

Data issues compound when you look at how a deal actually moves through the organization. The selling process spans multiple systems with multiple handoffs, and sellers spend much of their time on internal logistics rather than customer-facing work.

Kate Whiting gave the clearest end-to-end walkthrough we heard. The sequence, for a single enterprise deal:

- Discovery meeting happens. She logs notes in Keyforce, updates opportunity status, adds next steps, maintains close plans. Much of this feels like management-visibility work rather than seller-value work.
- Raises a ticket with the pre-sales team. **2–3 working days** before someone acknowledges it.
- Someone is assigned. **1+ week** from discovery to first technical engagement.
- Needs PS involvement. Submits a request in a different system with outdated dropdowns and stale customer records. Has to attach a document duplicating information she's already entered. PS won't look at it otherwise.
- PS takes **1-3 weeks** to produce a solution.
- SoW comes back as boilerplate — and it's not returned in the same system as the request. It gets uploaded to SharePoint; she has to search by R number to find it.
- Raises a quote — another ticket in Keyforce. She has no access to a product catalog, doesn't know what licenses are needed. Has to call someone.
- Quote comes back after **a day or longer**. If she doesn't review within **48 hours**, the ticket auto-closes.
- She has lost deals because of this process.

She enters the same information into three or four different systems across this lifecycle. If this is what the process looks like for a top performer on large strategic deals, it is likely worse for everyone else.

Quoting in particular came up in nearly every interview. It is the bottleneck with the clearest connection to lost revenue.

- Mohamad Al Nabulsi described engineering estimates that take two weeks, arrive padded by roughly 30% as a negotiation buffer, and get renegotiated later — "depends on the mood of the consultant."
- Toby Hughes described looking up 172 site IDs and product codes manually for a single large quote. His team now starts the quoting process a full month before they need the output, because quote requests come back with corrections and clarifications.
- Graham Stokes described deals where a customer says yes and then the business takes 4–5 days to produce the paperwork — and in that window, the customer can change their mind.
- Kate gave another example: a generic DMS quote for a single site (a deal worth roughly £40K) came back with 42 line items, including components she didn't know she needed: HIP, postcodes, Keyloop Message WhatsApp, VPN, remote access. Her reaction: "Selecting the main product should automatically pull the required dependencies underneath it." In some cases, customers are being asked to accept documents everyone knows contain errors, because the quote format can't be easily edited. That is a governance risk.
- Ed Binns and Jason Clifton described something nobody else mentioned: a back-end validation gap. Quotes can move through the process and reach the customer without anyone checking whether they match what was actually requested.

### Sellers eat the cost of fragmentation

Kate's walkthrough shows the selling process, but it also shows how much time sellers spend on internal logistics. She chased pre-sales, professional services, sales ops, AWS, and the quote team across separate ticket systems for a single deal. That pattern repeated across interviews.

- Toby described internal chasing (across delivery, support, engineering, and quoting) as the lowest-value work in his week.
- Sarah Alexander noted that sellers absorb marketing admin that should never reach them: manually updating campaign spreadsheets, emailing invoices from personal mailboxes.

Separately from the sales process overhead, sellers in some regions carry a significant customer support burden. Graham Stokes described the structural reason: under the old geographic model, a local managing director had PS, product, engineering, and support all under one structure, and a seller could escalate locally and get action. Under the current functional model, those resources are organized globally, but customers still treat the seller as their route into the company. Unhappy customers won't buy more, so sellers get dragged into support by necessity.

Graham described this as especially acute in Europe, where sellers act partly as sales, partly CSM, partly account manager, partly support lead, without control over any of the underlying functions. He noted some progress in the UK through forcing other teams to show up on customer calls, but said that's harder to make happen in Europe. Sarah described the same dynamic from the enablement side: sellers are often trying to run sales conversations while customers only want to talk about support issues.

A related pattern came up repeatedly: the "who knows about X?" problem. Given an incoming customer issue, people need to know which person at Keyloop handles that domain, and whether the question has been answered before. This is a different problem than data fragmentation — it's the absence of an expertise directory and an institutional answer bank.

### Red tape around the customer conversation

The face-to-face encounter with a customer is the core unit of commercial value. What happens before it should make it better. What happens after it should effectively harvest its value.

**Before the meeting,** preparation materials exist, but they may not fit the work or they may not be used consistently. Declan alluded to a 45-page list of questions sellers are supposed to ask during discovery. Tantia described engagement planning forms that sellers treat as a tick-box exercise rather than genuine preparation. Sarah Alexander noted that not every seller is even doing basic research before meetings today.

**During the meeting,** people capture what they can: handwritten notebooks, a couple of lines in Keyforce, separate Word documents. This variation is natural, because the customer encounter can vary. But it does mean that sellers generally have to re-enter and re-format information.

**After the meeting** is where the time goes. A seller has to produce internal notes for the CRM, a customer-facing follow-up email, and action items, plus the system bookkeeping: update opportunity status, add next steps, date-stamp updates, maintain close plans, re-upload close plans. If follow-up from a customer meeting takes 30-60 minutes (which seems typical), the company is spending very substantial seller time on post-meeting admin.

The company needs this data, and the earlier findings on data governance show what happens when things aren't captured. But the process as it stands may serve management visibility better than it serves selling.

This comes through in comments about Salesloft: "great for manager visibility, doesn't serve the seller." The work that would actually make the next interaction better gets crowded out by the reporting.

### Trapped knowledge

Keyloop has approximately 4,000+ possible product configurations for a given customer scenario, with no tool to navigate them. The SKU (stock-keeping unit) price list runs to 35,000 items. Product data lives in too many places, in multiple versions, and newer sellers don't yet have the mental map of "customer asks for X, therefore they need X, Y, and Z." Ramping sellers into automotive domain knowledge came up repeatedly as a management concern.

Keyloop built a customer-facing AI chatbot (Kara) that surfaces answers for customers, but sellers and account managers have nothing similar for internal use. The company invested in customer self-service before employee self-service.

### Quantifying organizational friction

This report is based on interviews, not a formal time-and-motion study. But specific numbers came up often enough to make the scale of these problems tangible.

**Meeting and customer interaction overhead:**
- **Around 10 customer meetings per week needing follow-up for a single seller.** Toby Hughes described roughly 10 customer meetings per week that each require some kind of follow-up: notes, CRM updates, customer emails, and action items.
		- *Business impact:* Seller capacity going to admin rather than customers. At scale, this is probably the biggest single source of wasted time in the CRO org.
- **Five distinct outputs from every customer interaction.** Ed Binns and Jason Clifton described what a single meeting should produce: internal notes, customer-safe notes, a follow-up email, suggested next steps, and action items. Today each is created manually.
	- *Business impact:* When follow-up is slow, momentum stalls. When capture is incomplete, the next interaction starts without context.
- **5–6 hours of internal meetings for a single pitch.** Toby described 12 people spending half a day coordinating internally for one customer engagement.
	- *Business impact:* Internal coordination cost that scales with deal complexity, taking time away from more deals or deeper preparation.

**Quoting and deal logistics:**
- **A month of lead time for quoting.** Toby described starting quote creation a month before expected signature because of iteration and rework.
	- *Business impact:* Extends deal cycles by weeks. Forces sellers to manage timelines around internal process rather than customer readiness.
- **4–5 days from "yes" to paperwork.** Graham Stokes described customers saying yes and then waiting nearly a week for the business to produce the documents — a window in which they can change their mind.
	- *Business impact:* Direct risk of lost deals. A customer who has said yes and then waits is a customer who can reconsider.
- **42 line items on a single-site £40K quote.** Kate's example: a straightforward DMS deal came back with components she didn't know she needed.
	- *Business impact:* Sellers can't confidently scope or explain their own quotes, and errors reach customers.
- **172 site IDs looked up manually for one large quote.** Toby described an hour of pure clerical admin just to assemble the input.
	- *Business impact:* High-value sellers doing data-entry work. That time comes directly out of selling.

**Knowledge access and fragmentation:**
- **35,000 SKUs and thousands of possible product combinations** with no navigable tool. Newer sellers have no way to learn what "customer asks for X" actually requires.
		- *Business impact:* Slower ramp for new sellers. Experienced sellers become bottlenecks because they hold product knowledge others can't access.
- **A week and a half of manual work to map the installed base.** Richard Johnston described the effort just to determine how many dealers sit on which DMS — basic strategic data that should be queryable.
	- *Business impact:* Strategic planning blocked by data assembly. Decisions get made on incomplete information, or don't get made.
- **3–4 systems touched across a single deal.** Kate described entering the same information repeatedly across separate systems and tickets.
	- *Business impact:* Redundant data entry introduces errors. Each re-entry is a chance for information to drift.
- **Support tickets raised for problems solved months earlier.** Multiple interviewees described the absence of institutional memory — the same questions get asked and re-answered because prior answers aren't searchable.
	- *Business impact:* Wasted support capacity. The knowledge exists inside Keyloop, but nobody can find it when they need it.

These numbers point to the same conclusion: the current operating model imposes hours of administrative drag per person per week and, in some cases, weeks of delay inside active deal cycles. Most of this is repetitive, structured work, which is where AI tends to help most.

---

## AI Findings

### Grassroots AI adoption

We did not find an organization that needs to be convinced AI can help. We found an organization where people are already using AI, in a dispersed way.

Across the CRO org, AI is already being used to:

- generate structured qualification summaries, customer presentation narratives, and meeting prep packs, in daily use by one team (Declan Irwin, Copilot + Claude)
- surface the 20 opportunities that matter out of 2,000 in a pipeline (Graham Stokes, Copilot + Claude)
- scrape and match dealer data at higher accuracy than a paid consultancy (Brian O'Mahony, Claude)
- analyze RFPs and tenders against internal capability docs to identify gaps (Kate Whiting, Claude + ChatGPT)
- assemble package pricing and product codes from site count and configuration inputs, via a vibe-coded tool now available to sales in Seismic (Mina Korhonen)
- match a 750K dealer dataset against the customer base for targeting recommendations (Chris Laird, Claude)
- build product correlation models for cross-sell (MJ)

There is also a Claude-based internal assistant (Ask Keyloop) already deployed and connected to SharePoint, Outlook, Teams, Jira/Confluence, Miro, and Asana, though not yet to Keyforce or live account data.

This is all happening at the grassroots, which is to be expected. AI is flexible enough that individuals can act on opportunities without waiting for a central build.

The AI Center of Excellence, which might coordinate these efforts, is focused on product engineering, leaving business-side adoption without an obvious governance home.

### Uneven AI access

AI access at Keyloop falls into tiers:

- **Claude and Claude Code** (~£480/user/year, requires approval and cross-charge): Currently required for richer data analysis work, strongest models, and coding. Access to this is limited and uneven (e.g. Kate has it, other sellers don't), and there is a risk of perception of unfairness.
- **Copilot Premium**: Based on recent (though not necessarily current) ChatGPT models. Not fully rolled out. Access to Claude models is apparently coming to this tier.
- **Standard Copilot** (~£240/user/year): the organizational default. Basic AI features, but not the ones that unlock the most value. Much of the CRO org sits here. Half of Declan's team cannot use the agents he built because they lack the right licenses.
- **Shadow tier**: people paying out of their own pocket for AI tools, with no governance, no integration, and no organizational support.

Our understanding is that the IT recommendation to the executive leadership team is Copilot Premium universally, Claude selectively. That decision has not yet been ratified.

### Key Constraints

On the Microsoft side, IT has a permissive posture. The tools to build custom agents, automate workflows, and connect AI to internal knowledge sources are available today. Teams meeting recaps can already be customized to produce different outputs for internal and external use. One caveat: the M365 permissions model defaults to closed, which means Copilot can only draw on content a user already has access to. Zara Wells flagged this — in practice, Copilot can see less than people assume.

On the Salesforce side, the picture is different. Copilot for Sales is licensed but cannot be deployed until the new Salesforce instance (Kilimanjaro) is live. The Salesforce admin team is currently focused on that migration. Any AI work that requires live deal, account, or pipeline data from Keyforce depends on coordination with that team and, in some cases, on Kilimanjaro itself. Kate described wanting Ask Keyloop connected to Keyforce so she could pull live account data; Tim confirmed that connection does not exist today.

IT is willing to support AI work but needs two things it currently lacks: business stakeholders to define requirements and validate outputs, and bandwidth. There is no formal experimentation pipeline. Teams informally "take and run with it." The constraint is people, not technology or policy.

---

## Opportunities

### How we evaluated

The findings point to various places where AI could help. To decide where to focus, we created an evaluation framework with four attributes:

1. **Needed.** Does this serve the people doing the work? Will they want to use it, or will it feel like another obligation? The findings are clear that tools perceived as management visibility rather than contributor value get ignored or resented. We prioritized opportunities where adoption should be enthusiastic, not enforced.
2. **Feasible.** Do we have a buildable idea? Finding proof points at the grass roots, as we did, points to lower risk. A recommendation grounded in Declan's working agents or Mina's quote tool is a different bet from one that starts from scratch.
3. **Bounded.** The AI landscape is changing fast enough that long-horizon investments are riskier. The right tool in twelve months may not be the right tool today. We also want visible impact soon, both to build credibility and to learn from real usage. If it can't show results in a quarter, it's either too large or too dependent on other work.
4. **Measurable.** Can we tell if it worked? Time saved, deals accelerated, adoption rates, data quality improvements. If we can't define what success looks like before we start, we shouldn't start.

### Problems to solve now

Based on this framework, two problems stand out as the best near-term targets:

- **The overhead around customer interactions.** Preparation, capture, follow-up, and system bookkeeping take up significant time across the CRO org — and the outputs often serve management visibility more than the work itself. This is the problem felt most broadly across the interviews, it has a working proof of concept, and the results would be immediately visible.
- **Quoting friction.** The most consistently cited connection to lost revenue. Sellers lose deals not because customers say no, but because the company takes too long to produce the paperwork. Product complexity makes it worse: 35,000 SKUs, no accessible catalog, dependencies sellers don't know about until the quote bounces back.

We also see a set of organizational "enablers" that are required in order for these solutions to succeed. Those will be detailed below.

### Problems to solve later

The recommendations in this report are scoped to what Keyloop can start this quarter. But the interviews surfaced several high-value problems that are not yet ready for AI investment — they depend on the data foundation that Kilimanjaro and related cleanup work will provide. These represent a natural second phase of AI-driven improvement. Each would benefit from the same kind of structured assessment (interviews, workflow mapping, feasibility analysis) once the underlying data is in place.

- **Pipeline and forecasting intelligence.** High value, but depends on clean deal data that doesn't yet exist in unified form. Once Kilimanjaro consolidates the CRM landscape and structured meeting capture begins producing better upstream signals, AI can help distinguish real from aspirational pipeline, surface qualification gaps earlier, and improve forecast inspection for managers.
- **Account health monitoring and proactive churn detection.** Zara's team described the problem clearly: revenue erosion invisible until too late. This requires the longitudinal account data that the data foundation work will eventually provide. With cleaner account, invoicing, product, and support data, AI could identify declining accounts earlier and help prioritize interventions.
- **A richer internal assistant connected to live commercial data.** Ask Keyloop is already useful on the knowledge side, but it is not connected to Keyforce or live account and opportunity records. A future version connected to live commercial data would be far more useful for sellers, AMs, and leaders.
- **Full quote and scope automation.** The quoting problem is real, but a full configure-price-quote (CPQ) platform is a large systems project, not a quarter-length AI initiative. Our near-term recommendation scopes to what's achievable now with lighter tooling. A fuller CPQ capability becomes more realistic once product, pricing, entitlement, customer, and site data are more consistently connected.
- **CRM enforcement and compliance tooling.** Addressing symptoms rather than causes, and likely to face the adoption resistance the interviews warned about.

---

## Recommendations

This section describes the recommended initiatives in more depth. It also details the  "enablers" which make those initiatives usable and adoptable.

### Recommended initiatives

#### 1. Customer encounter support

**What this is:**
- AI support for the customer meeting lifecycle: prep, capture, follow-up, and next-step creation
- Start with Teams recap outputs and Copilot Studio (Microsoft's platform for building custom AI agents) workflows; layer in a more structured front-end if needed
- Build on Declan Irwin's existing work rather than starting from scratch

**Why this matters:**
- Prep, capture, follow-up, and system bookkeeping are one of the broadest sources of admin overhead in the CRO org
- Sellers re-enter the same information across systems, and post-meeting work often serves reporting more than selling
- Better structured outputs improve CRM hygiene and create better downstream data without waiting for a new foundation

**What it should do:**
- Generate pre-meeting briefs using available account context
- Produce internal notes, customer-safe follow-up, and action items from the same interaction
- Suggest next steps and help prepare for the next meeting
- Degrade gracefully when recording is not possible

**What success looks like:**
- People spend less time on post-meeting admin
- Follow-up happens faster
- CRM data quality improves (structured inputs, not freeform)
- Preparation for the next meeting draws on what was captured in the last one

**How we'd measure it:**
- Time from meeting end to follow-up sent
- CRM note completeness (structured fields populated vs. blank)
- Self-reported time on post-meeting admin, before and after
- Voluntary adoption rate

**Champions:**
- Declan Irwin — already built working agents for qualification summaries, customer narratives, and preparation packs, plus a full prompt library and structured front-end prototype. His team is the natural pilot.
- Toby Hughes — quantified the pain (10 meetings/week, 30-60 min follow-up each). Strong early adopter.
- Tantia Kruger — independently described the same concept from the management side.

**Near term scope guard rails:**
- Keep the first version contributor-first, not manager-first
- Avoid hard workflow enforcement or scripted selling
- Accept manual CRM entry in the near term where system write-back is blocked

**What to avoid:**
The most common failure mode for tools like this is optimizing for capture rather than for the seller. If the tool's primary effect is producing more data for management dashboards, people will treat it the way they treat Salesloft: "great for manager visibility, doesn't serve the seller." The first version needs to make the seller's next interaction better, not just the manager's next pipeline review.

**Technologies to explore:**
- Teams meeting recaps — already customizable for internal vs. customer-facing summaries, available now to Copilot Premium users, no build required
- Copilot Studio agents — can be configured with MEDDIC (a structured deal-qualification framework) criteria, sales process knowledge, and Keyloop's product landscape for richer outputs
- Structured mini-site — like Declan's HTML prototype, may be more effective than a chat interface for people following a staged process
- These approaches are not mutually exclusive and can layer up over time

#### 2. Quoting support

**What this is:**
- Assistive quoting support, not full CPQ
- A lighter layer that helps sellers assemble better quote inputs faster and reduces avoidable bounce-backs
- Scoped to common configurations and exported reference data this quarter

**Why this matters:**
- Quoting is the clearest drag on revenue that came up in the interviews
- Sellers lose time to clerical work, dependency lookup, and repeated correction cycles
- Product complexity and hidden dependencies make first-pass accuracy too low

**What it should do this quarter:**
- Provide configuration guidance for common scenarios
- Assemble quote briefs from natural-language inputs plus exported reference data
- Validate likely missing dependencies before submission
- Compare what was requested with what is about to be sent to the customer

**What success looks like:**
- Quote briefs accepted on first submission more often
- Time from "customer says yes" to "quote in front of them" drops measurably
- Sellers stop starting quotes a month early
- Fewer deals lost to internal delays

**How we'd measure it:**
- Quote turnaround time
- First-submission acceptance rate (vs. bounce-backs)
- Seller-reported confidence assembling a complete brief
- Deals where quoting delay was flagged as a factor

**Champions:**
- Mina Korhonen — already built a working tool that takes country, tier, site count, and technician numbers and returns the right packages with catalog codes and prices. It replaced a set of per-currency PowerPoint cheat sheets and is already available to sales via Seismic.
- Brian O'Mahony — owns the quoting operation centrally, has CPQ on his roadmap
- Toby Hughes — described the pain most concretely (172 site IDs looked up manually for a single quote)

**Near-term feasibility boundary:**
- Scope to the most common configurations first, using exported catalog, pricing, and rules documents rather than waiting for live Salesforce or Keyforce integration
- Use AI to help assemble quote briefs, surface likely dependencies, and validate outputs before submission
- Treat customer/site lookup and final system entry as manual or semi-manual where necessary
- Do not position this as a replacement for CPQ or as a full rewrite of the quote workflow this quarter

**What to avoid:**
A quoting tool that gives wrong answers is worse than no tool at all. If sellers learn they can't trust the output, they stop using it and tell everyone else to stop too. The first version should cover the most common configurations accurately and be explicit about what it doesn't handle. Partial coverage with high reliability beats broad coverage that's unreliable.

**Technologies to explore:**
- Copilot Studio agent or similar M365-based tool grounded in exported product catalog and pricing data, with bundling logic encoded from experienced sellers and quote analysts
- Decision-tree capability: user describes the scenario, tool returns likely components with correct product codes
- Lightweight validation layer comparing what was requested with what is about to be sent to the customer

### Enablers

#### 3. AI capability building and grassroots support

**The goal.** Raise AI fluency across the CRO org, and create lightweight structure around the grassroots innovation that is already happening so it can spread, sustain, and graduate into supported infrastructure.

**Capability building:**
- Hands-on leadership sessions where participants work with AI on their own data and their own problems
- Practical CRO workshops focused on useful inputs, output review, iteration, and approved-tool guidance
- Regional tailoring where product mix, role design, and sales cycle differ

**Supporting innovation at the edge:**

The interviews turned up proof points that nobody planned centrally: Declan's encounter agents, Mina's quote tool, Brian's dealer-data work, Graham's pipeline triage, Kate's RFP analysis. Each was built by someone who noticed a problem in their own work and decided to fix it. The organization's job is not to plan the next wave. It's to make it easy for these things to emerge and spread.

What this should look like:
- **A regular show-and-tell.** Every two weeks, 30 minutes, with 1-3 short demos per session. If there aren't enough demos, use as a recipe-swapping session (which, for managers, is actually a listening and learning session). Keep the production value low and informality high: screen-share and talk, no slides. Record and distribute consistently. Local experiments (even when they fail) will be a strong way to identify new opportunities and process gaps. We want to see the failures as well as the successes, which makes informality and a high trust level crucial. Running this session successfully is a matter of good social engineering.
	- Assigned: a good emcee, and 2+ high approachable senior managers who agree to be present each time (and to sometimes demo themselves)
- **A shared channel** in Teams for people building with AI. Open to anyone. The important thing is that ideas posted there actually get responses: "we're trying this," "talk to X, who's already on it," or "not now, because Y." If people post and hear nothing back, they stop posting.
	- Assigned: a channel owner / moderator / facilitator / host
- **A lightweight adoption path.** Not every grassroots tool needs to become an official project. But for the ones that do, the path should feel like a reward, not a bureaucratic gauntlet. Mina Korhonen's quoting tool is a live example: she built it, got it into Seismic so sales can use it, and is now stuck on a platform limitation (Seismic can't generate PDFs). She's between "team sharing" and "cross-team adoption" and needs IT consultation to get to the next step. That's exactly the kind of moment this path is designed for.
	- *Personal use* — anyone can build anything for themselves within approved tools. No approval needed. Encouraged.
	- *Team sharing* — builder shares with their team. Manager is aware. Tool is added to a shared registry so the champion network can see it.
	- *Cross-team adoption* — multiple teams want it. A lightweight review: does it work reliably, does it handle data appropriately, is it documented enough for someone else to maintain? IT provides a consultation, not a gate.
	- *Org-supported* — IT takes co-ownership. The tool gets a proper environment, monitoring, and support. The builder becomes a stakeholder, not the sole maintainer.
- **Recognition, not cash.** PwC, Lloyds Banking Group, and GitHub have all run versions of this. What sustains participation is not money. It's public recognition from leadership, access to better tools for people who've earned it, and development opportunities like presenting or being consulted on product decisions. Keyloop already has a natural version: Claude access as something earned by demonstrated value creation.

**What to avoid.** These programs fail in predictable ways: a suggestion box that nobody reads, a single champion who carries everything and burns out, tools that get co-opted by management for surveillance, or governance that's either absent or so heavy that people stop trying.

**This enabler needs a dedicated owner** — someone with cross-functional context across the CRO org who can facilitate sessions that feel useful rather than performative, and who understands the specific workflows and proof points well enough to connect people doing related work. Spreading this across existing leaders' already-full plates is how these programs quietly die.

**Why this is an enabler.** Capability-building and grassroots support matter, but they are not the main event. Their job is to make the workflow initiatives above stick, reduce shadow-tool usage (people using unsanctioned AI tools without governance), and create the conditions for the org to find its own next high-value AI use cases rather than waiting for a central plan.

#### 4. Copilot Premium for the CRO org, and clarity on Claude access

Most of the recommendations above depend on Copilot Premium capabilities:
- Custom agents (Copilot Studio)
- Customizable meeting recaps (internal vs. customer-facing)
- Ability to connect AI to specific internal data sources

Much of the CRO org sits on standard Copilot, which doesn't provide these. Half of Declan's team cannot use the agents he built because they lack the right licenses.

- IT's recommendation to the executive leadership team is already Copilot universally
- This assessment provides the demand-side evidence
- Cost is roughly £240 per user per year
- Even modest time savings (30 min/day per person) would represent a substantial return
- This gates everything else in this report, and the decision should be made quickly

**On Claude access.** We do not believe Claude is necessary for most people in the CRO org. Copilot Premium, properly deployed, covers the vast majority of the use cases in this report.

However, the current distribution of Claude licenses has created a perception of a class system — some people have it, others don't, and the criteria are not transparent. The CIO described Claude access as requiring a request, manager approval, and cross-charge to the business unit. Kate Whiting, who is doing some of the most sophisticated AI work in the org, sees herself as someone who benefits from Claude-level capability. Others are paying out of their own pocket. That ambiguity hurts morale and makes governance harder.

Two things would help:

1. **Publish clear guidance on who has Claude access and why.** The criteria don't need to be elaborate, but they need to be visible. When people can't tell whether they're excluded by design or by accident, they assume the worst.

2. **Allow anyone to request Claude access, and approve justified use cases quickly.** The people who actively seek out a more powerful AI tool are, almost by definition, the people most likely to generate value with it. This is the same dynamic that produced Declan's agents, Mina's quote tool, Brian's dealer-data work, and Kate's RFP analysis — value created at the edge by individuals who saw an opportunity and acted on it. A slow or opaque approval process works against that. The cost per license (~£480/year) is small relative to the likely value created.

#### 5. Review data access policies

Copilot can only search content a user has permission to see. The M365 permissions model at Keyloop defaults to closed (whereas platforms like Google Workspace leave content internally open unless restricted). In practice, this means Copilot often surfaces only the user's own documents and emails rather than broader company knowledge. The gap between what people expect AI to know and what it can actually reach showed up in interview after interview.

IT has a permissive posture inside the M365 tenant, and Copilot Studio already supports grounding agents (connecting them to specific data sources so their answers draw on real company content) in SharePoint, Confluence, Jira, and other sources. The technical capability is there. What's needed is a deliberate review of which content should be opened for AI retrieval, ideally timed alongside the Copilot Premium rollout so the tools and the access arrive together.

**Content repositories to evaluate for broader access:**
- Product documentation, competitive intelligence, pricing guides, and sales playbooks in SharePoint — the core reference material sellers and AMs need daily
- The product catalog and SKU data — sellers currently have no access to the catalog at all, which is a root cause of the quoting problems described earlier. Even a read-only, navigable version would help.
- Prior quotes, statements of work, and case studies — recurring questions get asked and re-answered constantly because prior work isn't searchable
- Knowledge base content in Confluence, Jira, and scattered SharePoint folders — people have built workarounds to extract this content manually because the tools they use can't reach it

This review should happen alongside the Copilot Premium rollout. There is no point giving people better AI tools if those tools can't see what the company knows.

---

## C-Suite Approvals Needed

To act on these recommendations this quarter, six decisions are needed:

### 1. Approve Copilot Premium for the CRO organization

**Decision for: CRO + CIO + CFO.** This gates everything else. The near-term initiatives depend on Premium capabilities — customizable Teams recaps, Copilot Studio agents, grounded workflows — that standard Copilot does not provide. Cost is roughly £240 per user per year. Even modest time savings across the CRO org would represent a substantial return. Until this is approved, the initiatives above cannot start properly.

### 2. Green-light the two near-term initiatives

**Decision for: CRO.** Customer encounter support and assistive quoting support, each run as a quarter-length initiative with explicit success measures. These are not transformation programs — they are bounded bets with existing champions and working proof points. The CRO can authorize both within her organization.

### 3. Assign named owners and cross-functional support

**Decision for: CRO, with IT and Sales Ops.** Each initiative needs a business owner in the CRO organization, IT support for implementation inside the M365 perimeter, and participation from Sales Ops, quoting, enablement, and relevant field leaders. Without this, the initiatives become side projects without process owners — and side projects without process owners fail.

### 4. Authorize a focused M365 permissions review

**Decision for: CRO + CIO.** Open the specific content repositories that matter most for the initiatives: product documentation, pricing guides, playbooks, prior quotes, and the product catalog. This is a targeted access exercise, not a general information-governance overhaul. It needs to happen alongside the Copilot Premium rollout so the tools and the access arrive together.

### 5. Clarify Claude access and approved-tool policy

**Decision for: CIO, supported by CRO.** Publish a clear request path and criteria for Claude access. Approve justified use cases quickly for the smaller cohort doing higher-complexity work. The goal is to reduce shadow usage, remove the perception of an arbitrary access tier, and let the people generating the most value with AI continue to do so with organizational support. Cost is roughly £480 per user per year for a small number of users.

### 6. Align on the message to the organization

**Decision for: CRO.** This is a contributor-first productivity effort, not a surveillance program. It is not blocked on waiting for Kilimanjaro. The immediate goal is to remove low-value work, improve speed, and learn from real usage. That message needs to come from leadership explicitly, not be left for people to infer.

---

## Conclusion

Keyloop's CRO org is not starting from zero with AI. People across the organization are already building with it, and the results are promising enough to scale. The constraint is not capability or willingness. It is that these efforts are happening inside a fragmented commercial system that forces sellers and account managers to act as the glue between teams, tools, and data, absorbing hours of work that shouldn't need a human.

The strongest near-term bets are customer encounter support and quoting support: they address the most visible pain, already have grassroots proof points, and can show measurable results inside a quarter. Neither requires waiting for a new foundation to be built, though both will work better over time as the underlying systems improve. Those initiatives should be paired with the practical enablers this report has identified: Copilot Premium rollout, capability-building, clear guidance on Claude access, and a deliberate review of data permissions.

Each initiative includes explicit success measures. At the end of the quarter, those measures should be reviewed against baseline: Did follow-up time drop? Did quote turnaround improve? Did people adopt the tools voluntarily? That review is the moment to decide what to scale, what to adjust, and whether the second-phase opportunities outlined in this report are ready to begin.

Keyloop is a technology company selling into an industry that is not naturally innovative. Dealers need guidance on where technology is going, and they look to their vendors for it. If Keyloop's own sellers are visibly fluent in AI — using it to prepare better, respond faster, and understand their customers more deeply — that becomes part of the pitch. It is hard to sell the future convincingly when your own team is navigating ticket queues and spreadsheets. The work in this report is a productivity initiative, but it is also a credibility initiative. A CRO organization that moves faster and works smarter closes more deals — and becomes the proof point for the technology it's selling.

---

## Appendix: Interviewees

This assessment was based on structured interviews conducted over three weeks in March 2026. Participants were selected to cover a cross-section of roles, regions, and levels within the CRO organization, plus IT leadership.

| Name | Role |
|------|------|
| Graham Stokes | RVP Europe, UK & South Africa |
| Richard Johnston | VP Global Solutions |
| Brian O'Mahony | VP Sales Operations |
| Zara Wells | Director of Account Management, UK |
| Tantia Kruger | Regional Sales Director, South Africa |
| Declan Irwin | Sales Manager, UK & Ireland |
| Sarah Alexander | Sales Enablement |
| Kate Whiting | Enterprise Sales |
| Toby Hughes | Senior Mid-Market Seller, UK |
| Ed Binns | Key Account Manager |
| Jason Clifton | Key Account Manager |
| Mohamad Al Nabulsi | Account Manager, Middle East |
| Juan Ignacio | Velocity Sales Manager |
| Adam Bedforth | Solution Sales |
| Mark Regenburg | CIO |
| Tim | IT Director |

Additional input was received from Mina Korhonen (Product Marketing) and Federico (IT, access and usage tracking).
