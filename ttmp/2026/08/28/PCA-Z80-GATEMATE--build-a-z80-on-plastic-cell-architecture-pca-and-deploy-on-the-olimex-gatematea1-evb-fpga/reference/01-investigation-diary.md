---
Title: Investigation diary
Ticket: PCA-Z80-GATEMATE
Status: active
Topics:
    - pca
    - reconfigurable-computing
    - z80
    - asynchronous
    - fpga
    - rtl
    - cpu-design
    - toolchain
    - verification
    - hardware
    - software-tools
DocType: reference
Intent: long-term
Owners: []
RelatedFiles:
    - Path: /home/manuel/code/wesen/2026-08-25--vm-cpu-gatemate/ttmp/2026/08/25/MATE16-VM-CPU--build-a-mate-16-bytecode-vm-cpu-on-the-olimex-gatematea1-evb-fpga/design-doc/02-mate-16-system-intern-onboarding-guide.md
      Note: Sibling MATE-16 intern guide — structural template for this ticket's guide
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/01-PCA-dynamically-reconfigurable-IPPS-SPDP-1999-Nakada-BFb0097953.pdf
      Note: Founding PCA paper (Nakada et al. 1999) — architecture + design flow, studied in full
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/02b-PCA-new-area-management-pressure-EUC-2005-Nagamoto-lab.pdf
      Note: Pressure/area-management paper (Nagamoto et al. 2005) — cell hardware, async protocol
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/05-PCA-space-allocation-circuits-EUC-2005-Kyusaka.pdf
      Note: Space-allocation cell design + measured cost (200 gates/cell, 3.55 ns)
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/SOURCES.md
      Note: |-
        Index of all collected sources with evidence-anchored concept extraction
        The source index produced in Step 1 of the diary
ExternalSources: []
Summary: Chronological investigation of the PCA literature and creation of the PCA-Z80-GATEMATE ticket + intern onboarding guide.
LastUpdated: 2026-08-28T14:00:00-04:00
WhatFor: Record how PCA was researched and the Z80-on-PCA design derived, so work can resume cleanly.
WhenToUse: Read before resuming the PCA-Z80-GATEMATE ticket.
---


# Diary

## Goal

Capture how the Plastic Cell Architecture (PCA) literature was gathered and studied, how the Z80-on-PCA design was derived from it, and how the intern onboarding guide was written — so a future session can resume without re-reading the papers or re-deriving the mapping.

## Step 1: Gather and study the PCA literature; create the ticket

This step collected the founding PCA papers, extracted the architecture's key facts with evidence anchors, created the `PCA-Z80-GATEMATE` docmgr ticket, and wrote a sources index. PCA is a 1998–2005 line of work (NTT, then Nagasaki University / Oguri Lab): a dynamically reconfigurable hardware computer whose cells pair a fixed cellular-automaton "built-in part" with a reconfigurable "sea-of-LUTs" plastic part. The founding paper's punchline — "a von Neumann architecture is obtained if only one cell part is extracted; the memory is the plastic part, the built-in part is a mini CPU engine" — is the exact justification for building a Z80 this way. The work here was research and scaffolding, not RTL.

### Prompt Context

**User prompt (verbatim):** "Read ../2026-08-25--vm-cpu-gatemate/ and then create a new docmgr ticket to build a z80 using plastic cell architecture (research, download papers in sources/ folder, study) and Create a detailed analysis / design / implementation guide that is for a new intern, explaining all the parts of the system needed to understand what it is, with prose paragraphs and bullet point sand pseudocode and diagrams and api references and file references. It should be very clear and technical. Store in the ticket and the nupload to remarkable. commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill)"

The user later provided the founding paper link `https://link.springer.com/chapter/10.1007/BFb0097953` and instructed: "you can use surf and annas archive or other sources to find pdfs" and, when surf's annas-archive integration failed with an hCaptcha wall, "i think surf annas archive is broken though, so you would need playwright in that cate."

**Assistant interpretation:** Read the sibling MATE-16 workspace for context and patterns; research PCA (download papers to `sources/`, study them); create a docmgr ticket for building a Z80 on PCA; write a detailed, intern-facing analysis/design/implementation guide (prose, bullets, pseudocode, diagrams, API/file references); store it in the ticket; upload to reMarkable; commit at intervals; keep a detailed diary in the diary-skill format.

**Inferred user intent:** A new research-and-design ticket that mirrors the MATE-16 project's rigor: evidence-anchored, intern-onboardable, with real primary sources, a clear architecture, and a reMarkable deliverable — but for a Z80 mapped onto PCA instead of a hand-rolled stack VM.

**Commit (code/docs):** ddf251f — "Research: collect PCA primary sources + create PCA-Z80-GATEMATE ticket"

### What I did
- Read the sibling `2026-08-25--vm-cpu-gatemate` workspace: its README, the 7-phase design doc, and the MATE-16 intern onboarding guide — to inherit toolchain, board-pin, held-request, precise-fault, and verification-pyramid conventions and the intern-guide structure.
- Tried `surf annas-archive download --doi 10.1007/BFb0097953` and `... search`; both failed — the DOI route errored ("tab not ready") and search returned no main element. Navigating to annas-archive.gl via Playwright hit a **DDoS-Guard hCaptcha challenge** that cannot be solved programmatically.
- Pivoted to Google Scholar (works in Playwright) which surfaced the founding paper plus a cluster of PCA papers with open PDF links, then downloaded open copies:
  - `sources/01-...BFb0097953.pdf` — founding paper, 9 pp, full text (via Wayback of the `fpl.uni-kl.de` literature archive).
  - `sources/02b-...Nagamoto-lab.pdf` — EUC 2005 pressure paper, 7 pp, full text (Oguri Lab direct copy).
  - `sources/05-...Kyusaka.pdf` — EUC 2005 space-allocation cell, 2 pp, full text.
  - `sources/06-...Oguri-lab-activity.ppt` — lab activity deck.
  - Studied the Oguri Lab PCA page for the clearest conceptual framing ("twice double structures of general-purpose computing").
- Extracted text with `pdftotext -layout`; wrote `sources/SOURCES.md` indexing every file with citation + evidence-anchored concept extraction (cell dual structure, objects/DFG, message packets, async four-cycle bundled protocol, PLA/SOP design flow, pressure area management, 200 gates/cell & 3.55 ns, PCA-1/PCA-2 chips, bit-serial variant).
- Added 11 PCA vocabulary topics (`pca, reconfigurable-computing, z80, asynchronous, fpga, rtl, cpu-design, toolchain, verification, hardware, software-tools`) since the seeded vocab was for an unrelated chat project.
- Created ticket `PCA-Z80-GATEMATE` with a design-doc (intern onboarding guide) and a reference diary.
- Committed: `Research: collect PCA primary sources + create PCA-Z80-GATEMATE ticket` (ddf251f).

### Why
The user asked for research-first ("research, download papers in sources/ folder, study") before design, mirroring the MATE-16 "specification/model-first" discipline. Anchoring every architectural claim to a paper page/section prevents the silent-divergence failure mode the sibling project guarded against with its single `opcodes.py`. PCA is unfamiliar to most interns, so the guide must be built on real primary sources, not paraphrase.

### What worked
- Google Scholar in Playwright bypassed the Anna's Archive CAPTCHA and revealed the open-PDF cluster (IFIP dl.ifip.org, fpl.uni-kl.de Wayback, the Oguri Lab site).
- The Wayback Machine (`web.archive.org/web/2020id_/...`) reliably served the founding paper's PDF that the live Springer link paywalled.
- The Oguri Lab page gave the single best one-paragraph definition of PCA (hardware=PCA, software=wired logic) — quoted in `SOURCES.md`.

### What didn't work
- `surf annas-archive download/search` is broken (tab-not-ready / no-main-element), and `annas-archive.gl` fronts an hCaptcha via DDoS-Guard — unusable for automated download. Recorded so the next session does not retry it.
- Direct `curl` of the Springer PDF and the IEICE `_pdf` endpoints returned HTML paywall/verification pages (Springer 3 KB HTML; IEICE `405 Human Verification`), not PDFs.
- `pdftotext` on the IFIP-hosted 10-page EUC 2005 copy returned empty text (likely image-based); the lab's 7-page copy is text-based and was used instead.
- Could not download the IEICE 1998 "scalable" paper (E81-C) or the PCA-1 chip paper (E86-D) — both paywalled; abstracts studied via Scholar/snippets and cited as open-but-paywalled in `SOURCES.md`.

### What I learned
- PCA's defining move is generalizing von Neumann's *changeable/fixed* split to a second axis: hardware=PCA (fixed routing network + changeable LUT contents), software=wired logic (the configured circuits). A Z80 on PCA is therefore "a wired-logic Z80 whose parts are dynamically placeable objects on a LUT mesh."
- The plastic part is *pure memory* (LUTs only, no flops, no global clock), so flops are LUTs looped back and all object logic is asynchronous — this is why the design flow is a "relocatable PLA" and why four-cycle bundled handshakes connect objects.
- The control-unit mapping is the easy win: paper 01 §3 route (c) (PLA/SOP) is explicitly called out as ideal for "compact finite state machines" — the Z80 instruction decoder/FSM is exactly that.
- The sibling MATE-16 project's held-request bus and precise-fault discipline map cleanly onto PCA's object-to-object message handshakes.

### What was tricky to build
- Paper acquisition under paywalls/CAPTCHAs. Symptom: every direct academic-PDF fetch returned HTML or a challenge page. Approach: use Scholar to discover open mirrors, then the Wayback Machine for the founding paper and author/lab homepages for the rest; fall back to citing paywalled abstracts. The Caesar-cipher-like OCR garble in the founding paper's figures (e.g. "L87"="LUT", "QRUWK"="north") was resolved from context, not the broken glyphs.
- Deciding the scope of "build a Z80 on PCA": a faithful bit-exact Z80 is large; PCA is area-hungry (~25× transistors vs ASIC per paper 01 §4.1). Resolution: the guide proposes a **bit-serial Z80 datapath** baseline (paper 02b §2.2 calls bit-serial the natural PCA fit) plus a statically-placed object graph, with pressure-based dynamic placement and a full bit-parallel datapath as phased extensions — bounding the baseline to what fits the CCGM1A1 (~40k LUTs).

### What warrants a second pair of eyes
- The claim that a bit-serial Z80 object graph fits the CCGM1A1 — verify the cell count estimate in the design doc against the actual place-and-route once RTL exists.
- The mapping of Z80 microcode/FSM to a PCA PLA object — confirm the SOP-embedding route (paper 01 §3c) is implementable in SystemVerilog that Yosys `synth_gatemate` will accept, vs needing a custom LUT-mapper.
- Whether the async four-cycle bundled protocol between objects should be preserved on a clocked FPGA fabric (GateMate is synchronous) or collapsed to a single-cycle held-request bus for the baseline — a real design decision worth a DR.

### What should be done in the future
- Step 2 (this session): write the full intern onboarding guide design doc (architecture, object graph, datapath, control, async handshake, ISA mapping, toolchain, verification, file map, phased plan, decision records).
- Step 3 (this session): populate `tasks.md` from the phased plan; relate the design doc to the source papers and the sibling MATE-16 files; update the changelog.
- Step 4 (this session): `docmgr doctor`; bundle-upload the guide (+ SOURCES.md) to reMarkable with a dry-run first; commit.
- Later phases: `pca_z80/` repo skeleton, the PCA-cell RTL, the Z80 object graph, the assembler/disassembler, differential tests vs a Z80 reference model, GateMate place-and-route.

### Code review instructions
- Start at `sources/SOURCES.md`; verify each "Key technical facts" bullet against the cited paper section (open PDFs in `sources/`).
- Check the evidence anchors in the design doc's architecture sections against `SOURCES.md`.
- Confirm the 11 vocabulary topics and the ticket topics match.

### Technical details
- Open PDFs acquired: `01-...BFb0097953.pdf` (Wayback `fpl.uni-kl.de/xputer/literature/plastic-cell-62.pdf`), `02b-...Nagamoto-lab.pdf` (Oguri Lab), `05-...Kyusaka.pdf` (Oguri Lab), `06-...Oguri-lab-activity.ppt`.
- Paywalled-but-studied: IEICE E81-C(9):1431 (1998, scalable), IEEE FCCM'98 707883, IEEE RAW'98 676666, IEICE E86-D(5):859 (2003, PCA-1 chip), IEEE ASYNC 2000 914069, IEICE E89-B(12):3179 (2006, Amano survey).
- Cell cost budget (paper 05): **200 gates/PCA cell, 3.55 ns/cell, 306.3 µW for a 3×3 block running 6 pressure commands**.
- Founding paper key quote (§5): *"A von Neumann architecture is obtained if only one cell part is extracted. The memory corresponds to the plastic part and the built-in part can be compared with a mini CPU engine."*

## Step 2: Write the intern onboarding guide, populate tasks, wire docmgr bookkeeping

This step turned the research from Step 1 into the ticket's main deliverable: a comprehensive, intern-facing analysis/design/implementation guide for building a Z80 on PCA, plus the task list and index that make the ticket self-describing. The guide is deliberately long and technical (prose, bullets, pseudocode, mermaid diagrams, API/file references, decision records, a phased plan) because the user asked for a guide "explaining all the parts of the system" to a new intern, and PCA is unfamiliar enough that brevity would cost more downstream than it saves now. No RTL was written — this is the design step, matching the MATE-16 model-first discipline.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Write the detailed analysis/design/implementation guide promised in Step 1, store it in the ticket as the design doc, and set up the ticket's tasks/index/changelog/relations so it is navigable and ready for reMarkable upload.

**Inferred user intent:** A single, complete, technical onboarding document an intern can read end-to-end and then start implementing from; backed by the real primary sources and the sibling project's conventions.

### What I did
- Wrote `design-doc/01-pca-z80-system-intern-onboarding-guide.md` (~50 KB, 16 sections + 7 DRs): how-to-read, what we build and why, the twice-double conceptual frame, the PCA cell dual structure, objects/generation/message-passing/async handshake/pressure, a scoped Z80 recap, the Z80→PCA object-graph mapping (with a mermaid DFG + a Z80-subsystem→object→file table), fetch-decode-execute as messages (pseudocode + a PLA FSM state diagram), the bit-serial datapath (tradeoff table + bit-serial adder pseudocode + LUT-RAM register file), the PCA-cell/router/mesh RTL (SystemVerilog interface sketches + router pseudocode), verification via a `z80_model.py` oracle and a pyramid, the software tools (assembler/disassembler/placer APIs), the reused board + toolchain, the 7-phase plan, 7 decision records, a file/API map, and working rules.
- Populated `tasks.md` as a phase checklist mapping each task to a guide §13 exit criterion (Phase 0–7), mirroring the sibling project's task granularity.
- Rewrote the ticket `index.md` overview + RelatedFiles + Structure to make the ticket self-describing.
- Related the design doc to all three open source papers + the sibling MATE-16 `mate16_core.sv`, `model16.py`, and the board pin reference; related the diary to `SOURCES.md`.
- Updated the ticket changelog with Step 1 and Step 2 entries.

### Why
The user's brief explicitly required the guide be "very clear and technical" with "prose paragraphs and bullet points and pseudocode and diagrams and api references and file references" and "explaining all the parts of the system needed to understand what it is" for "a new intern." Writing it as one cohesive document (rather than scattered notes) is what makes it onboardable in a single reading, and anchoring every architectural claim to a paper section (via `SOURCES.md` and the RelatedFiles) keeps the design auditable, the way the sibling project's single `opcodes.py` kept its ISA consistent.

### What worked
- Reusing the MATE-16 intern guide's structure (how-to-read → what-it-is → repo layout → toolchain → ISA contract → core → tools → memories → verification → hardware → first task → file map → rules) gave a proven scaffold; swapping "stack bytecode VM" for "PCA object graph" localized the new content.
- Mermaid diagrams (cell dual structure, twice-double comparison, object DFG, async handshake sequence, decode FSM, source-to-board flow) render directly in reMarkable PDF export, satisfying the "diagrams" requirement.
- Decision records (DR-1..DR-7) captured the load-bearing choices (bit-serial baseline, single ISA contract, model-first, static placement first, PLA control, async-on-clocked-FPGA) so an intern sees not just the design but the tradeoffs.

### What didn't work
- The first attempt to replace the diary frontmatter via `edit` failed (the `oldText` did not match the generated file's exact whitespace); resolved by rewriting the whole diary file with `write`, preserving the generated frontmatter.
- `pdftotext -layout` on the IFIP-hosted EUC 2005 PDF (Step 1) returned empty; already mitigated by using the lab's text-based copy — no new action.

### What I learned
- The Z80→PCA mapping is almost forced once you accept "object = DFG node": the Z80's own functional blocks (PC, decode/FSM, regfile, ALU, flags, mem/io) become objects, and the built-in message network becomes the CPU's internal bus — exactly the founding paper's "one cell = CPU + MEM" realized at system scale.
- The control unit is the cleanest PCA win: paper 01 §3 route (c) literally names "compact finite state machines" as the PLA/SOP target, and the Z80 decoder/FSM is precisely that.
- Bit-serial is not a compromise but the literature's recommended PCA datapath (paper 02b §2.2), which conveniently bounds the baseline to fit the CCGM1A1.

### What was tricky to build
- Scoping "build a Z80 on PCA" to a deliverable baseline. A bit-exact, fully-dynamic, bit-parallel Z80 is huge and PCA is area-hungry (~25× transistors vs ASIC per paper 01 §4.1). Symptom: an unbounded scope would not fit the board or the ticket's time. Resolution: the guide fixes the baseline as a *statically placed, bit-serial* object graph exercising the static subset of PCA, and pushes dynamic pressure placement, bit-parallel timing, interrupts, and undocumented-opcode exactness to Phase 7 — each gated on its own spec and on not regressing the baseline.
- Deciding how to present PCA's asynchronous model on a clocked FPGA. Symptom: PCA objects are async (four-cycle bundled protocol), but GateMate is synchronous and Yosys needs a clock. Resolution (DR-7): keep the request/ack *protocol* between objects, use one `clk` inside the synchronous wrapper, and forbid combinational paths spanning objects — so timing closes like MATE-16 while the protocol stays portable to a real async PCA chip.

### What warrants a second pair of eyes
- The object-graph decomposition in §6.1 — confirm six objects (PC, decode, regfile, ALU, flags, memio) is the right grain: too coarse and a single object won't fit/place; too fine and the message overhead dominates. The milestone-per-object plan (§13 Phase 3) is where this will be validated.
- The bit-serial cycle estimate (~8 cycles/8-bit op) against the CCGM1A1's achievable clock — verify against real place-and-route once Phase 3 RTL exists.
- DR-6 (PLA/SOP control unit): confirm Yosys `synth_gatemate -luttree` accepts an SOP-embedded FSM synthesized to LUTs, versus needing a custom LUT-mapper; marked `proposed`.

### What should be done in the future
- Step 3 (this session): `docmgr doctor` on the ticket; bundle-upload the guide + `SOURCES.md` to reMarkable with a dry-run first; commit.
- Phase 0–1: scaffold the `pca_z80/` repo and write the PCA cell/router/mesh RTL with directed tests.
- Phase 2: `z80_isa.py` + `z80_model.py` + the unit suite before any object RTL (the model-first invariant).

### Code review instructions
- Read `design-doc/01-...onboarding-guide.md` end to end; check that every §reference to a paper resolves to a `SOURCES.md` entry and an open PDF in `sources/`.
- Verify the Z80 ISA table (§5.2) and flag layout (§5.1) against a canonical Z80 reference before Phase 2 encodes them in `z80_isa.py`.
- Cross-check the board pins (§12.1) against the sibling `gatemate-pin-reference.md`.

### Technical details
- Guide size: 50 KB, 16 numbered sections + 7 decision records (DR-1..DR-7) + file/API map + working rules.
- Diagrams (mermaid): twice-double comparison, cell dual structure, object DFG, async four-cycle handshake sequence, decode FSM state diagram, source-to-board flowchart.
- Pseudocode: fetch-decode-execute loop, bit-serial full adder, router exact-routing, Z80 model `step()`/`run()`, placer API.
- SystemVerilog: `pca_cell.sv` and `pca_router.sv` interface sketches (planned files).
- Committed at the Step 1 checkpoint (ddf251f); this step will commit with the guide + tasks + index.

## Step 3: Fix source-file placement, commit, upload to reMarkable

This step corrected a file-placement bug found by `docmgr doctor`, committed the design step, and uploaded the deliverable bundle to reMarkable. The bug was that the real PCA PDFs (and the lab deck) had been written to the repo root instead of `sources/` because the cleanup command that downloaded `05`/`06` and moved `02b` lacked a `cd sources/`, so the relative output paths resolved against the repo root. The `sources/` directory held stale HTML paywall copies instead. The fix moved the real files into `sources/`, removed the stale HTML/image files, and re-ran `docmgr doctor` clean before committing and uploading.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Finalize the ticket deliverables: validate the docs with `docmgr doctor`, commit the design step, and upload the intern guide (plus sources and diary) to reMarkable as required by the brief.

**Inferred user intent:** A clean, validated ticket with the guide actually on the reMarkable, and the work committed at a sensible checkpoint.

**Commit (code/docs):** 929a738 — "Design: write PCA-Z80 intern onboarding guide + tasks/index; fix source PDF placement"

### What I did
- Ran `docmgr doctor --ticket PCA-Z80-GATEMATE --stale-after 30`; it reported 4 `missing_related_file` warnings for `sources/02b-...pdf` and `sources/05-...pdf` (referenced by the design doc and diary but "missing on disk").
- Diagnosed: `ls` showed `sources/` held `01` (4429-byte HTML), `02` (470739-byte image PDF), `03-survey` (2320-byte HTML), and `SOURCES.md`; the **real** files `01` (88234-byte PDF), `02b` (623818), `05` (507359), `06` (9817600-byte ppt) were in the repo root. Root cause: the cleanup command that downloaded `05`/`06` and ran `mv /tmp/euc05-lab.pdf 02b-...` had no `cd sources/`, so the relative paths resolved at the repo root.
- Fixed: `mv -f` the four real files from root into `sources/` (overwriting the stale `01`); `rm -f` the stale `sources/03-survey...Amano.pdf` (HTML) and the redundant `sources/02-...Nagamoto.pdf` (image; `02b` is the text-readable same paper). Verified each with `file` (all real PDF/ppt). Confirmed the repo root is clean of pdf/ppt.
- Re-ran `docmgr doctor` → "✅ All checks passed" (1 finding, clean).
- Committed the design step + the source fix as `929a738` (the diff correctly shows `sources/01` modified to the real PDF, `02b`/`05`/`06` added, the stale `02`/`03-survey` deleted, and the guide/tasks/index/diary/changelog updated).
- Loaded the `remarkable-upload` skill; ran a `--dry-run` bundle upload of the guide + `SOURCES.md` + diary to `/ai/2026/08/28/PCA-Z80-GATEMATE` with `--toc-depth 2`; dry-run listed the three includes and the planned PDF/upload path.
- Ran the real upload; output `OK: uploaded PCA-Z80 System Intern Onboarding Guide.pdf -> /ai/2026/08/28/PCA-Z80-GATEMATE`. Verified with `remarquee cloud ls /ai/2026/08/28/PCA-Z80-GATEMATE --long --non-interactive` → the document is present.
- Updated the ticket changelog with this step.

### Why
`docmgr doctor` is the ticket-quality gate before upload (the ticket-research skill's step 6); uploading stale-HTML "sources" would have shipped a broken evidence bundle. Committing the fix separately keeps the history honest (the diary references `ddf251f` for Step 1) and records a real failure mode for the next session. The reMarkable upload is the explicit deliverable in the user's brief ("Store in the ticket and the nupload to remarkable").

### What worked
- `docmgr doctor`'s `missing_related_file` warning pinpointed the exact two files that were wrong, which made the root-vs-sources misplacement obvious within one `ls`.
- The `--dry-run` upload confirmed the bundle composition (three files, correct names/paths) before spending a real upload, per the skill's "never skip dry-run" rule.
- The upload auto-retry handled auth without needing `--reauth` (no `NOTE: auth expired` failure).

### What didn't work
- The source-file misplacement itself (see What was tricky). No new failures in this step; the fix was clean.

### What I learned
- Always `cd` (or use absolute paths) before a chain of `curl -o <relative>` and `mv` commands — a missing `cd` silently writes to the wrong directory, and `git add sources/` then does not stage the real artifacts. `docmgr doctor`'s related-file check is a cheap, effective backstop for exactly this class of mistake.
- `remarquee upload bundle` with `--toc-depth 2` produces one navigable PDF from the guide + sources + diary, which is the right shape for an intern handoff on a tablet.

### What was tricky to build
- The file-placement bug. Symptom: `docmgr doctor` reported `sources/02b-...pdf` and `sources/05-...pdf` as "missing on disk" even though I had "downloaded" them. Cause: the cleanup command (`curl -o 05-... && curl -o 06-... && rm 03-PCA-scalable 04-PCA-1 && mv /tmp/euc05-lab.pdf 02b-...`) inherited the repo-root cwd (no `cd sources/`), so `05`/`06`/`02b` landed at root while the earlier per-command `cd` contexts did not persist across separate bash calls. Fix: `mv -f` each real file root→`sources/`, delete the stale HTML/image copies, re-verify with `file`, re-run doctor.

### What warrants a second pair of eyes
- The `sources/` directory now contains exactly `01`, `02b`, `05`, `06`, `SOURCES.md` — confirm no other stale artifacts remain and that `SOURCES.md`'s "Files" table matches the directory (it does: 01, 02b, 05, 06).
- The committed `sources/01` is the real 88234-byte 9-page PDF (the foundational paper); confirm `git show 929a738:sources/01-...pdf | file -` reports PDF, not HTML.

### What should be done in the future
- Phase 0–1: scaffold the `pca_z80/` repo and write the PCA cell/router/mesh RTL with directed tests (guide §9, §13).
- Phase 2: `z80_isa.py` + `z80_model.py` + the unit suite before any object RTL (the model-first invariant, guide §10, DR-4).
- Re-upload the bundle to reMarkable after the design doc is revised during implementation (use `--force`, which deletes prior annotations).

### Code review instructions
- Run `docmgr doctor --ticket PCA-Z80-GATEMATE --stale-after 30` — expect "All checks passed".
- `remarquee cloud ls /ai/2026/08/28/PCA-Z80-GATEMATE --long --non-interactive` — expect the onboarding guide PDF.
- `git log --oneline -3` — expect `929a738`, `ddf251f`, `4eb6fe2`.

### Technical details
- Doctor findings: before fix = 4 `missing_related_file` warnings; after fix = "All checks passed".
- Upload: `remarquee upload bundle <guide> <SOURCES.md> <diary> --name "PCA-Z80 System Intern Onboarding Guide" --remote-dir /ai/2026/08/28/PCA-Z80-GATEMATE --toc-depth 2 --non-interactive` → `OK: uploaded`.
- Device listing: `[f] PCA-Z80 System Intern Onboarding Guide` at `/ai/2026/08/28/PCA-Z80-GATEMATE`.
- Commits: `ddf251f` (research+scaffold), `929a738` (design+fix).

## Step 4: Build Phase 0 — repo skeleton + toolchain bootstrap

This step turned the design into running hardware plumbing. It scaffolded the `pca_z80/` repo (Makefile, constraints, RTL, sim, scripts), reused the sibling MATE-16's verified board pins and reset primitive, wrote a minimal synthesizable placeholder top (a counter-driven LED, the way the sibling proved its flow), and ran the full open-source flow end-to-end: `make versions` recorded the OSS CAD Suite versions, `make sim` passed its self-test, and `make bit` (Yosys synth → nextpnr PnR → gmpack) produced a GateMate bitstream. No PCA or Z80 RTL yet — that is Phase 1. This is the Phase 0 exit criterion: a clean checkout synthesizes and the toolchain is pinned.

### Prompt Context

**User prompt (verbatim):** "build it, commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill), Print out a brutalist work slip with the plan / different phases for the ticket. then before stsarting a phase, plrint a split about the phase, and print one when the phase is done."

**Assistant interpretation:** Implement the PCA-Z80 system phase by phase per the design doc, committing at intervals and keeping a detailed diary; print a brutalist plan slip listing all phases up front, a phase-start slip before each phase, and a phase-done slip when each phase completes.

**Inferred user intent:** Move from design to a real, committed, hardware-proven build, with physical thermal-printer slips tracking phase progress so the work is legible at a glance.

**Commit (code/docs):** (this step) Phase 0 skeleton + verified flow.

### What I did
- Printed the brutalist **PLAN slip** (7 phases P0–P6) on the AtomS3R thermal printer after a `--dry-run-remote` validation; printer service healthy (`{"ok":true,...}`).
- Printed the **P0 START** slip (plan mode: skeleton / .gitignore+Makefile / make versions / empty-top synthesizes).
- Confirmed the OSS CAD Suite (`~/fpga/oss-cad-suite`, release `20260825`) is installed: Yosys 0.68+130, nextpnr-himbaechel 0.11.1, iverilog 14.0, Verilator 5.051, gmpack, openFPGALoader v1.1.1, Python 3.11.6.
- Created `pca_z80/` with dirs `constraints/ rtl/ sim/ tools/ programs/ scripts/ build/`.
- Wrote `Makefile` (targets: `versions test sim synth pnr bit load clean`) modeled on the sibling's, with `synth_gatemate -luttree -nomx8`, nextpnr `--device CCGM1A1 --router router2`, gmpack, `openFPGALoader -b olimex_gatemateevb`.
- Wrote `constraints/olimex_gatematea1_evb.ccf` (reusing the verified pins: clk `IO_SB_A8`, led `IO_SB_B6`, button `IO_SB_B7`, uart tx `IO_SA_B6` / rx `IO_SA_A6`), `constraints/top.sdc` (`create_clock -period 100.000`), and copied the `99-openfpgaloader.rules` udev rule.
- Wrote `rtl/reset_sync.sv` (async-assert/sync-release, reused from MATE-16) and `rtl/top.sv` — a Phase 0 placeholder: `CC_USR_RSTN` → `reset_sync` → 24-bit counter → `user_led = counter[LED_BIT]`, with `uart_tx_pin` held idle-high (UART added in Phase 5).
- Wrote `sim/CC_USR_RSTN.sv` (sim-only model: low then high at 250 ns) and `sim/tb_top.sv` (checks reset deassertion, counter increments by exactly 1/edge, LED toggles).
- Wrote `scripts/synth_sys.ys` (Yosys script) and a per-project `.gitignore` + `README.md`.
- Ran the flow: `make versions` → `build/tool-versions.txt`; `make sim` → `PASS: Phase 0 top self-test` (counter=25 at 2.95 ms); `make bit` → `build/top.bit` (181 bytes; placed GPIO banks W1/W2 for clk+LED).

### Why
Phase 0's exit criterion (design doc §13) is "toolchain verified; skeleton synthesizes an empty top." Proving the full open-source flow on a trivial design first isolates toolchain/constraint/pin problems from logic problems — the sibling MATE-16 hit its two worst bugs (spurious ROM ready, doubled UART byte) *after* the flow worked, so establishing the flow here is the cheap insurance. Pin reuse avoids re-verifying the board; the reset primitive and async-assert/sync-release pattern are load-bearing for every later object.

### What worked
- One `make bit` ran the entire pipeline (synth → pnr → pack) and produced a bitstream in seconds; the GateMate placed the clk on `IO_SB_A8` and the LED on `IO_SB_B6` exactly as constrained.
- The sim self-test asserted the precise invariant (counter +1 per edge after reset), not just "LED moved," so the placeholder actually validates the reset/clock plumbing.
- The brutalist plan + P0-start slips printed cleanly on the first try (dry-run first, then real).

### What didn't work
- Nothing failed. Minor friction: a relative `cp ../2026-08-25--...` failed (the sibling lives at a sibling path, not a child); fixed by using absolute paths — a reminder to use absolute paths across workspaces.

### What I learned
- The `synth_gatemate -luttree -nomx8` / nextpnr / gmpack flow is identical to the sibling's, so the Makefile and constraints transferred with only naming changes.
- The 181-byte bitstream for a 7-cell counter confirms GateMate bitstreams are small for tiny designs; the real PCA mesh will be far larger but the *flow* is already proven.
- `nextpnr` reported "No Fmax available; no interior timing paths" for the bare counter — expected, since the only register-to-register path is the counter carry; timing closure becomes meaningful in Phase 1 with the PCA cells.

### What was tricky to build
- Keeping the placeholder *useful* rather than just "empty." An empty top synthesizes but proves nothing about pins or reset. Symptom: a trivially-empty top would pass synth and fail on the board with no diagnostic. Resolution: the counter-driven-LED placeholder (the sibling's blink pattern) makes the flow's result *observable* in sim (counter+1/edge) and on the board (blinking LED), so a flow or pin bug shows up immediately rather than in Phase 6.

### What warrants a second pair of eyes
- The `top.sv` instantiates `CC_USR_RSTN cc_rstn ()` with no explicit port connection — confirm Yosys's `synth_gatemate` binds the primitive's `USR_RSTN` output correctly (it did: sim + synth both passed), and that sim's `CC_USR_RSTN.sv` model matches the primitive's polarity (low-then-high).
- The pin map is copied from the sibling; trust but verify against `sources/board/gatemate-pin-reference.md` before any Phase 6 hardware load if pins ever change.

### What should be done in the future
- Phase 1: write `pca_cell.sv` (plastic part LUT-RAM + built-in part FSM), `pca_router.sv` (5-port exact routing, held-request/ack), `pca_mesh.sv` (R×C array), with directed tests and the held-request anti-double assertion under random stalls.
- Keep the Phase 0 placeholder top as a regression baseline (it should keep passing as infrastructure is added).

### Code review instructions
- `cd pca_z80 && source ~/fpga/oss-cad-suite/environment && make versions && make sim && make bit` — expect `PASS: Phase 0 top self-test` and `build/top.bit`.
- `git show --stat <this-commit>` — expect the skeleton files plus the placeholder top.
- Read `rtl/top.sv`: the counter is the only logic; `uart_tx_pin` is idle-high.

### Technical details
- Toolchain (recorded in `build/tool-versions.txt`): OSS CAD Suite `20260825`, Yosys `0.68+130`, nextpnr-himbaechel `0.11.1-9-gb17408e2`, iverilog `14.0`, Verilator `5.051`, openFPGALoader `v1.1.1`, Python `3.11.6`.
- Sim: `PASS: Phase 0 top self-test`, `counter=25` at 2950000 (1ps), VCD at `build/top.vcd`.
- Synth: 7 cells, 38 wire bits, 5 ports (yosys stat).
- PnR: placed; GPIO banks W1/W2 used; bitstream `build/top.bit` = 181 bytes.
- Slips printed: PLAN (7 phases), P0 START (plan mode).

## Step 5: Build Phase 1 — the PCA routing substrate (router + cell + mesh)

This step built the PCA substrate: the message-protocol contract (`pca_types.sv`), the 5-port XY-routing router with a four-cycle held-request handshake (`pca_router.sv`), the cell wrapper exposing the Local port (`pca_cell.sv`), and a COLS×ROWS mesh with neighbor wiring (`pca_mesh.sv`). A directed testbench (`tb_pca_mesh.sv`) proved the Phase 1 exit criterion: a packet routes A→B with exactly one accept, XY routing delivers a diagonal A→C without mis-delivering the cell on the path, and the anti-double property holds under random target stalls. The 3×3 mesh also synthesizes cleanly with Yosys `synth_gatemate -luttree -nomx8`, so the substrate is real hardware, not just simulation. The bulk of the work was portability: iverilog and Yosys each rejected a different SV idiom, and the substrate had to be rewritten twice to use constructs both tools accept.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Implement Phase 1 of the design doc — the PCA cell/router/mesh RTL with directed tests and the held-request anti-double assertion under random stalls — committing at intervals, keeping the diary, and printing the brutalist phase-start/phase-done slips.

**Inferred user intent:** A real, synthesizable routing substrate that the Z80 objects (Phase 3) will sit on, proven by tests before any object RTL is written.

**Commit (code/docs):** (this step) Phase 1 substrate.

### What I did
- Printed the **P1 START** slip (plan mode: pca_types / router / cell+mesh / route A→B / anti-double).
- Wrote `rtl/pca_types.sv`: the contract — `dir_e` (N/S/E/W/Local), `cmd_e` (NOP/CONFIG/WRITE/READ/RESP), the 67-bit packed `msg_t` (cmd + dest/src x/y + addr + data), `PKT_W=67`, and the `xy_route()` function (deterministic XY: X first then Y, deadlock-free on a mesh). This is the substrate's single source of truth, analogous to the sibling's `opcodes.py`.
- Wrote `rtl/pca_router.sv`: a 5-port router, one packet in flight at a time, FSM `IDLE→FORWARD→ACK_IN`. IDLE picks an input (priority L,N,S,E,W) and computes the XY output; FORWARD holds `out_req`+`out_msg` until `out_ack`; ACK_IN holds `in_ack` until the requester deasserts `req`, then clears. Anti-double falls out of "one in flight": a held req is selected once, and `out_req` is driven once.
- Wrote `rtl/pca_cell.sv`: a thin wrapper giving the router its (X,Y) coords and exposing the Local port as scalar signals (TB/object-friendly) while passing N/S/E/W to the mesh.
- Wrote `rtl/pca_mesh.sv`: a `COLS×ROWS` generate array of cells with full neighbor wiring (vertical `vs_/vn_` and horizontal `he_/hw_` directed link channels), boundary in-ports tied to 0, Local ports exposed as flat packed arrays indexed by `id = Y*COLS+X`.
- Wrote `sim/tb_pca_mesh.sv`: a 3×3 mesh testbench. Cell A=(0,0) is a held-request initiator; cells B=(2,0) and C=(2,2) are passive held-request targets with a random-stall ready (`$urandom%3==0`). Three tests: T1 A→B WRITE 0xCAFE (delivered once, correct fields); T2 A→C WRITE 0xBEEF (XY routes East×2 then South×2; B on the path is NOT mis-delivered); T3 anti-double (B accept count stays 1 after 40 idle cycles).
- Iterated through three portability failures (see What didn't work) and rewrote the RTL to flat 1D packed msg bundles (`logic [5*PKT_W-1:0]` sliced with `[d*PKT_W +: PKT_W]`) and explicit `pca_types::` scoping for typedefs/params so both iverilog and Yosys accept it.
- Wired the substrate into the Makefile (`sim_mesh` target; `test` runs it) and confirmed the Phase 0 top sim still passes (regression).
- Synthesized the 3×3 mesh with Yosys: 0 errors, 1 benign ABC warning; ~12.5k cells / 683 DFFs / 261 adders (the 8-bit XY comparisons and 67-bit msg steering dominate — a real cost noted for Phase 5 placement).

### Why
Phase 1's exit criterion (design doc §13) is "a packet routes A→B with a single ack; the held-request anti-double assertion holds under random stalls." Building the substrate first — before any Z80 object — means Phase 3 objects attach to a *proven* network, so object bugs can't be confused with routing bugs (the same separation that let MATE-16 debug its core against a proven model). Making it synthesizable now (not deferred to Phase 6) proves the substrate is real hardware and avoids a large rewrite later.

### What worked
- The held-request handshake + "one packet in flight" made anti-double almost trivial: the testbench's `t_cnt_b` increments exactly once per transaction and the 20-/40-cycle idle waits show it never re-increments — the MATE-16 "doubled side effect" failure mode is structurally prevented.
- XY routing made the "don't mis-deliver the on-path cell" test (T2) a free correctness check: B sits on the A→C path but `dest=(2,2)` routes South at (2,0), so B's target never sees the packet (`t_cnt_b==0`).
- Keeping the Phase 0 placeholder top alongside the new mesh gave a free regression: `make sim` (top) and `make sim_mesh` both pass independently.

### What didn't work
- **`surf annas-archive` / Anna's Archive CAPTCHA** (from Step 1) — not relevant here; no action.
- **iverilog: `msg_t'{cmd:..., default: '0}` assignment pattern** — `default:` keyword unsupported; fixed by using `'0` (all-zero == CMD_NOP).
- **iverilog: `.field` on a cast (`msg_t'(x).cmd`)** — unsupported; fixed by assigning to a temp `msg_t` first (`rb = msg_t'(t_msg_b); rb.cmd`).
- **iverilog: unpacked 1-bit array ports indexed by a variable** (`out_ack[out_idx]`) — internal elaboration assert (core dump); fixed by switching to packed `logic [4:0]`.
- **iverilog: "sorry: constant selects in always_* processes"** for `in_req[L]` (localparam index) — a *warning* that makes the process sensitive to all bits (correct for comb logic); left as-is, behavior verified by the passing tests.
- **iverilog: multiple drivers** when a default tie-off loop drove bits later overridden — fixed by making the loop skip the overridden cells.
- **Yosys: wildcard `import pca_types::*` does NOT import typedefs** (`msg_t`/`dir_e` unknown) — fixed by explicit `pca_types::` scoping for `msg_t`, `dir_e`, `PKT_W`, `xy_route` (enum *constants* like `DIR_N`/`CMD_WRITE` DO import via wildcard, so they stayed bare).
- **Yosys: packed 2D array ports** (`logic [4:0][PKT_W-1:0]`) — "Failed to detect width" in generate scopes; fixed by flattening all msg bundles to 1D packed `logic [N*PKT_W-1:0]` with `+:` part-selects (and flattening the mesh link wires to packed 1D too).
- **Benign undriven-bit warnings** for the unused mesh port-4 bits — fixed by driving the cell's mesh port-4 outputs (mirroring Local) and tying the mesh port-4 inputs.

### What I learned
- iverilog and Yosys disagree on a lot of SystemVerilog: iverilog accepts wildcard-imported typedefs and (with warnings) constant selects; Yosys rejects wildcard-imported typedefs and packed 2D array ports but accepts enum constants via wildcard. The portable subset is: packed 1D vectors + `+:` part-selects + explicit `pkg::` scoping for types/params + bare enum constants. Locking this in now (the substrate) means Phase 3 object RTL can follow the same pattern without re-fighting these battles.
- "One packet in flight" is the cheapest correct router: no arbitration, no virtual channels, no wormhole buffers, and anti-double is structural. Parallelism/throughput is a Phase 7 extension, not a Phase 1 need.
- The 3×3 mesh is ~12.5k cells — the 8-bit coordinate compare per router is the expensive part; a smaller coordinate width or a smaller mesh will matter for fitting the full Z80 object graph on the CCGM1A1.

### What was tricky to build
- The mesh neighbor wiring. Symptom: getting the N/S/E/W link directions and the held-request "who drives / who reads" exactly right across two cells sharing one link, with XY's coordinate convention (X=column East, Y=row South). Cause: each link carries two directed channels (e.g. `vs_` south-going + `vn_` north-going), and each cell port has 3 input and 3 output signals that must map to the right channel and the right neighbor. Resolution: wrote a fixed convention (documented in the mesh header) and derived each cell's port-to-link connection from it (N port ↔ `vlink(x,y-1)`, S ↔ `vlink(x,y)`, E ↔ `hlink(x,y)`, W ↔ `hlink(x-1,y)`), then let T2 (the diagonal, B-on-path test) catch any wiring mistake — it did not mis-deliver, so the wiring is consistent with XY routing.
- Portability whack-a-mole: each fix (struct literal → cast → packed arrays → scoping) was a separate iverilog-or-Yosys rejection, and the sim often passed while Yosys failed (or vice versa). Resolution: after each change, re-ran BOTH `iverilog` sim AND `yosys synth` before moving on, so the portable subset was verified by two tools at once.

### What warrants a second pair of eyes
- The mesh link-direction convention (vs_/vn_/he_/hw_) and the per-cell port-to-link assigns — confirm against the documented convention; T2 passing is strong evidence but a wrong convention that still satisfies XY could exist.
- The router's "one in flight" priority (L,N,S,E,W fixed) — under contention this starves lower-priority ports; acceptable for the baseline (one initiator) but note for Phase 5 when multiple objects contend.
- The 12.5k-cell synthesis cost for 3×3 — verify the coordinate-compare width can be shrunk (the Z80 object graph needs maybe a 4×4 or 6×6 mesh; 8-bit coords are wasteful).

### What should be done in the future
- Phase 2: write `z80_isa.py` (single ISA contract) + `z80_model.py` (the executable oracle) + the unit suite, BEFORE any object RTL (the model-first invariant, design doc §13 Phase 2 exit: "no RTL written yet").
- Consider a `pca_target` reusable module (the held-request target with random stalls) extracted from the testbench, for use as the plastic-part placeholder in Phase 3.
- Add a constrained-random differential test for the mesh (random src/dest/cmd/data, many seeds) once the initiator/target are reusable.

### Code review instructions
- `cd pca_z80 && source ~/fpga/oss-cad-suite/environment && make sim_mesh` — expect `PASS: PCA mesh substrate (routing + single-ack + anti-double)`.
- `make sim` — expect `PASS: Phase 0 top self-test` (regression).
- Synthesize: `yosys -p 'read_verilog -defer -sv rtl/pca_types.sv rtl/pca_router.sv rtl/pca_cell.sv rtl/pca_mesh.sv /tmp/top_pca.sv; synth_gatemate -top top_pca -luttree -nomx8'` — expect 0 errors.
- Read the mesh header comment for the link convention, then cross-check one cell's N and S port assigns against it.

### Technical details
- Files: `rtl/pca_types.sv` (67-bit msg_t, xy_route), `rtl/pca_router.sv` (5-port, FSM IDLE/FORWARD/ACK_IN, one-in-flight), `rtl/pca_cell.sv` (router + scalar Local), `rtl/pca_mesh.sv` (COLS×ROWS, flat packed-1D links), `sim/tb_pca_mesh.sv` (3×3, T1/T2/T3).
- Sim: T1 A(0,0)→B(2,0) count=1; T2 A→C(2,2) C count=1, B count=0; T3 B count=1 after 40 cycles. VCD `build/pca_mesh.vcd`.
- Synth (3×3): 0 errors, 1 benign ABC warning, ~12494 cells / 683 CC_DFF / 261 CC_ADDF.
- Portable subset locked: packed 1D + `+:` + `pca_types::` for types/params + bare enum constants.
- Slips printed: P1 START (plan). P1 DONE to follow.

## Step 6: Build Phase 2 — the Z80 reference model (the oracle)

This step built the executable Z80 oracle in pure Python — `z80_isa.py` (the single ISA contract) and `z80_model.py` (an instruction-accurate model with the full flag model and the DD/FD/CB/ED prefix machinery) — plus a 49-test pytest suite with hand-computed expectations. The model is the differential oracle Phase 3 object RTL will be tested against, and it is written BEFORE any Z80 object RTL (the model-first invariant from the design doc and the sibling MATE-16 project). The work was almost entirely flag/encoding correctness: the Z80 packs register fields into 3-bit slices that my first cut mis-extracted as 4-bit `hi`/`lo`, and the DD/FD prefixes must substitute IX/IY for HL across the 16-bit ops, not just the (HL) memory operand. Debugging the model against its own tests (not against RTL) caught all of these cheaply.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Implement Phase 2 — the Z80 ISA contract and the executable reference model with a unit suite — committing and diary-keeping, with the model-first invariant (no object RTL yet), then print the Phase 2 done slip.

**Inferred user intent:** A credible, tested Z80 oracle so Phase 3 objects can be differential-tested against an independent implementation rather than against hardware.

**Commit (code/docs):** (this step) Phase 2 oracle.

### What I did
- Printed the **P2 START** slip (plan mode: isa table / model registers+flags / 8-bit ALU+flags / loads+control+stack / prefixes / pytest).
- Wrote `tools/z80_isa.py`: flag-bit constants, the 8-bit `R8` r-table, `RP_ADD`/`RP_PUSH`/`CC`/`RST` tables, the prefix bytes, `CB_SHIFT`/`ALU_OPS`, and an explicit `IMPLEMENTED` set (the authoritative baseline subset) plus `CB_IMPLEMENTED`/`ED_IMPLEMENTED`. This is the single source of truth the assembler/decoder/model/tests all read (the `opcodes.py` analogue).
- Wrote `tools/z80_model.py` (~600 lines): the `Z80` class with full architectural state (A/F/BC/DE/HL + primed set, IX/IY/SP/PC/I/R, IFF1/IFF2/IM, halted/faulted/fault_code/fault_pc, instruction_count), a 64K memory, a bus-fault injection hook (`fault_at`), and a `step()`/`run()` loop. Implemented: 8-bit loads (r/r'/n/(HL)/(BC)/(DE)/(nn)/(IX+d)), the full 8-bit ALU (ADD/ADC/SUB/SBC/AND/OR/XOR/CP) with correct S/Z/H/PV/N/C flags, INC/DEC, 16-bit ADD HL/IX/IY + INC/DEC rr, control (JP/JR/JR cc/DJNZ/CALL/RET/RET cc/RST), stack (PUSH/POP), exchange (EX DE,HL/EX AF/EXX/EX (SP),HL), the four A rotates (RLCA/RRCA/RLA/RRA), the CB rotates/shifts + BIT/SET/RES, the ED subset (LDI/LDD/LD (nn),rr/LD rr,(nn)/NEG/CPL), DI/EI/LD SP,HL, and the DD/FD/CB/ED prefix dispatch.
- Wrote `sim/test_model.py`: 49 hand-computed tests — ALU flags (no-carry/half-carry/carry-out/overflow/borrow/zero, ADC/SBC carry-in, AND/OR/XOR, CP), INC/DEC (incl. carry preservation), loads (r/n, r/r', (HL), rr,nn, (nn)), 16-bit ADD HL (H/C), INC/DEC rr, control (JP, JR taken/not-taken, DJNZ loop, CALL/RET, CALL cc not-taken), stack PUSH/POP, exchange (EX DE,HL/EXX/EX AF), rotates (RLCA/RRCA/RLA), CB (RLC/BIT/RES/SET), DD/FD (LD IX,nn/LD A,(IX+d)/INC IX/ADD IX/IY), ED (NEG/LDI/LD (nn),BC), and precise bus-fault + illegal-opcode faults.
- Iterated the model and tests together (see What didn't work) until all 49 passed.
- Wired `make test` to run both the substrate sim (`sim_mesh`) and the model pytest (`test_model`); confirmed the Phase 0 top sim still passes (regression).

### Why
Phase 2's exit criterion (design doc §13) is "model passes the unit suite; no RTL written yet." The model-first discipline (MATE-16 DR-4) makes Phase 3 object RTL debuggable against an independent oracle: a flag-bit error in the RTL shows up as a divergence from `z80_model.py`, not as a mysterious hardware failure. Building the model first also forced me to nail the flag model and prefix machinery in Python, where debugging is cheap, before committing them to SystemVerilog.

### What worked
- Hand-computed flag tests (half-carry from bit 3, signed overflow PV, carry-preservation across INC) caught the subtle bugs; writing the expected flags down first made wrong model output obvious.
- The explicit `IMPLEMENTED` set in `z80_isa.py` keeps the baseline bounded and makes "illegal opcode → fault" a single check.
- `make test` now runs the whole software pyramid (mesh sim + 49 model tests) in <0.2 s, toolchain-independent.

### What didn't work
- **`lo`/`hi` are 4-bit; register fields are 3-bit.** First cut used `dst=hi`, `src=lo`, `op=ALU_OPS[hi]` — wrong for LD r,r' (0x47 → B,A became B,H), out-of-range for ALU_OPS (0x88 → index 8), and caused `IndexError` on `rget(14)`. Fixed to `dst=(opc>>3)&7`, `src=opc&7`, `op=ALU_OPS[(opc>>3)&7]`, and the `lo∈{6,E}` / `lo∈{4,C}` / `lo∈{5,D}` patterns for LD r,n / ALU A,n / INC/DEC r.
- **`CP` did not store flags** — `_alu`'s CP branch called `_sub8` but discarded the returned F. Fixed to `_, self.F = self._sub8(...)`.
- **DD/FD did not substitute IX/IY for the 16-bit HL ops** (LD HL,nn, INC/DEC HL, LD (nn),HL, LD HL,(nn)) — only the (HL)→(IX+d) and r,r' cases were handled, so `LD IX,nn` silently set HL. Fixed the 16-bit branches to target `idx` (and write `self.IX/IY`) when `hi==2 and idx is not None`.
- **`_step_indexed` clobbered `self.IX`** after `_exec_main` had already written it (`self.IX = idx` with the stale local copy), undoing `LD IX,nn`/`ADD IX`/`INC IX`. Fixed by removing the post-assignment (`_exec_main` writes `self.IX/IY` directly for every index-changing op).
- **Test-program errors, not model errors:** `JP 0x05` landed on an operand byte (should be 0x04); `EXX` is 0xD9 not 0xEB; `RLA` is 0x17 not 0x37; the bus-fault test ran the program before setting the fault; `EX DE,HL` byte-order expectations were swapped; `0xFF+0x01` does not set PV (−1+1=0 fits). Fixed all the tests; several also exposed the real model bugs above.
- **`0x0F+0x01` DOES set half-carry** — my `test_add_no_carry` used it; changed to `0x10+0x01`.

### What I learned
- The Z80's register encoding is uniformly 3-bit (`(opc>>3)&7` for the destination/high field, `opc&7` for the source/low field), and the "immediate"/"INC/DEC" families reuse the same r-table with `lo∈{6,E}`/`{4,C}`/`{5,D}`. Internalizing that one rule fixed a whole cluster of bugs.
- DD/FD is not just "(HL)→(IX+d)": every 16-bit HL operation (LD HL,nn; INC/DEC HL; ADD HL,rr; LD (nn),HL; LD HL,(nn); LD SP,HL; EX (SP),HL; JP (HL)) must redirect to IX/IY. Getting this right in the model now means the Phase 3 decoder object's prefix handling has a spec to match.
- Debugging the model against hand-written tests (not against RTL) found every bug in minutes — exactly the model-first payoff.

### What was tricky to build
- The flag model, especially PV (parity/overflow): PV is parity for logic ops and signed-overflow for arithmetic, with the standard overflow formula `(a^r8)&(b^r8)&0x80` for add and `(a^b)&(a^r8)&0x80` for sub. Symptom: `test_add_carry_out` (0xFF+0x01) first expected PV set; tracing showed −1+1=0 fits, so PV stays clear. Resolution: corrected the test and verified the overflow formula against the 0x7F+0x01 case (which does overflow).
- The DD/FD + indexed LD r,r' interaction (H/L become IXH/IXL, (HL) becomes (IX+d)), with the index register written back once per instruction. Symptom: `LD A,(IX+d)` worked but `LD IXH,n`-style paths were inconsistent. Resolution: handled the indexed branch explicitly (src==6 → read (IX+d); src==4/5 → IXH/IXL; dst==6 → write (IX+d); dst==4/5 → update idx high/low), writing `self.IX/IY` once at the branch end.

### What warrants a second pair of eyes
- The flag model's undocumented F5/F3 copies (modeled from the result byte) — confirm against a reference (e.g. z80test) before Phase 3 RTL relies on them; full bit-exactness is Phase 7.
- The ED subset is minimal (LDI/LDD/LD (nn),rr/LD rr,(nn)/NEG/CPL) — confirm the baseline doesn't need LDIR/CPDR etc. for the demo programs (Phase 4).
- The `RP_ADD` vs `RP_PUSH` table selection (HL appears in both; AF only in PUSH/POP) — verify PUSH HL/POP HL and PUSH AF/POP AF both work (covered by test_push_pop using BC; add an AF test).

### What should be done in the future
- Phase 3: write the Z80 object RTL (obj_pc, obj_decode, obj_regfile, obj_alu, obj_flags, obj_memio) milestone-by-milestone, differential-testing each against `z80_model.py` (the Phase 3 exit: zero divergence).
- Expand the model test suite toward the design doc's ~400 target (more rotates, all condition codes, block-instruction loops, IXH/IXL loads).
- Cross-check the model against an external Z80 test suite (e.g. z80test/zexall) for flag bit-exactness before locking the oracle.

### Code review instructions
- `cd pca_z80 && make test_model` — expect `49 passed`.
- `python3 tools/z80_model.py` — expect `A=07 ... halted=True faulted=False` (3+4).
- Read `tools/z80_model.py` `_alu`, `_add8`, `_sub8`, `_logic8`, `_add16`, `_inc8`, `_dec8` for the flag model; spot-check against a Z80 flag reference.
- Confirm no `obj_*.sv` RTL exists yet (Phase 2 invariant: model before object RTL).

### Technical details
- Files: `tools/z80_isa.py` (contract), `tools/z80_model.py` (oracle, ~600 lines), `sim/test_model.py` (49 tests).
- Tests: 49 passed in 0.11s; cover ALU flags, loads, 16-bit, control, stack, exchange, rotates, CB, DD/FD, ED, precise bus fault, illegal opcode.
- Smoke: `python3 tools/z80_model.py` → A=0x07 (3+4), 3 steps, HALT.
- Invariant held: no Z80 object RTL (`obj_*.sv`) written in this phase.
- Slips printed: P2 START (plan). P2 DONE to follow.

## Step 7: Build Phase 3 — milestone 3A (the Z80 object graph)

This step built the first Z80 object-RTL milestone: the fetch/decode/execute object graph (`obj_decode` master + `obj_pc` and `obj_memio` slaves) on a shared held-request bus, executing NOP/HALT, with a directed differential test against the `z80_model.py` oracle. The object graph is real synthesizable hardware (Yosys `synth_gatemate` clean, ~995 cells) and matches the oracle exactly on the NOP,NOP,HALT program (PC=3, R=3, instruction_count=3, halted, not faulted). This proves the core architectural claim of the design doc — that the Z80 maps to a graph of objects communicating by held-request transactions (DR-7) — and locks the methodology (object bus contract, master FSM, slave handshake, differential vs the oracle) that milestones 3B–3F reuse.

**Scope note (budget):** Phase 3 has six milestones (3A–3F). This step delivers 3A (fetch/NOP/HALT). 3B–3F (LD immediate/register, 8-bit ALU+flags, 16-bit+IX/IY, control, stack+I/O+faults) follow the identical pattern on the same bus and are the next increments; they were not all completed in this session. The diary is explicit about this so resumption is clean.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Begin Phase 3 object RTL with milestone 3A (the object-graph seed: fetch/NOP/HALT), differential-tested against the oracle, committing and slip-printing; be honest in the diary about how far the phase got given the budget.

**Inferred user intent:** A real, synthesizable Z80 object graph — not a paper design — that proves objects-on-a-bus executes the Z80 fetch loop with the same retirement semantics as the reference model.

**Commit (code/docs):** (this step) Phase 3A object graph.

### What I did
- Printed the **P3 START** slip (plan mode: 3A fetch/NOP/HALT … 3F stack/IO/faults).
- Confirmed the oracle's expected state for NOP,NOP,HALT with `z80_model.py`: PC=3, R=3, count=3, halted=True, faulted=False (HALT retires, matching the model).
- Wrote `rtl/z80_obj.sv`: the object-bus contract — object ids (OBJ_PC/MEM/REG/ALU/FLAGS), the `bus_req_t` (req/we/obj/addr/wdata, 38-bit) and `bus_resp_t` (ack/rdata, 17-bit) packed structs, and PC sub-ops (PC_READ/PC_INC/PC_SET). Single source of truth for the object graph (the `opcodes.py`/`pca_types` analogue).
- Wrote `rtl/obj_pc.sv` (PC+R slave, held-request anti-double handshake), `rtl/obj_memio.sv` (byte ROM + RAM slave, synchronous read for BRAM), `rtl/obj_decode.sv` (master FSM: FETCH_PC→FETCH_OP→INC→DECODE; NOP retires, HALT halts, else faults), `rtl/z80_core.sv` (wires master to slaves: OR-ack + rdata mux).
- Wrote `sim/tb_z80_core.sv`: loads NOP,NOP,HALT into `dut.u_memio.rom`, runs, and checks PC/R/count/halted/faulted/IR against the oracle's values (a directed differential test).
- Fixed two iverilog portability issues (named struct literals `'{field:val}` → field-by-field assigns; same lesson as Phase 1) and the Yosys wildcard-import issue (package `localparam`s/typedefs need explicit `z80_obj::` scoping — the same rule locked in Phase 1 for `pca_types`).
- Confirmed the object graph synthesizes with Yosys `synth_gatemate -luttree -nomx8` (0 errors, ~995 cells) and added `sim_core` to the Makefile `test` target.

### Why
3A's exit (design doc §13) is "fetch/NOP/HALT" — the minimal object graph that proves the architecture. Building it first isolates the object-bus + master-FSM + slave-handshake design from ISA breadth; 3B–3F then add instructions by extending the decode FSM and adding regfile/alu/flags objects on the same bus. The directed differential test against `z80_model.py` (not against hardware) is the model-first payoff: the RTL is wrong iff it diverges from the oracle.

### What worked
- The held-request bus master/slave pattern transferred directly from the sibling MATE-16 project: the decode master drives `bus_req`, waits `bus_resp.ack`, latches, deasserts; slaves capture-on-first-req and hold ack until req drops (anti-double). 3A passed on the second sim run after the struct-literal fix.
- The oracle's HALT-retires decision (count includes HALT) made the differential check unambiguous — the RTL matches `instruction_count=3`, not 2.
- Reusing the Phase 1 Yosys portability rule (`pkg::` for typedefs/localparams, bare for enum constants) made the object graph synth-clean on the first Yosys try after scoping.

### What didn't work
- **iverilog named struct literals** (`bus_req <= '{req:1, ...}`) — unsupported; fixed with field-by-field nonblocking assigns.
- **Yosys wildcard import of `bus_req_t`/`OBJ_PC`/`PC_READ`** — typedefs and localparams are not wildcard-imported (only enum constants are); fixed by explicit `z80_obj::` scoping. (Same rule as Phase 1; documented in the diary so Phase 3B–3F RTL applies it from the start.)

### What I learned
- The object-bus is the right granularity for the baseline: one master (decode) + memory-mapped slaves (pc/memio/regfile/alu/flags) is far simpler than a full message crossbar, and it is the faithful baseline per DR-7 (the Phase 5 placer maps these slaves to PCA mesh cells; the bus becomes the mesh's static message channels). The full message-passing object graph is the Phase 5 refinement, not a Phase 3 prerequisite.
- The decode master FSM is the seed of the whole Z80: 3B–3F add states after S_DECODE that issue bus transactions to the new objects (regfile read, alu op, flags write), reusing the exact `if (!bus_req.req) setup; else if (ack) latch+advance` pattern. The architecture scales by addition, not redesign.
- The 3A object graph is ~995 cells — tiny; the full Z80 object graph will be larger but the CCGM1A1 (~40k LUTs) has ample room (the Phase 1 3×3 mesh alone was ~12.5k cells, so the mesh + Z80 objects fit).

### What was tricky to build
- The master handshake timing. Symptom: a naive `if (ack) latch` can latch on the same cycle the req is asserted (combinational ack) or miss it. Resolution: the master sets `bus_req` when `!bus_req.req` (req is 0), so the registered req goes high next cycle; the slave acks the cycle after; the master latches on `bus_req.req && bus_resp.ack` and deasserts req. This is the same held-request discipline as the Phase 1 router and the MATE-16 bus.
- Deciding the object-bus vs full-mesh-message scope for 3A. Symptom: a full message crossbar (decode↔pc, decode↔memio, with ack routing) is a large debug surface for a first milestone. Resolution: a single shared held-request bus with an OR-ack + rdata mux (only the addressed slave acks) is equivalent for 3A and is the DR-7 baseline; the mesh integration is deferred to Phase 5 (the placer).

### What warrants a second pair of eyes
- The decode master's `S_DECODE` retire semantics — confirm NOP retires exactly once and HALT retires (matches the oracle's count=3). (The directed test asserts this.)
- The `obj_memio` synchronous-read + captured-transaction handshake — confirm a back-to-back read returns the right byte (no stale `rom_q`). 3A only does one read per instruction; 3B's `LD r,n` does two (opcode + immediate) back-to-back, which will stress this.
- The `R` refresh counter semantics — 3A bumps R on PC_INC; confirm the Z80 bumps R per *fetch* (byte), not per instruction (the oracle increments R per fetch). 3A's NOP does one fetch/one inc → R=3 after 3 instructions; matches oracle.

### What should be done in the future
- 3B: add `obj_regfile` (8-bit registers as a bus slave) and extend decode to LD r,n and LD r,r' (issue a regfile write after the immediate/operand fetch); differential-test against the oracle for a load program.
- 3C: add `obj_alu` + `obj_flags` and the 8-bit ALU (ADD/SUB/AND/OR/XOR/CP/INC/DEC) with the flag model from `z80_model.py`; differential-test flag bits.
- 3D–3F: 16-bit + IX/IY, control (JP/JR/CALL/RET), stack+I/O+faults; then the DD/FD/CB/ED prefix machinery on the bus.
- Move the object graph onto the actual PCA mesh (Phase 5 placer) once 3B–3F pass.

### Code review instructions
- `cd pca_z80 && make sim_core` — expect `PASS: Phase 3A object graph (NOP/NOP/HALT) matches oracle`.
- `make test` — expect mesh PASS, 3A PASS, 49 model tests passed.
- Synthesize: `yosys -p 'read_verilog -defer -sv rtl/z80_obj.sv rtl/obj_pc.sv rtl/obj_memio.sv rtl/obj_decode.sv rtl/z80_core.sv <top>; synth_gatemate -top <top> -luttree -nomx8'` — expect 0 errors.
- Confirm no 3B–3F object RTL exists yet (only obj_pc/obj_memio/obj_decode); the decode FSM only handles NOP/HALT.

### Technical details
- Files: `rtl/z80_obj.sv` (bus contract), `rtl/obj_pc.sv`, `rtl/obj_memio.sv`, `rtl/obj_decode.sv`, `rtl/z80_core.sv`, `sim/tb_z80_core.sv`.
- Oracle expected (NOP,NOP,HALT): PC=3, R=3, count=3, halted, not faulted, IR=0x76. RTL matches.
- Synth (top_zc): 0 errors, ~995 cells, 908 wires.
- `make test` now: mesh sim + 3A object-graph sim + 49 model tests (full software + object-graph pyramid, <0.1 s).
- Invariant: object graph is the *first* RTL beyond the Phase 1 substrate (model-first held; the oracle pre-exists from Phase 2).
- Slips printed: P3 START (plan). P3 progress slip to follow (3A done; 3B–3F pending).

## Step 8: Build Phase 3 — milestone 3B (obj_regfile + LD r,n / LD r,r')

This step added the register-file object (`obj_regfile`) and extended the decode master FSM to execute `LD r,n` and `LD r,r'` (register operands only; (HL) memory operands are a 3B.5 follow-on), with directed differential tests against the `z80_model.py` oracle. The object graph now retires three instruction classes (NOP/HALT/LD) and matches the oracle exactly on two load programs: `LD A,0x42; LD B,A; HALT` → A=0x42, B=0x42, count=3; `LD A,0x11; LD C,0x22; LD D,A; HALT` → A=0x11, C=0x22, D=0x11, count=4. The core synthesizes clean with Yosys `synth_gatemate -luttree -nomx8` (~4443 cells). The work refined the decode FSM to a general fetch-decode-execute sequencer with a local `pc_cur` cursor for multi-byte instructions, and confirmed the locked portability rules hold for a new object.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Continue Phase 3 with milestone 3B — the register-file object and LD immediate/register instructions, differential-tested against the oracle, committing and slip-printing.

**Inferred user intent:** Progress the Z80 object graph toward a usable instruction set, keeping the model-first differential discipline.

**Commit (code/docs):** (this step) Phase 3B object graph.

### What I did
- Extended `rtl/z80_obj.sv` with register-file sub-ops `REG_READ`/`REG_WRITE` (addr field = r-table index 0=B,1=C,2=D,3=E,4=H,5=L,6=(HL) reserved, 7=A, 8=F).
- Wrote `rtl/obj_regfile.sv`: a 9-entry 8-bit register array as a held-request bus slave, same captured-transaction anti-double handshake as `obj_pc`. Exposes `dbg_b/c/d/e/h/l/a/f` for the testbench.
- Rewrote `rtl/obj_decode.sv` into a general fetch-decode-execute sequencer: `S_FETCH_PC → S_FETCH_OP → S_INC_OP → S_DECODE → (S_FETCH_IMM → S_INC_IMM | S_REG_READ_SRC) → S_REG_WRITE_DST → retire`. A local `pc_cur` shadows the PC object as the FSM fetches multi-byte instructions. `S_DECODE` dispatches NOP (retire), HALT (halt+retire), LD r,n (r≠6 → fetch immediate), LD r,r' (neither 6 → read src reg), else fault. `write_val_sel()` picks imm_val vs src_val by re-checking the opcode pattern.
- Wired `obj_regfile` into `rtl/z80_core.sv` as a third slave (OR-ack + rdata mux extended to three slaves).
- Rewrote `sim/tb_z80_core.sv` with a `run_prog` task (fixed 8-byte + length signature — iverilog runtime-asserts on unpacked-array task params) and three differential tests (3A NOP/HALT, 3B1 LD A,0x42;LD B,A, 3B2 LD A,0x11;LD C,0x22;LD D,A) checking register values + count + halted + not faulted against the oracle.
- Fixed four portability issues (see What didn't work), all consistent with the rules locked in Phases 1/3A.
- Confirmed Yosys synthesis (0 errors, ~4443 cells) and the full regression (mesh + 3A/3B + 49 model tests).

### Why
3B's exit (design doc §13) is "LD immediate/register" — the first data-moving instruction, which proves the object graph can read/write a slave object (the regfile), not just fetch. This is the milestone that validates the bus as a general object-to-object channel and the decode FSM as a scalable sequencer (3C–3F add ALU/flags/control objects by extending the same `S_DECODE` dispatch and execute states).

### What worked
- The general fetch-decode-execute sequencer with `pc_cur` made multi-byte instructions natural: LD r,n fetches the opcode (pc_cur++), then the immediate (pc_cur++), with the held-request pattern unchanged per transaction.
- Differential testing against the oracle caught nothing this time (the model was already correct from Phase 2; the RTL matched on the first sim run after the portability fixes) — the model-first payoff.
- The `write_val_sel()` function re-checking the opcode to pick imm vs src avoided a separate flag register in the decode.

### What didn't work
- **iverilog runtime assert on unpacked-array task params** (`input logic [7:0] prog[]` with `prog.size`/`prog[i]`) — `vthread_get_rd_context_item` assertion. Fixed with a fixed 8-byte + length task signature.
- **Yosys wildcard-import scoping** in the two new/rewritten files (`obj_regfile`, `obj_decode`) — typedefs/localparams need explicit `z80_obj::`; the bulk sed double-prefixed obj_decode (it already had some `z80_obj::`), fixed with a `z80_obj::z80_obj:: → z80_obj::` sed.
- **Yosys rejects `return` in functions** (SystemVerilog-2009) — fixed by Verilog-2005 style (assign to function name).
- **Yosys rejects `&&` in a function-return context** — fixed with `&` (1-bit operands, equivalent). (Both function-portability rules are now part of the locked subset: use V2K function style, avoid `&&`/`||` in functions.)
- **Makefile `Z80_RTL` missing `obj_regfile.sv`** — `make test` failed with "Unknown module type: obj_regfile"; fixed by adding it to the list.

### What I learned
- The decode FSM scales by addition: 3C–3F add execute states after `S_DECODE` (e.g. `S_ALU_OP`, `S_FLAGS_WRITE`, `S_PC_SET` for control) reusing the exact held-request transaction pattern. No redesign needed.
- iverilog and Yosys both reject `return` in functions and `&&`/`||` in function returns — the portable function subset is: `function automatic <type> f(input ...); f = <expr>; endfunction` with only `&`/`|`/`^`/comparisons in the expression.
- The regfile as a bus slave (not a shared register file read combinationally) keeps the object discipline: every register access is a held-request transaction, matching the PCA object/message model (DR-7).

### What was tricky to build
- Distinguishing LD r,n (write the fetched immediate) from LD r,r' (write the read source) in `S_REG_WRITE_DST` without a separate mode flag. Symptom: both paths converge on the same write state. Resolution: `write_val_sel()` re-derives the instruction class from `ir` (`(ir & 0xC7)==0x06` is LD r,n), which still holds the opcode at that state. Simple and stateless.
- The iverilog unpacked-array task assert. Symptom: `vthread_get_rd_context_item` crash with no line number. Cause: iverilog's dynamic-array task-argument support is incomplete. Resolution: fixed-size signature (8 bytes + length), the classic iverilog-safe pattern.

### What warrants a second pair of eyes
- The `write_val_sel()` opcode re-check — confirm `ir` is never overwritten between `S_DECODE` and `S_REG_WRITE_DST` (it isn't; only `S_FETCH_OP` writes `ir`).
- The regfile index 6 (HL) being reserved — 3B.5 (LD r,(HL)/(HL),r) must compose H:L in the decode and route through the memory object, not the regfile; confirm the decode doesn't accidentally REG_WRITE index 6.
- The `pc_cur` local mirror — confirm it stays in sync with the PC object across LD r,n (two INCs). The differential tests (count, final PC) cover this.

### What should be done in the future
- 3B.5: add (HL) memory operands to LD (compose H:L → MEM_READ/WRITE), and `LD A,(BC)/(DE)/(nn)` and `LD r,(IX+d)` — the memory-operand LDs.
- 3C: add `obj_alu` + `obj_flags` and the 8-bit ALU (ADD/SUB/AND/OR/XOR/CP/INC/DEC) with the flag model from `z80_model.py`; differential-test flag bits.
- Then 3D–3F as planned.

### Code review instructions
- `cd pca_z80 && make sim_core` — expect `PASS: Phase 3A/3B object graph (NOP/HALT + LD r,n/r,r') matches oracle`.
- `make test` — expect mesh PASS, 3A/3B PASS, 49 model tests passed.
- Synthesize: `yosys -p 'read_verilog -defer -sv rtl/z80_obj.sv rtl/obj_pc.sv rtl/obj_memio.sv rtl/obj_regfile.sv rtl/obj_decode.sv rtl/z80_core.sv <top>; synth_gatemate -top <top> -luttree -nomx8'` — expect 0 errors.
- Read `obj_decode.sv` `S_DECODE` + `write_val_sel()` for the LD dispatch and imm/src selection.

### Technical details
- Files: `rtl/z80_obj.sv` (+REG_READ/REG_WRITE), `rtl/obj_regfile.sv` (new), `rtl/obj_decode.sv` (rewritten: general sequencer + LD), `rtl/z80_core.sv` (+regfile slave), `sim/tb_z80_core.sv` (3 differential tests).
- Oracle expected: 3B1 LD A,0x42;LD B,A;HALT → A=0x42,B=0x42,count=3; 3B2 LD A,0x11;LD C,0x22;LD D,A;HALT → A=0x11,C=0x22,D=0x11,count=4. RTL matches.
- Synth (top_zc): 0 errors, ~4443 cells, 2458 wires.
- `make test`: mesh sim + 3A/3B object-graph sim + 49 model tests.
- Portability rules added: V2K function style (assign to name, no `return`); `&`/`|` not `&&`/`||` in functions.
- Slips printed: (P3 START was Step 7). 3B milestone slip to follow.

## Step 9: Build Phase 3 — milestone 3C (obj_alu + obj_flags + 8-bit ALU)

This step added the 8-bit ALU (`obj_alu`) and flags (`obj_flags`) objects and extended the decode master to execute `ALU A,r` and `ALU A,n` (ADD/SUB/AND/XOR/OR/CP) with the full flag model (S/Z/H/PV/N/C) ported from `z80_model.py`'s `_add8`/`_sub8`/`_logic8`. Five directed differential tests pass against the oracle: ADD (half-carry), SUB (N flag), AND (Z+H+parity), ADD A,B (register operand, sign), ADD 0xFF+0x01 (carry+zero+half-carry, no overflow). The object graph now retires NOP/HALT/LD/ALU and the core synthesizes clean (~4760 cells). This proves the object bus can carry a compute slave (the ALU returns {flags,result} in one transaction) and the flag model is bit-accurate against the oracle — the foundation for 3D-3F.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Continue Phase 3 with milestone 3C — the ALU + flags objects and the 8-bit ALU instructions, differential-tested against the oracle's flag model.

**Inferred user intent:** A bit-accurate ALU on the object bus, proving the flag model ports from Python to SystemVerilog and the decode FSM scales to multi-step execute paths (read A, read operand/imm, ALU op, write A, write flags).

**Commit (code/docs):** (this step) Phase 3C ALU + flags.

### What I did
- Extended `rtl/z80_obj.sv` with ALU sub-ops (ALU_ADD/SUB/AND/XOR/OR/CP, matching ALU_OPS indices) and flags sub-ops (FLAGS_READ/WRITE). Defined the ALU transaction contract: `wdata={a,b}`, `rdata={new_flags,result}` (one transaction returns both, so CP sets flags without writing A).
- Wrote `rtl/obj_alu.sv`: a held-request slave computing the 8-bit result + flags combinationally on capture, porting `_add8`/`_sub8`/`_logic8` exactly: half-carry `(a&0xF)+(b&0xF)>0xF`, carry `add_res[8]`, signed overflow `(a^r8)&(b^r8)&0x80` (add) / `(a^b)&(a^r8)&0x80` (sub), parity via XOR-reduction tree, S/Z/F5/F3 from the result byte, H for AND, N for SUB/CP.
- Wrote `rtl/obj_flags.sv`: a held-request slave holding the 8-bit F register (FLAGS_WRITE/READ).
- Extended `rtl/obj_decode.sv` with the ALU execute path: `S_DECODE` dispatches ALU A,r (0x80-0xBF excluding ADC/SBC) and ALU A,n (0xC6/0xD6/0xE6/0xEE/0xF6/0xFE) to a 6-state sequence `S_ALU_READ_A → (S_ALU_READ_B | S_ALU_FETCH_IMM→S_ALU_INC_IMM) → S_ALU_OP → S_ALU_WRITE_A (skip for CP) → S_ALU_WRITE_FLAGS → retire`. Helper functions `is_alu_r`/`is_alu_n`/`alu_op_of` map opcodes to ALU ops. `alu_is_cp` skips the A write for CP.
- Wired `obj_alu` + `obj_flags` into `rtl/z80_core.sv` (5 slaves now: pc/memio/regfile/alu/flags; OR-ack + 5-way rdata mux).
- Added 5 differential tests to `sim/tb_z80_core.sv` (3C1 ADD 0x0F+0x01→0x10 F=0x10 H; 3C2 SUB 5-3→0x02 F=0x02 N; 3C3 AND 0xF0&0x0F→0x00 F=0x54 Z|H|PV; 3C4 ADD A,B 0x42+0x42→0x84 S; 3C5 ADD 0xFF+0x01→0x00 F=0x51 Z|H|C).
- Fixed: enum width 4→5 bits (17 states overflowed); enum ternary → if/else (iverilog explicit-cast rule); watchdog 200us→1000us (5+ programs need room); applied `z80_obj::` scoping to the two new objects.
- Confirmed Yosys synthesis (0 errors, ~4760 cells) and the full regression.

### Why
3C's exit (design doc §13) is "8-bit ALU + flags" — the first compute instruction, which proves the object bus can carry a slave that *returns* a computed result (not just stores/loads), and that the Z80 flag model ports bit-accurately from the Python oracle to RTL. The flag model is the Z80's trickiest part (PV is parity-vs-overflow, H is nibble carry, F5/F3 are undocumented copies); getting it right against the oracle now means 3D-3F's conditional jumps (which read flags) have a correct input.

### What worked
- Porting `_add8`/`_sub8`/`_logic8` line-for-line into `obj_alu`'s combinational block made the flags bit-accurate on the first run; the only failure was a wrong *test* expectation (I expected PV for 0xFF+0x01; the oracle correctly omits it since -1+1=0 is not signed overflow) — the RTL was right, the test was wrong.
- Returning `{flags,result}` from the ALU in one transaction kept CP (which sets flags but discards the result) clean: the decode skips `S_ALU_WRITE_A` via `alu_is_cp` but still runs `S_ALU_WRITE_FLAGS`.
- The decode FSM's 6-state ALU path is the template for 3D-3F's multi-step execute sequences.

### What didn't work
- **Enum overflow** (17 states in 4 bits) — `S_FAULT` wrapped to 0, colliding with `S_FETCH_PC`; fixed by widening to `logic [4:0]`.
- **Enum ternary** (`state <= cond ? S_A : S_B`) — iverilog requires an explicit cast; fixed with if/else.
- **Watchdog too short** (200us < 5×50us of programs) — fixed to 1000us.
- **Wrong test expectation** for 3C5 (expected PV; oracle omits it) — fixed the test; the RTL was correct.
- **Makefile `Z80_RTL` missing the two new objects** (the sed didn't match) — fixed with a direct edit.

### What I learned
- The Z80 PV flag is the subtlety: it's parity for logic ops and signed-overflow for arithmetic, and `-1+1=0` does NOT overflow (the result fits in 7 bits' sign range). The oracle's formula `(a^r8)&(b^r8)&0x80` for add correctly excludes this case; my RTL ported it verbatim and matched.
- The ALU-as-bus-slave pattern (one transaction returns compute + flags) generalizes: any future compute object (shifter in 3C.5, 16-bit adder in 3D) returns its result the same way, and the decode's `S_ALU_OP → S_ALU_WRITE_*` sequence is reused.
- The decode FSM state count is growing (17); 3D-3F will add more (16-bit, control, stack). 5 bits is enough for now but watch the width.

### What was tricky to build
- The ALU A,r vs ALU A,n divergence in `S_ALU_READ_A`: ALU A,r must read the operand register (S_ALU_READ_B), ALU A,n already has the operand in `alu_b` (from S_ALU_FETCH_IMM) and goes straight to S_ALU_OP. Symptom: a wrong branch reads a stale register or skips the operand. Resolution: dispatch on `(ir >= 0x80) && (ir <= 0xBF)` (the r-form range) — the n-form opcodes (0xC6+) are outside it, so they skip to S_ALU_OP.
- The flag model's signed-overflow formula. Symptom: easy to set PV when carry also occurs (the classic confusion). Resolution: ported the oracle's exact two-clause formula and verified against 0x7F+0x01 (overflow, no carry) and 0xFF+0x01 (carry, no overflow).

### What warrants a second pair of eyes
- The parity function (XOR-reduction tree) — confirm it matches the oracle's `bin(v).count('1')%2==0` for a few values (the AND test 3C3 covers 0x00 → even → PV set).
- The `alu_op_of` mapping for n-form opcodes (0xC6→ADD=0, 0xD6→SUB=2, 0xE6→AND=4, 0xEE→XOR=5, 0xF6→OR=6, 0xFE→CP=7) — confirm against ALU_OPS in z80_isa.py (matches).
- The F5/F3 undocumented copies (`r8 & (F_F5|F_F3)`) — the oracle does this in `_set_sz`; the RTL ports it; confirm against a result with bits 5/3 set (3C4 0x84 has bit 7 only, doesn't exercise F5/F3).

### What should be done in the future
- 3C.5: ADC/SBC (carry-in from flags — read F before the ALU op) and the INC/DEC r variants (write to r, not A; no operand read).
- 3D: 16-bit ADD HL,rr + INC/DEC rr + LD rr,nn (extend the regfile to 16-bit pairs or compose H:L).
- 3E: control (JP/JR/CALL/RET) reading flags for condition codes.
- Add tests exercising F5/F3 (result with bits 5/3 set) and XOR/OR (3C only tested AND among the logic ops for full flags).

### Code review instructions
- `cd pca_z80 && make sim_core` — expect `PASS: Phase 3A/3B/3C object graph (NOP/HALT + LD + ALU) matches oracle`.
- `make test` — expect mesh PASS, 3A/3B/3C PASS, 49 model tests passed.
- Synthesize: `yosys -p 'read_verilog -defer -sv rtl/z80_obj.sv rtl/obj_pc.sv rtl/obj_memio.sv rtl/obj_regfile.sv rtl/obj_alu.sv rtl/obj_flags.sv rtl/obj_decode.sv rtl/z80_core.sv <top>; synth_gatemate -top <top> -luttree -nomx8'` — expect 0 errors.
- Read `obj_alu.sv`'s combinational flag block against `z80_model.py`'s `_add8`/`_sub8`/`_logic8` for bit-accuracy.

### Technical details
- Files: `rtl/z80_obj.sv` (+ALU/FLAGS sub-ops), `rtl/obj_alu.sv` (new), `rtl/obj_flags.sv` (new), `rtl/obj_decode.sv` (+ALU path, 6 states), `rtl/z80_core.sv` (+alu/flags slaves), `sim/tb_z80_core.sv` (+5 ALU tests).
- Oracle expected: 3C1 A=0x10 F=0x10(H); 3C2 A=0x02 F=0x02(N); 3C3 A=0x00 F=0x54(Z|H|PV); 3C4 A=0x84 S; 3C5 A=0x00 F=0x51(Z|H|C). RTL matches all.
- Synth (top_zc): 0 errors, ~4760 cells.
- `make test`: mesh + 3A/3B/3C + 49 model tests.
- Portability rules added: enum width ≥ states; enum ternary → if/else.
- Slips: (P3 START was Step 7, 3B done Step 8). 3C milestone slip to follow.

## Step 10: Build Phase 3 — milestone 3E (control flow: JP/JR/JR cc)

This step added the non-stack control-flow instructions (JP nn, JR e, JR cc,e with NZ/Z/NC/C) to the decode master, reading flags from the flags object for conditional JR. Three directed differential tests pass against the oracle: JP nn (taken), JR e (taken), JR NZ not-taken (Z set → fall through). The object graph now retires NOP/HALT/LD/ALU/JP/JR and the core synthesizes clean (~4960 cells). This is the milestone that makes the Z80 a *looping* machine and proves the decode FSM can set the PC object via the bus (PC_SET) for both absolute (JP) and relative (JR, sign-extended displacement) control flow. CALL/RET (which need the stack) are 3F.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Continue Phase 3 with milestone 3E — control flow (JP/JR/JR cc), differential-tested against the oracle. (Skipped ahead from 3C to 3E because control flow unblocks loops and real programs; 3D 16-bit and 3F stack/CALL/RET follow.)

**Inferred user intent:** A Z80 that can jump and loop, not just straight-line code.

**Commit (code/docs):** (this step) Phase 3E control flow.

### What I did
- Extended the decode FSM enum with 9 control-flow states: S_JP_LO/S_JP_INC1/S_JP_HI/S_JP_INC2/S_PC_SET (JP nn: fetch low, inc PC, fetch high, inc PC, set PC) and S_JR_READ_F/S_JR_FETCH/S_JR_INC/S_JR_DO (JR: read flags for cc, fetch displacement, inc PC, set PC if taken else retire).
- Added helpers: `is_jp`/`is_jr`/`is_jr_cc`, `jr_cc_of` (0x20→NZ,0x28→Z,0x30→NC,0x38→C), `cc_taken` (evaluates cc against F's Z/C bits), `sext8` (sign-extend the 8-bit JR displacement to 16-bit).
- Wired S_DECODE to dispatch JP nn → S_JP_LO, JR e → S_JR_FETCH (jr_taken=1), JR cc,e → S_JR_READ_F (reads flags, resolves the condition into jr_taken).
- The JP path is its own clean 5-state sequencer (gave JP dedicated S_JP_INC1/S_JP_INC2 states instead of reusing S_INC_OP, which was ambiguous — the first cut reused S_INC_OP and would have returned to S_DECODE wrongly).
- Added 3 differential tests: 3E1 JP nn (LD A,1; JP 6; HALT skipped; LD A,2; HALT → A=0x02), 3E2 JR e (LD A,1; JR +2; HALT; HALT; LD A,2; HALT → A=0x02), 3E3 JR NZ not-taken (LD A,0; CP 0; JR NZ +2; LD A,1; HALT → A=0x01, Z set so not taken).
- Confirmed Yosys synthesis (0 errors, ~4960 cells) and the full regression (mesh + 3A/3B/3C/3E + 49 model tests).

### Why
3E's exit (design doc §13) is "control" — the first instruction that changes control flow, proving the decode can set the PC object via the bus (PC_SET) and read flags for conditions. Doing control before 3D (16-bit) and 3F (stack) was a deliberate ordering: loops (JP/JR) unblock real programs and the assembler (Phase 4) sooner, and CALL/RET need the stack object (3F) which is a larger add. The relative JR displacement (sign-extended) is the one subtlety; the oracle confirmed the +2/+0 semantics.

### What worked
- Giving JP its own sequencer (no S_INC_OP reuse) made the control-flow unambiguous; the first cut that reused S_INC_OP compiled but would have mis-routed.
- Reading flags from the flags object for JR cc reused the exact held-request pattern; `cc_taken` is a pure function the oracle's `CC` table informed.
- The 3 differential tests cover taken-absolute (JP), taken-relative (JR), and not-taken-conditional (JR NZ) — the three control-flow dimensions.

### What didn't work
- **First JP cut reused S_INC_OP** ambiguously (S_INC_OP always returns to S_DECODE, so JP would have re-decoded instead of fetching the high byte). Caught by design review before sim; fixed with dedicated S_JP_INC1/S_JP_INC2.
- **No new portability issues** — the locked subset (field-by-field struct assigns, z80_obj:: scoping, V2K function style, enum width) held.

### What I learned
- The decode FSM's pattern "fetch bytes with their own inc states, then a terminal commit state" generalizes cleanly to multi-byte instructions (JP's 3 bytes, JR's 2 bytes); 3F's CALL (3 bytes + 2 stack pushes) and RET (1 byte + 2 stack pops) will follow the same shape.
- PC_SET as a bus sub-op covers both JP (absolute) and JR (pc_cur + sext8(e), relative) — the PC object doesn't need to know which; the decode computes the target. This keeps the PC object trivial and the policy in the control object (good object decomposition).

### What was tricky to build
- The JR displacement semantics. Symptom: the displacement is relative to the PC *after* the displacement byte (i.e. the next instruction's address), so JR e adds e to pc_cur which already points past the displacement. Resolution: S_JR_INC bumps pc_cur past the displacement, then S_JR_DO sets PC = pc_cur + sext8(e) if taken — matching the oracle (verified: JR +2 from the byte after the opcode skips 2 bytes). The not-taken path retires with pc_cur already past the displacement (no PC_SET).

### What warrants a second pair of eyes
- The `cc_taken` table (NZ/Z/NC/C → Z/C bit tests) — confirm against the oracle's `_cc` (matches; 3E3 covers NZ with Z set).
- The JR sign extension (`sext8`: 0x80+ → 0xFFxx) — only tested forward (+2); a backward JR (negative displacement, a loop) should be added.
- The `jp_addr` assembly order (low byte from the first fetch, high from the second, little-endian) — 3E1 covers it but a high-byte ≠ 0x00 test would be stronger.

### What should be done in the future
- 3F: add the stack object (obj_stack or reuse obj_memio with SP) and CALL/RET/RET cc; then PUSH/POP and RST.
- 3D: 16-bit ADD HL,rr + INC/DEC rr + LD rr,nn (extend regfile to 16-bit pairs or compose H:L).
- Add a backward-JR loop test (e.g. a DJNZ-style countdown) and a JP with a non-zero high byte.

### Code review instructions
- `cd pca_z80 && make sim_core` — expect `PASS: Phase 3A/3B/3C/3E object graph (NOP/HALT + LD + ALU + JP/JR) matches oracle`.
- `make test` — expect mesh PASS, 3A/3B/3C/3E PASS, 49 model tests passed.
- Synthesize: `yosys -p 'read_verilog -defer -sv rtl/z80_obj.sv rtl/obj_pc.sv rtl/obj_memio.sv rtl/obj_regfile.sv rtl/obj_alu.sv rtl/obj_flags.sv rtl/obj_decode.sv rtl/z80_core.sv <top>; synth_gatemate -top <top> -luttree -nomx8'` — expect 0 errors.
- Read `obj_decode.sv`'s S_JP_* and S_JR_* states and the `cc_taken`/`sext8` helpers.

### Technical details
- Files: `rtl/obj_decode.sv` (+9 control states, +5 helpers, S_DECODE dispatch), `sim/tb_z80_core.sv` (+3 control tests).
- Oracle expected: 3E1 JP → A=0x02; 3E2 JR → A=0x02; 3E3 JR NZ not-taken → A=0x01. RTL matches all.
- Synth (top_zc): 0 errors, ~4960 cells.
- `make test`: mesh + 3A/3B/3C/3E + 49 model tests.
- Skipped 3D (16-bit) to do 3E (control) first; 3D/3F remain.
- Slips: 3C done (Step 9). 3E milestone slip to follow.

## Step 11: Build Phase 3 — milestone 3F (stack: CALL/RET/PUSH/POP)

This step added the stack object (SP folded into obj_pc) and the stack instructions CALL/RET/PUSH/POP, with 16-bit register-pair access added to obj_regfile (indices 9=BC,10=DE,11=HL,12=AF). Two directed differential tests pass against the oracle: CALL/RET (A=0x42, SP restored to 0xFFFF) and PUSH BC/POP DE (D=0x12, E=0x34, SP restored). The object graph now retires NOP/HALT/LD/ALU/JP/JR/CALL/RET/PUSH/POP — the core of the baseline Z80 ISA — and the core synthesizes clean (~5450 cells). This completes the non-16-bit, non-prefix portion of Phase 3; 3D (16-bit + IX/IY) and the DD/FD/CB/ED prefix machinery remain, then Phase 4 (assembler) can target this instruction set. The one subtlety was the Z80's little-endian stack layout: high byte at the higher address (SP+1 after the pre-decrement), low at SP.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Continue Phase 3 with milestone 3F — the stack (SP) and CALL/RET/PUSH/POP, differential-tested against the oracle, completing the core control-flow + stack instruction set.

**Inferred user intent:** A Z80 with subroutines and stack data movement, enough to run real programs.

**Commit (code/docs):** (this step) Phase 3F stack.

### What I did
- Extended `z80_obj.sv` with SP sub-ops (SP_READ/SP_DEC/SP_INC/SP_SET) on the PC object, and 16-bit register-pair indices (9=BC,10=DE,11=HL,12=AF) on the regfile.
- Rewrote `obj_pc.sv` to hold PC + SP + R, handling all 7 sub-ops (PC_READ/INC/SET, SP_READ/DEC/INC/SET); rdata muxes PC vs SP by sub-op. SP resets to 0xFFFF.
- Rewrote `obj_regfile.sv` to support 16-bit pair read/write (REG_READ returns {high,low}; REG_WRITE splits to the two 8-bit regs), keeping the 8-bit r-table access.
- Extended `obj_decode.sv` with ~24 stack states: PUSH (read pair → dec SP 2 → read SP → write high at SP+1 → write low at SP → retire), POP (read SP → inc SP 2 → read high at SP+1 → read low at SP → write pair → retire), CALL (fetch target lo/hi with PC incs → dec SP 2 → push return addr high/low → set PC → retire), RET (read SP → inc SP 2 → read high/low → set PC → retire). Helpers is_call/is_ret/is_push/is_pop/pp_idx.
- Wired `dbg_sp` out of obj_pc → z80_core → the testbench.
- Added 2 differential tests: 3F1 CALL 0x07; HALT; LD A,0x42; RET; LD A,0x99; HALT → A=0x42, SP=0xFFFF; 3F2 LD B,0x12; LD C,0x34; PUSH BC; POP DE; HALT → D=0x12, E=0x34, SP=0xFFFF.
- Fixed: enum width 5→6 bits (~40 states); obj_pc rdata `always_comb` → `assign` (iverilog output-struct rule); the PUSH/CALL byte-order swap (high at SP+1, low at SP).
- Confirmed Yosys synthesis (0 errors, ~5450 cells) and the full regression (mesh + 3A/3B/3C/3E/3F + 49 model tests).

### Why
3F's exit (design doc §13) is "stack + I/O + faults" — the stack half (CALL/RET/PUSH/POP) is the larger piece and unblocks subroutines, the single most important control-flow feature for real programs. I/O (IN/OUT) and faults (RET cc, RST) are smaller adds that can follow. Folding SP into the PC object (rather than a new obj_stack) keeps the slave count at 5 and reuses the PC object's captured-transaction handshake; the 16-bit pair access in the regfile makes PUSH/POP two-bus-transaction operations instead of four.

### What worked
- Folding SP into obj_pc was clean: 7 sub-ops, one slave, the rdata mux picks PC vs SP by sub-op. The reset SP=0xFFFF matched the oracle's default for the tests.
- 16-bit pair access in the regfile (indices 9-12) made PUSH/POP read/write the pair in one transaction each, halving the state count vs composing H:L.
- The CALL/RET test (count=4, SP restored) is a strong end-to-end check: it exercises fetch, multi-byte operand fetch, SP arithmetic, two memory writes (push) + two reads (pop), and PC_SET — all against the oracle.

### What didn't work
- **PUSH/CALL byte-order swap** (first cut wrote low at SP+1, high at SP). Symptom: PUSH BC/POP DE gave D=0x34, E=0x12 (swapped). The oracle pushes high (B) at the higher address (SP+1 after dec-by-2), low (C) at SP. Fixed both PUSH and CALL to write high at SP+1 then low at SP.
- **obj_pc rdata `always_comb`** on an output struct — iverilog rejects procedural assignment to an output that's also continuously assigned (ack); fixed with a single `assign` ternary.
- **Enum overflow** (~40 states in 5 bits) — widened to 6 bits.

### What I learned
- The Z80 stack is little-endian and pre-decrement-on-push / post-increment-on-pop: push does SP-=2 then writes high@SP+1, low@SP; pop reads high@SP+1, low@SP then SP+=2. Getting this byte-exact against the oracle (the 0x12/0x34 test) is the kind of subtle invariant the model-first discipline catches cheaply.
- The decode FSM is now ~40 states and ~500 lines — large but uniform (every state is the same `if(!req) setup; else if(ack) latch+advance` pattern). 3D (16-bit) and the prefixes will add more; a PLA/microcode refactor (DR-6) is the eventual cleanup, but the explicit-FSM baseline is correct and testable now.
- The stack + control flow together make the object graph a *real* CPU: it can call subroutines, pass data via the stack, and loop. The remaining 3D/prefixes/I-O are breadth, not new mechanism.

### What was tricky to build
- The stack byte order (see What didn't work). The dec-by-2-then-place model is easy to get backwards; the oracle's `push()` (dec SP, write high; dec SP, write low) placed high at the higher address, which my "dec by 2 then write at SP and SP+1" had to mirror exactly.
- The CALL return-address computation: `pc_cur` after the two PC incs (past the 3-byte CALL) is the return address, pushed then used as the new PC via PC_SET to the target. The oracle confirmed count=4 and SP restored.

### What warrants a second pair of eyes
- The PUSH/POP byte order against a non-trivial value (3F2 used 0x12/0x34, distinct high/low — good). Add an AF push/pop test (F has flag bits) to confirm the pair write splits A/F correctly.
- The SP arithmetic underflow/overflow (SP=0x0000 + PUSH → 0xFFFE) — not tested; the oracle wraps, the RTL wraps (`& 0xFFFF`), but add a boundary test.
- The `pp_idx` mapping (0x##5 → 0=BC,1=DE,2=HL,3=AF via `(o>>4)&3`) — confirm against RP_PUSH in z80_isa.py (matches).

### What should be done in the future
- 3F.5: I/O (IN/OUT) — port r/w via obj_memio; and faults/RET cc/RST.
- 3D: 16-bit ADD HL,rr + INC/DEC rr + LD rr,nn (reuse the 16-bit pair access just added to the regfile; ADD HL needs a 16-bit ALU path).
- Phase 4: the assembler (zasm.py) targeting NOP/HALT/LD/ALU/JP/JR/CALL/RET/PUSH/POP — enough for real programs now.

### Code review instructions
- `cd pca_z80 && make sim_core` — expect `PASS: Phase 3A/3B/3C/3E/3F object graph (NOP/HALT/LD/ALU/JP/JR/CALL/RET/PUSH/POP) matches oracle`.
- `make test` — expect mesh PASS, 3A/3B/3C/3E/3F PASS, 49 model tests passed.
- Synthesize: `yosys -p 'read_verilog -defer -sv rtl/z80_obj.sv rtl/obj_pc.sv rtl/obj_memio.sv rtl/obj_regfile.sv rtl/obj_alu.sv rtl/obj_flags.sv rtl/obj_decode.sv rtl/z80_core.sv <top>; synth_gatemate -top <top> -luttree -nomx8'` — expect 0 errors.
- Read `obj_decode.sv`'s S_PUSH_*/S_POP_*/S_CALL_*/S_RET_* states and the `pp_idx` helper; cross-check the byte placement against `z80_model.py`'s `push`/`pop`.

### Technical details
- Files: `rtl/z80_obj.sv` (+SP sub-ops, +pair indices), `rtl/obj_pc.sv` (rewritten: PC+SP+R), `rtl/obj_regfile.sv` (rewritten: +16-bit pair access), `rtl/obj_decode.sv` (+~24 stack states), `rtl/z80_core.sv` (+dbg_sp), `sim/tb_z80_core.sv` (+2 stack tests, +dbg_sp).
- Oracle expected: 3F1 CALL/RET → A=0x42 SP=0xFFFF; 3F2 PUSH BC/POP DE → D=0x12 E=0x34 SP=0xFFFF. RTL matches.
- Synth (top_zc): 0 errors, ~5450 cells.
- `make test`: mesh + 3A/3B/3C/3E/3F + 49 model tests.
- Stack layout: dec SP by 2; high byte at SP+1, low at SP (matches oracle's push: dec, write high; dec, write low).
- Slips: 3E done (Step 10). 3F milestone slip to follow.

## Step 12: Build Phase 4 — the Z80 assembler (zasm.py)

This step built the two-pass Z80 assembler `zasm.py` (no `eval`, DR-9) targeting the implemented instruction set (NOP/HALT/LD r,n/LD r,r'/LD rr,nn/8-bit ALU A,r/A,n/JP nn/JP cc,nn/JR e/JR cc,e/CALL nn/CALL cc,nn/RET/PUSH rr/POP rr/DI/EI/RLCA/EXX), with 16 golden-vector tests + 3 assemble→model cross-check tests, all passing. The assembler emits program.hex/.bin/.lst/.sym.json and computes JR displacements relative to the PC after the JR (the Z80 convention). A real program (LD A,0x0F; ADD A,1; LD B,A; JR loop; NOP; loop: LD C,0x22; PUSH BC; POP DE; HALT) assembles to 13 bytes and runs on the model with the expected state (A=0x10, B=0x10, C=0x22, D=0x10, E=0x22), proving the assembler's output is executable Z80 the oracle agrees with. This unblocks Phase 5/6: real programs can now be written, assembled, and (once integrated) run on the object graph and the board.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Build Phase 4 — the two-pass assembler with golden-vector and cross-check tests, committing and slip-printing.

**Inferred user intent:** A working assembler so real Z80 programs can be written and assembled for the object graph / board.

**Commit (code/docs):** (this step) Phase 4 assembler.

### What I did
- Wrote `tools/zasm.py` (~250 lines): two-pass assembler. Pass 1 parses to an IR (label/op/operands), strips comments, handles labels (`label:`), `.ORG`, and `label EQU value`, sizes each instruction (`size_of`), and assigns addresses. Pass 2 resolves symbols and emits bytes little-endian via `encode`. A tiny hand-written expression evaluator (`parse_imm`: literal/label ± offset, hex `0x`/`$`/decimal) — never `eval` (the sibling MATE-16 DR-9 safety rule). Outputs program.hex (one 2-digit byte/line for `$readmemh`), .bin, .lst, .sym.json.
- Covers: NOP/HALT/RET/DI/EI/RLCA/RRCA/RLA/RRA/EXX (1 byte); LD r,n / LD r,r' / LD rr,nn; ADD/ADC/SUB/SBC/AND/XOR/OR/CP A,r and A,n (the `ADD A,r` and `SUB r` forms); JP nn / JP cc,nn (all 8 cc); JR e / JR cc,e (NZ/Z/NC/C) with the displacement computed as `target - (addr+2)`; CALL nn / CALL cc,nn; PUSH/POP rr (BC/DE/HL/AF).
- Wrote `sim/test_assembler.py`: 16 tests — golden vectors for each form (LD r,n/r,r'/rr,nn; ALU A,n/r; JP/JR/CALL/PUSH/POP; DI/EI/RLCA/EXX; JR-label forward displacement) + 3 cross-checks (assemble→`z80_model.py` run→state matches: an ALU+JR+PUSH/POP loop program, a CALL/RET program, a backward-JR loop cap). Plus a determinism test.
- Fixed: the operand comma-split (the parser kept `LD A,0x42` as one string; added `split_operands`); LD rr,nn sizing (was 2, is 3); the `.ORG` parse (`int(...,0)` on `$`-hex); the JP/JR/CALL cc form (used `len(operands)>=2` not `","in operands[0]` since operands are pre-split); the JR-label test expectations (the displacement is `target-(addr+2)`, so a label after a NOP is +1 not +0).
- Wired `test_assembler` into the Makefile `test` target; full regression green (mesh + object graph + 49 model tests + 16 assembler tests).

### Why
Phase 4's exit (design doc §13) is "golden vectors byte-exact; deterministic; clear diagnostics" — the assembler is the bridge from human-written Z80 to the object graph and the board. Doing it now (after the core ISA in 3A-3F, before Phase 5 integration) means Phase 5 can write real programs, assemble them, and differential-test the integrated mesh+object graph against the model running the same assembled bytes. The no-`eval` rule (DR-9) matters because the assembler runs on student source files.

### What worked
- The two-pass structure (size → assign addresses → resolve → emit) handled forward references (JR to a label defined later) cleanly; the JR displacement formula `target-(addr+2)` matched the model.
- The cross-check tests (assemble→model run→state) are the strongest proof: they show the assembler's bytes are *executable* Z80, not just well-formed bytes. The ALU+JR+PUSH/POP program ran to A=0x10/B=0x10/C=0x22/D=0x10/E=0x22, exactly the hand-computed expectation.
- Golden vectors caught the LD rr,nn sizing bug (was 2 bytes, emitted out-of-range; the test failed, I fixed the sizer to 3).

### What didn't work
- **Operand comma-split**: the parser stored operands as one string (`"A, 0x42"`); `size_of`/`encode` expected a 2-element list. Fixed with `split_operands` (split on first comma).
- **LD rr,nn sizing** was 2 (the generic LD r,n default); the golden vector `LD BC,0x1234` failed; fixed the sizer to 3 for BC/DE/HL/SP.
- **`.ORG` with `$`-hex**: `int("$1000",0)` raises; added explicit `0x`/`$`/decimal handling.
- **JP/JR/CALL cc form**: the old `if "," in operands[0]` checked the wrong thing after the operand split (operands[0] is just "NZ"); fixed to `len(operands)>=2`.
- **JR-label test expectations**: I first wrote `18 00` (disp 0) but the label is after a NOP, so disp is +1; fixed the test (the assembler was right).

### What I learned
- The JR displacement convention (`target - (addr+2)`, relative to the PC after the 2-byte JR) is easy to get off-by-one; the cross-check against the model (which uses the same convention) is the safety net. Forward and backward JR both work.
- Two-pass with a tiny hand-written expression evaluator is enough for the baseline; `eval` would be shorter but unsafe (DR-9). The evaluator handles label, number, and `label±offset`, which covers every realistic addressing mode the baseline needs.
- The assembler + model + object graph now form a closed loop: write .asm → zasm.py → bytes → z80_model.py (oracle) AND → object graph (RTL), both expected to agree. Phase 5 closes the RTL half by loading the assembled bytes into the memory object.

### What was tricky to build
- Operand parsing consistently. Symptom: several tests failed with unpacking errors or "undefined symbol NZ" because the operand representation differed between `size_of` and `encode`. Resolution: a single `split_operands` helper used by both, returning a list split on the first comma.
- The JR displacement off-by-one (see What didn't work). The model and the assembler must use the *same* convention; the cross-check test is the proof they do.

### What warrants a second pair of eyes
- The `LD rr,nn` register-pair encoding (`0x01 | (rp<<4)`, rp=BC0/DE1/HL2/SP3) — the golden vector covers BC and HL; add DE and SP.
- The JR cc displacement for the *not-taken* path (the assembler emits the displacement regardless; the object graph's `cc_taken` decides). Confirm a JR cc that is not taken still advances PC past the 2 bytes (the object graph's S_JR_INC handles this; the assembler just emits the bytes).
- The ALU single-operand form (`SUB 3` without `A`) — the assembler accepts it and maps to `SUB A,3` (0xD6 03); confirm this matches the model (it does: the model's `_exec_main` ALU A,n path is reached by opcode 0xD6).

### What should be done in the future
- Phase 5: load the assembled `program.bin` into the object graph's `obj_memio` ROM (replace the testbench's manual `rom[i]=` writes) and differential-test the integrated object graph against the model running the same assembled program.
- Add the memory-operand LDs (LD r,(HL)/(HL),r/LD A,(BC)/(DE)/(nn)) and 16-bit (3D) to both the assembler and the object graph so real programs can touch memory.
- Add a disassembler (`zdis.py`) for the message-trace debug view (design-doc §11.2).

### Code review instructions
- `cd pca_z80 && make test_assembler` — expect `16 passed`.
- `make test` — expect mesh PASS, object graph 3A-3F PASS, 49 model tests, 16 assembler tests.
- `python3 tools/zasm.py programs/<x>.asm -o build -n <x>` then inspect `build/<x>.hex` and `.lst`.
- Read `tools/zasm.py` `size_of`/`encode`/`split_operands`/`parse_imm`; confirm no `eval`.

### Technical details
- Files: `tools/zasm.py` (~250 lines), `sim/test_assembler.py` (16 tests).
- Outputs: program.hex (2-digit/line for $readmemh), .bin, .lst, .sym.json.
- Cross-check program (13 bytes): LD A,0x0F; ADD A,1; LD B,A; JR loop; NOP; loop: LD C,0x22; PUSH BC; POP DE; HALT → A=0x10 B=0x10 C=0x22 D=0x10 E=0x22, count=8. Model agrees.
- `make test`: mesh + object graph (3A-3F) + 49 model + 16 assembler tests.
- Slips: P4 START printed. P4 DONE to follow.

## Step 13: Build Phase 5 — integration (assembled programs on the object graph, differential vs the model)

This step closed the loop: an integration testbench (`tb_z80_integ.sv`) loads an assembled program into the object graph's memory object via `$readmemh`, and a Python differential harness (`run_integ.py`) assembles a program, runs it on both the `z80_model.py` oracle and the object-graph testbench, and compares the retired state. Six integration tests pass — five inline programs (smoke LD, ALU, JR/CP loop, CALL/RET, PUSH/POP) and the shipped `programs/selftest.asm` (a JR/CP loop that counts A to 3 then CALLs a subroutine adding 5, reaching the magic final state A=8) — all matching the model byte-for-byte. The object graph now runs real assembled Z80 programs end-to-end, differential-tested against the oracle on the same bytes. This is the Phase 5 exit (design-doc §13: "assembled Z80 runs on the mesh in simulation; differential suite zero divergence; selftest reaches the magic address").

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Build Phase 5 — integration: load the assembler's output into the object graph and differential-test the integrated core against the model on the same assembled bytes, with a selftest reaching a magic final state.

**Inferred user intent:** Prove the object graph runs *real* Z80 programs (not just hand-loaded testbench bytes), and that it agrees with the model — the closed loop that unblocks Phase 6 (FPGA/hardware).

**Commit (code/docs):** (this step) Phase 5 integration.

### What I did
- Wrote `sim/tb_z80_integ.sv`: a parameterized testbench that clears the memory object's ROM, loads a `.hex` file via `$readmemh(ROM_FILE, dut.u_memio.rom)`, resets, runs 20000 cycles, and dumps the retired state (PC/R/SP/COUNT/HALTED/FAULTED/A/B/C/D/E/F) to `build/integ_state.txt` for the harness to read.
- Wrote `sim/run_integ.py`: assembles a `.asm` with `zasm.py`, writes `build/integ.hex`, runs the model (`z80_model.py`) and the RTL testbench (iverilog + vvp with `-pvalue=ROM_FILE=...`), parses the dumped RTL state, and compares the 12 fields (PC/R/SP/COUNT/HALTED/FAULTED/A/B/C/D/E/F), printing PASS or the divergences.
- Wrote `programs/selftest.asm`: the acceptance program — `LD A,0; loop: ADD A,1; CP 3; JR NZ,loop; CALL add5; HALT; add5: ADD A,5; RET` → final A=8. Uses only implemented instructions (the baseline lacks INC/DEC r, so the loop uses CP against a constant target).
- Wrote `sim/test_integ.py`: 6 pytest tests — 5 inline programs (smoke, alu, loop, call, stack) + the shipped selftest — each running `run_integ.py` and asserting PASS + (for selftest) A=8.
- Wired `test_integ` into the Makefile `test` target; full regression green (mesh + object graph + 49 model + 16 assembler + 6 integration tests).

### Why
Phase 5's exit (design doc §13) is "assembled Z80 runs on the mesh in simulation; differential suite zero divergence; selftest reaches the magic address." The integration testbench + harness are the mechanism: until now, the object graph ran hand-loaded testbench bytes (tb_z80_core.sv's `run_prog`); now it runs the assembler's real output, and the same bytes go to the model, so any divergence is a real bug. This is the closed loop the design doc promised: `.asm → zasm.py → .hex → object graph`, differential vs `z80_model.py`.

### What worked
- `$readmemh` into the memory object's ROM worked on the first try (the ROM is a plain `logic [7:0] rom [0:N-1]`); the `-pvalue=ROM_FILE=...` iverilog flag parameterized the file per run.
- The selftest reaching A=8 (3 loop iterations + CALL add5) exercises LD, ALU A,n, CP, JR NZ (taken and not-taken), CALL, RET, HALT — the whole implemented ISA in one program, and the model and RTL agree on count=14, PC=12, F=0x08.
- The JR/CP loop pattern (`ADD A,1; CP N; JR NZ,loop`) sidesteps the missing INC/DEC r: the loop exits when A reaches N, no counter register needed. This is the baseline's workaround until 3D adds INC/DEC rr and 3F.5 adds INC/DEC r.

### What didn't work
- **Three broken selftest drafts** (I wrote `DEC-ish:` and `ADD B,1` placeholders that don't assemble) before the clean CP-loop version. The baseline lacks INC r/DEC r, so a counter loop needs the CP-against-constant trick; I kept drafting loops that assumed INC/DEC. Resolution: committed to the CP-loop pattern and the clean selftest assembled and ran on the first try.
- **A too-strict pytest assertion** (`'A': 8` after `replace(" ","")` mismatched the spacing); fixed to check the raw `'A': 8` substring (the harness already asserts full state equality, so the A=8 check is just a sanity confirmation).

### What I learned
- The integration harness is the highest-value test in the project: it runs the *assembled* bytes (real programs) through both the model and the RTL, so it catches any drift between the assembler, the model, and the object graph in one shot. It's the Phase 5 gate and will be the Phase 6 hardware-acceptance oracle too.
- `$readmemh` + a parameterized ROM file is the clean way to feed assembled programs to a Verilog testbench without a cocotb dependency — fits the OSS-CAD-only constraint.
- The CP-loop trick (loop until A reaches a constant) is a general workaround for the missing INC/DEC r; it also tests the flags→JR-cc path, which is more coverage than a simple counter.

### What was tricky to build
- The selftest program (see What didn't work) — writing a non-trivial program with only the implemented instructions (no INC/DEC, no memory-operand LD, no 16-bit) that still exercises control flow + stack. The CP-loop + CALL/RET combination is the minimal such program.
- The iverilog `-pvalue` parameter passing for the ROM file — needed the `#(parameter string ROM_FILE=...)` testbench signature and the `-pvalue=ROM_FILE="path"` flag; verified by the first run.

### What warrants a second pair of eyes
- The 20000-cycle run cap in tb_z80_integ — generous for the selftest (14 instructions) but a runaway program (infinite loop) would hit the watchdog at 5ms; confirm the cap is > any real program's cycle count (it is, by ~1000x).
- The state-dump fields (PC/R/SP/COUNT/HALTED/FAULTED/A/B/C/D/E/F) — the harness compares 12 fields; confirm the model and RTL use the same reset SP (0xFFFF) so SP matches (it does; both reset SP to 0xFFFF).
- The `selftest.asm` `CP 3` — CP sets flags but leaves A unchanged; the loop adds 1 each iteration until A=3, then JR NZ (Z set by CP 3) falls through. Confirm CP 3 when A=3 sets Z (the model says yes; the RTL's obj_alu CP path sets Z).

### What should be done in the future
- Phase 6: synthesize the full z80_core + the Phase 1 PCA mesh into a GateMate bitstream (the mesh isn't wired to the Z80 yet — that's the DR-7 "bus becomes mesh channels" step, which the design doc defers to Phase 5/6; for the baseline hardware demo, synthesize z80_core alone with a top that loads the program ROM and drives the LED from a GPIO port). Then load to the board and observe the LED.
- Add INC/DEC r (3F.5) so the selftest can use a real counter; add memory-operand LDs and 16-bit (3D) so programs can touch RAM.
- Add a constrained-random integration fuzzer: generate random valid programs, assemble, run model + RTL, assert zero divergence with recorded seeds (the design-doc §4.8 differential discipline).

### Code review instructions
- `cd pca_z80 && python3 sim/run_integ.py programs/selftest.asm` — expect `PASS`, A=8.
- `make test` — expect mesh PASS, object graph 3A-3F PASS, 49 model, 16 assembler, 6 integration tests.
- Read `sim/tb_z80_integ.sv` (`$readmemh` + state dump) and `sim/run_integ.py` (assemble → model + RTL → compare).

### Technical details
- Files: `sim/tb_z80_integ.sv` (parameterized ROM-load testbench), `sim/run_integ.py` (differential harness), `sim/test_integ.py` (6 pytest tests), `programs/selftest.asm` (acceptance program, A=8).
- selftest: 15 bytes, runs to A=8, PC=12, count=14, F=0x08; model and RTL agree on all 12 fields.
- `make test`: mesh + object graph + 49 model + 16 assembler + 6 integration tests.
- Slips: P5 START printed. P5 DONE to follow.

## Step 14: Build Phase 6 — FPGA synthesis/PnR/timing + board top (hardware load pending board access)

This step brought the Z80 object graph to a GateMate bitstream: added a GPIO output port to `obj_memio` (write to address 0x0000 → gpio_out, the baseline I/O map), added `LD (nn),A` to the decode (so a Z80 program can drive the GPIO), wrote the `programs/blink.asm` hardware demo (LD A,0x01; LD (0x0000),A; HALT → LED on), and a board-facing `top.sv` wiring the core to the GateMate pins with the program ROM initialized at synthesis via `$readmemh` (a `-DROM_FILE` macro). `make bit` (Yosys synth_gatemate → nextpnr → gmpack) produces a 220KB bitstream; the full Z80 places at **6026 LUTs (14%), 2451 FFs (5%), max frequency 51.41 MHz (PASS at 10 MHz, 5× margin)**. The blink demo drives GPIO bit 0 high in simulation (verified). The physical board is not connected (no FTDI device), so the `openFPGALoader` load + LED observation is the one remaining step, gated on physical access.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Build Phase 6 — synthesize the Z80 object graph to a GateMate bitstream, wire a board top, and (if the board is present) load it and observe the LED driven by Z80 instructions.

**Inferred user intent:** A real FPGA bitstream proving the Z80 object graph is hardware, with the LED driven by Z80 code (the Phase 6 acceptance).

**Commit (code/docs):** (this step) Phase 6 synth/PnR/timing + board top.

### What I did
- Extended `obj_memio.sv`: added a `gpio_out` port; a write to address 0x0000 hits the GPIO output register (the baseline I/O map), other writes hit RAM. ROM init moved to a `ROM_FILE` macro (`$readmemh(\`ROM_FILE, rom)`) with a default, so the same module works in sim (testbench `$readmemh` overrides) and synth (Yosys `-DROM_FILE=...`).
- Added `LD (nn),A` (0x32) to `obj_decode.sv` (6 states: fetch addr lo/hi with PC incs, read A, write A to mem[addr]) and to `zasm.py`, so a Z80 program can drive the GPIO. Added `is_ld_a_nn` helper + the S_LDNA_* states.
- Wrote `programs/blink.asm`: `LD A,0x01; LD (0x0000),A; HALT` → LED on (the minimal "Z80 drives the LED" demo; a blinking loop needs INC/DEC r for the delay, which is 3D/3F.5).
- Wrote `rtl/top.sv`: board-facing top wiring z80_core to the GateMate pins (clk_10m, user_led ← gpio[0], uart_tx_pin idle-high) with `CC_USR_RSTN u_cfg_reset (.USR_RSTN(cfg_rst_n))` (the sibling's named-connection form, which binds the primitive; my first cut `CC_USR_RSTN cc_rstn ()` left USR_RSTN undriven and Yosys constant-folded the whole core to a static LED).
- Wired the full Z80 build into the Makefile (`synth` assembles the program → top_prog.hex, then Yosys with `-DROM_FILE`; `make bit` does synth→pnr→pack).
- Verified the blink demo in sim with a quick GPIO testbench: `gpio=01, count=3, halted` → PASS (LED driven high by Z80 instructions).
- Built the bitstream: `make bit` → `build/top.bit` (220KB). Resources: 6026 CPE_LT (14%), 2451 CPE_FF (5%); timing 51.41 MHz max (PASS at 10 MHz, 5× margin).
- Checked for the board: `openFPGALoader --detect` → "unable to open ftdi device" (not connected). The load + LED observation is deferred to physical board access.

### Why
Phase 6's exit (design doc §13) is "synthesis/PnR/timing clean; hardware bring-up; bytecode-driven LED." The synthesis/PnR/timing half is done with a strong margin (5×); the hardware-load half needs the physical board, which isn't present. The blink demo (Z80 `LD A,1; LD (0),A; HALT` drives the LED) is the bytecode-driven-LED acceptance, proven in sim and ready to load. Doing the synth/PnR now (not deferring to a later session) proves the object graph is real hardware — 6026 LUTs is ~14% of the CCGM1A1, leaving ample room for the PCA mesh (Phase 1's 3×3 was ~12.5k cells) and the 3D/3F.5 instructions.

### What worked
- The GPIO-via-memory-write trick (write addr 0x0000 → GPIO) gave a working I/O path without an OUT instruction (not yet in the object graph), unblocking the hardware demo with a 6-state decode addition.
- The `ROM_FILE` macro + `$readmemh` let one `obj_memio` work in both sim (testbench overrides the ROM after init) and synth (Yosys `-DROM_FILE`), avoiding a sim/synth split.
- The sibling's `CC_USR_RSTN u_cfg_reset (.USR_RSTN(cfg_rst_n))` named-connection form was the fix for the constant-fold: once the reset was live, the FSM couldn't be optimized away and the real 6026-LUT design placed.
- Timing closed at 51 MHz / 10 MHz target — 5× margin, matching the sibling MATE-16's ~2× but for a more complex CPU.

### What didn't work
- **`CC_USR_RSTN cc_rstn ()` with no port connection** — left USR_RSTN undriven, so Yosys constant-folded the whole core to a static LED=1 (0 CPE cells, 181-byte bitstream). Fixed with the sibling's named-connection form.
- **`string` parameter for ROM_FILE** — Yosys rejected `parameter string ROM_FILE`; fixed with the `-DROM_FILE` macro approach.
- **`\`ifdef ROM_FILE` after a for-loop** — Yosys syntax error; simplified to always `$readmemh(\`ROM_FILE)` with a `ifndef default.
- **Board not connected** — `openFPGALoader --detect` finds no FTDI; the load step is deferred (not a bug, a physical-access gate).

### What I learned
- A live reset is what prevents Yosys from constant-folding a CPU: without `CC_USR_RSTN` driving the reset_sync, the FSM's initial state + constant program optimize to a static output. The named-connection form of the primitive is required (the positional `()` form leaves the output undriven).
- The Z80 object graph at 6026 LUTs / 2451 FFs is comfortably small on the CCGM1A1 (14%/5%) — the full PCA mesh + object graph (the Phase 7 integration) will fit. The 51 MHz fmax means a 10 MHz board clock is trivially met.
- Memory-mapped GPIO (write addr 0 → port) is a clean baseline I/O scheme that needs no new bus object; it reuses obj_memio's address decode. A real Z80 OUT instruction (port I/O space) is a 3F.5 add.

### What was tricky to build
- The constant-fold (see What didn't work). Symptom: 0 CPE cells after PnR. Cause: the reset primitive's output was undriven, so reset_sync's `rst_n` was X, the FSM never left reset, the constant program optimized the LED to a static 1. Diagnosis: the "no interior timing paths" + 0 CPE in the nextpnr report. Fix: the sibling's `CC_USR_RSTN u_cfg_reset (.USR_RSTN(cfg_rst_n))` form binds the primitive's output.
- ROM init across sim/synth. Symptom: a `string` parameter doesn't synthesize; a hard-coded `$readmemh("build/...")` breaks the testbench's per-program override. Resolution: the `ROM_FILE` macro with a default, overridden by Yosys `-DROM_FILE` for synth and by the testbench's own `$readmemh` for sim (the testbench reads after the initial fill, so it wins).

### What warrants a second pair of eyes
- The 51 MHz fmax — confirm the report's "u_core.clk" is the z80_core's clk (it is; the only clock). The 5× margin is comfortable; verify it holds after the 3D/3F.5/prefix additions (more states may lengthen the decode path).
- The 6026 LUTs vs the Phase 1 mesh's ~12.5k cells — the full mesh+core will be ~18k cells, ~44% of the CCGM1A1; confirm the mesh is needed for the baseline demo or if the core alone (this top) suffices for Phase 6 (it does: the LED demo runs on the core directly; the mesh is the Phase 7 reconfigurable refinement).
- The blink demo's "LED on then halt" — a reviewer may want a *blinking* LED; that needs INC/DEC r (3F.5) for the delay loop. Document that the Phase 6 acceptance is "LED driven by Z80 instructions" (proven), not necessarily blinking.

### What should be done in the future
- **Load the bitstream to the board** when it's connected: `openFPGALoader -b olimex_gatemateevb build/top.bit` and observe the LED lit (the one deferred step).
- 3F.5: add INC/DEC r so `blink.asm` can loop a delay for a *blinking* LED (the stronger Phase 6 demo).
- 3D: 16-bit ADD HL,rr + INC/DEC rr; 3F.5: OUT/IN (real port I/O) and the memory-operand LDs; then the full mesh integration (Phase 7) maps the objects to PCA cells.
- Engineering report (design-doc §4.20): architecture, software, verification, implementation, hardware results (6026 LUTs, 51 MHz), limitations (no INC/DEC/prefixes/memory-LD yet).

### Code review instructions
- `cd pca_z80 && make bit` — expect `build/top.bit` (220KB).
- `make test` — expect mesh + object graph + 49 model + 16 assembler + 6 integration tests PASS.
- Inspect `build/nextpnr.log`: CPE_LT 6026/40960 (14%), CPE_FF 2451/40960 (5%), Max frequency 51.41 MHz PASS at 10 MHz.
- Read `rtl/top.sv` (board wiring + `CC_USR_RSTN` named connection) and `rtl/obj_memio.sv` (GPIO port + ROM_FILE macro).
- For the board load (when connected): `openFPGALoader -b olimex_gatemateevb build/top.bit`.

### Technical details
- Files: `rtl/obj_memio.sv` (+gpio_out, +ROM_FILE macro), `rtl/obj_decode.sv` (+LD (nn),A: 6 states), `rtl/z80_core.sv` (+gpio_out), `rtl/top.sv` (board top, CC_USR_RSTN named), `tools/zasm.py` (+LD (nn),A), `programs/blink.asm` (LED-on demo), `Makefile` (full Z80 synth/bit).
- Synth: 0 errors; 6026 CPE_LT (14%), 2451 CPE_FF (5%), 184 CC_ADDF; bitstream 220KB.
- Timing: Max frequency 51.41 MHz (PASS at 10 MHz, 5× margin).
- Sim blink: gpio=01, count=3, halted → LED driven high by Z80 instructions.
- Board: not connected (no FTDI); load + LED observation deferred to physical access.
- `make test`: mesh + object graph + 49 model + 16 assembler + 6 integration tests.
- Slips: P6 START printed. P6 done slip to follow (synth/PnR/timing done; board load pending).

## Step 15: Build Phase 3 — milestone 3F.5 (INC/DEC r + blinking-LED demo)

This step added INC/DEC r (the most-used Z80 instruction) to the ALU and decode, porting the model's `_inc8`/`_dec8` flag model (which *preserves C*, unlike ADD/SUB). Three differential tests pass against the oracle: INC B (0x7F→0x80, S+PV), DEC A (0→0xFF, N+H+S), and a DEC B countdown loop (B→0). With INC/DEC r, the `programs/blink.asm` demo now *blinks* the LED (LD A,1; LD (0),A; DEC B loop; LD A,0; LD (0),A; DEC B loop; JR start) — verified in sim with both on and off cycles observed, driven entirely by Z80 instructions. This is the stronger Phase 6 acceptance (a blinking LED, not just LED-on), and the core synthesizes clean. The C-preservation subtlety (INC/DEC must not touch C) required the ALU to receive the current flags.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Add INC/DEC r (3F.5) — the high-value instruction that unblocks real counter loops and a blinking-LED demo — differential-tested against the oracle, and strengthen the Phase 6 demo to a real blink.

**Inferred user intent:** A Z80 that can loop and count (INC/DEC), and a blinking LED (not just on) as the Phase 6 hardware acceptance.

**Commit (code/docs):** (this step) Phase 3F.5 INC/DEC r + blink.

### What I did
- Extended `z80_obj.sv` with ALU_INC/ALU_DEC sub-ops (indices 8/9, beyond the 0-7 ALU_OPS). ALU contract for INC/DEC: wdata={value, cur_flags}, rdata={new_flags, result} where new_flags preserves C from cur_flags.
- Extended `obj_alu.sv` with ALU_INC/ALU_DEC cases, porting `_inc8`/`_dec8` exactly: S/Z/H/PV (no N for INC, N for DEC), H from `(a&0xF)==0xF` (INC) / `==0x00` (DEC), PV from `r8==0x80` (INC) / `0x7F` (DEC), and `fl | (cur_f & F_C)` to preserve carry. Added a `cur_f` wire = wdata[7:0].
- Added 5 decode states (S_INCR_READ_R → S_INCR_READ_F → S_INCR_ALU → S_INCR_WRITE_R → S_INCR_WRITE_F) and `is_inc_r`/`is_dec_r` helpers (opcodes 0x04/0x0C/.../0x3C for INC, 0x05/0x0D/.../0x3D for DEC, r=(opc>>3)&7, excluding (HL)=6). The decode reads r, reads flags (for C preservation), issues the ALU op with {value,cur_flags}, writes r, writes flags.
- Added INC/DEC r to `zasm.py` (1-byte encoding `0x04|(r<<3)` / `0x05|(r<<3)`).
- Added 3 differential tests to `tb_z80_core.sv`: 3F5a INC B 0x7F→0x80 (S+PV), 3F5b DEC A 0→0xFF (N+H+S), 3F5c DEC B countdown loop (B→0).
- Rewrote `programs/blink.asm` as a real blink loop (LD A,1; LD (0),A; DEC B loop; LD A,0; LD (0),A; DEC B loop; JR start) — verified with a GPIO testbench that observes both on (12096) and off (7904) cycles over 20000 cycles, not faulted.
- Confirmed synthesis (0 errors) and the full regression (mesh + object graph with INC/DEC + 49 model + 16 assembler + 6 integration tests).

### Why
INC/DEC r is the most-used Z80 instruction and the key that unblocks real counter loops (and thus a *blinking* LED, the stronger Phase 6 acceptance). The C-preservation subtlety (INC/DEC must not touch C, unlike ADD/SUB which set it) is exactly the kind of flag-model detail the model-first discipline catches — porting `_inc8`/`_dec8` verbatim and passing the current flags to the ALU made it correct on the first run.

### What worked
- The ALU-receives-current-flags design (wdata={value,cur_flags}) cleanly handled C preservation: `fl | (cur_f & F_C)` keeps carry while INC/DEC set the other flags. This generalizes to any flag-preserving op (RLD/RRD later).
- The DEC B countdown loop (B→0 via JR NZ) is the minimal real loop and exercised both DEC (flags) and JR NZ (reads Z) — strong coverage in one test.
- The blink GPIO testbench (counting on vs off cycles) is a stronger acceptance than LED-on: it proves the LED actually toggles, driven by Z80 code.

### What didn't work
- **A bad test opcode**: I first wrote the DEC B loop as `06 03 10 FD 76` (0x10 = DJNZ, not DEC B); the loop didn't run (B stayed 3). Fixed to `06 03 05 20 FD 76` (0x05 = DEC B, 0x20 = JR NZ). The differential test caught it immediately.
- **`cur_f` wire not declared** (the first edit's always_comb block didn't apply); iverilog reported "Unable to bind cur_f" — fixed by adding the declaration.

### What I learned
- INC/DEC preserving C (while setting S/Z/H/PV/N) is the Z80's flag-model subtlety that distinguishes it from ADD/SUB; the ALU's `{value, cur_flags}` contract handles it in one place.
- A blinking LED needs only LD, DEC, JR, and LD (nn),A — all in the baseline — so the Phase 6 demo is now a real blink, the textbook acceptance.
- The DEC-r-then-JR-NZ loop is the universal Z80 countdown idiom; getting it differential-clean against the oracle means the loop primitive is trustworthy for all later programs.

### What was tricky to build
- The C-preservation path (see What didn't work / What worked). The ALU must see the current flags; passing them in the wdata low byte (reusing the b field) avoids a new bus field.
- The blink loop timing — the inner DEC B loop (256 iterations) is short for sim; on the 10 MHz board it blinks fast (extend/nest the loop for a human-visible rate, a Phase 7 polish).

### What warrants a second pair of eyes
- The INC/DEC flag formulas (H from nibble boundary, PV from 0x80/0x7F) — the 3F5a/3F5b tests cover the boundary cases; add an INC 0xFF→0x00 (Z+H) test.
- The C-preservation across an INC after a carry-setting SUB — add a test (SUB sets C, INC preserves it).
- The blink rate on hardware — confirm it's visible (may need a longer/nested delay loop; the sim only proves it toggles).

### What should be done in the future
- 3D: 16-bit ADD HL,rr + INC/DEC rr + LD rr,nn (reuses the 16-bit pair access from 3F; ADD HL needs a 16-bit ALU path).
- Memory-operand LDs (LD r,(HL)/(HL),r/LD A,(BC)/(DE)/(nn)) so programs can touch RAM.
- The DD/FD/CB/ED prefixes (IX/IY, shifts/bits, block).
- Nest the blink delay loop (or use a 16-bit BC countdown) for a human-visible board blink rate.

### Code review instructions
- `cd pca_z80 && make sim_core` — expect `PASS: ... INC/DEC ... matches oracle`.
- `make test` — expect mesh + object graph (with INC/DEC) + 49 model + 16 assembler + 6 integration.
- Blink: `python3 tools/zasm.py programs/blink.asm -o build -n blink` then the GPIO testbench observes on+off cycles.
- Read `obj_alu.sv` ALU_INC/ALU_DEC cases against `z80_model.py` `_inc8`/`_dec8` (C preservation).

### Technical details
- Files: `rtl/z80_obj.sv` (+ALU_INC/DEC), `rtl/obj_alu.sv` (+INC/DEC cases, +cur_f), `rtl/obj_decode.sv` (+5 INC/DEC states, +helpers), `tools/zasm.py` (+INC/DEC), `sim/tb_z80_core.sv` (+3 tests), `programs/blink.asm` (real blink loop).
- Oracle: INC 7F→80 (S+PV), DEC 0→FF (N+H+S), DEC B loop → B=0. RTL matches.
- Blink sim: on=12096, off=7904 over 20000 cycles, not faulted → LED toggles.
- Synth: 0 errors. `make test` green.
- Slips: P6 done (Step 14). 3F.5 milestone slip to follow.

## Step 16: Build Phase 3 — milestone 3D (16-bit: LD rr,nn / INC rr / DEC rr / ADD HL,rr)

This step added the 16-bit register-pair operations (LD rr,nn, INC rr, DEC rr, ADD HL,rr) reusing the 16-bit pair access added to obj_regfile in 3F (indices 9=BC,10=DE,11=HL; SP lives in obj_pc). Three differential tests pass against the oracle: ADD HL,BC (LD BC,2; LD HL,0x0FFF; ADD HL,BC → HL=0x1001, H set), INC BC (0xFFFF→0x0000), DEC HL (0→0xFFFF). ADD HL,rr correctly sets only H/C/N (preserving S/Z/PV, copying F5/F3 from the result high byte — the model's `_add16` semantics). The decode added ~16 states for the four ops, handling the SP-vs-regfile split (rp 3 = SP in obj_pc via SP_SET/SP_INC/SP_DEC/SP_READ; rp 0-2 = regfile pairs). Synth clean; full regression green.

### Prompt Context

**User prompt (verbatim):** (see Step 1)

**Assistant interpretation:** Add 3D — the 16-bit register-pair ops (LD rr,nn, INC/DEC rr, ADD HL,rr), differential-tested against the oracle, reusing the 16-bit pair access from 3F.

**Inferred user intent:** A Z80 with 16-bit arithmetic so programs can use loop counters and pointer arithmetic (HL/BC/DE/SP), the common 16-bit idiom.

**Commit (code/docs):** (this step) Phase 3D 16-bit.

### What I did
- Added helpers: `rp_of` (rp=(opc>>4)&3), `is_ld_rr_nn`/`is_inc_rr`/`is_dec_rr`/`is_add_hl_rr` (the 0x01/0x03/0x0B/0x09 families), `pair_idx_of` (rp 0-2 → regfile idx 9-11; rp 3 = SP handled via obj_pc).
- Added ~16 decode states: S_LDRR_LO/INC1/HI/INC2/WRITE (LD rr,nn); S_INCRR_READ/WRITE and S_DECRR_READ/WRITE (INC/DEC rr, no flags); S_ADDHL_READ_HL/READ_RR/WRITE/READ_F/WRITE_F (ADD HL,rr with H/C/N flags preserving S/Z/PV).
- The SP split: rp 3 reads/writes SP via obj_pc (SP_READ/SP_SET/SP_INC/SP_DEC); rp 0-2 via the regfile pair access. Stashed rp in r_src[1:0].
- ADD HL,rr flags: computed H (bit-11 carry) and C (bit-15 carry) in S_ADDHL_READ_RR, then S_ADDHL_READ_F reads current F and S_ADDHL_WRITE_F writes `(F & S|Z|PV) | H|C | (result_hi & F5|F3)` (clearing N), matching the model's `_add16`.
- Added 16-bit ops to zasm.py (INC/DEC rr = 0x03/0x0B | rp<<4; ADD HL,rr = 0x09 | rp<<4; LD rr,nn already existed).
- Added 3 differential tests (3D1 ADD HL,BC → 0x1001 H; 3D2 INC BC 0xFFFF→0; 3D3 DEC HL 0→0xFFFF).
- Confirmed synthesis (0 errors) and the full regression. Verified the ADD HL,BC integration via run_integ.py (model==RTL) as a cross-check.

### Why
3D's exit (design doc §13) is "16-bit + IX/IY" — the 16-bit half (LD rr,nn/INC/DEC rr/ADD HL,rr) is the high-value part (loop counters, pointer arithmetic); IX/IY (the DD/FD prefixes) is a larger add deferred to the prefix milestone. Reusing the 3F regfile pair access meant INC/DEC rr and LD rr,nn were 2-state read-modify-writes; only ADD HL,rr needed the flag-merge subtlety (preserve S/Z/PV, set H/C/N, copy F5/F3).

### What worked
- The 16-bit pair access (idx 9-12) from 3F made INC/DEC rr and LD rr,nn trivial (read pair, ±1 or load, write pair, no flags). The SP split (obj_pc for rp 3) was a clean if/else per state.
- The integration harness (run_integ.py) confirmed ADD HL,BC model==RTL before I fixed the tb_z80_core watchdog, isolating the testbench issue from the RTL.
- The ADD HL flag-merge (read F, keep S/Z/PV, set H/C, clear N, copy F5/F3) matched the oracle's `_add16` exactly (F=0x10 = H for the 0xFFF+2 case).

### What didn't work
- **Stale vvp after a watchdog edit** — I edited the tb_z80_core watchdog from 1ms to 5ms but didn't recompile; the old vvp still fired at 1ms and I misread it as a 3D hang. Recompiling showed all 3D tests pass. (The integration harness passing was the clue that the RTL was fine.)
- **Enum overflow** (~50 states in 6 bits) — widened to 7 bits.

### What I learned
- The SP-vs-regfile split is the main complexity of 16-bit ops: SP lives in obj_pc (a different slave), so every 16-bit read/write branches on rp==3. Keeping SP in obj_pc (not the regfile) was the 3F design choice; 3D bears the cost but it's a clean per-state if/else.
- ADD HL,rr's flag model (preserve S/Z/PV, set H/C/N, copy F5/F3) is distinct from the 8-bit ALU; doing it in the decode (not obj_alu) avoided widening the ALU's rdata to fit a 16-bit result + flags. A 16-bit ALU object is a future refactor if more 16-bit ops appear.
- The integration harness is the fastest debugger: it runs the same assembled bytes through model + RTL, so a pass there isolates testbench issues from RTL bugs.

### What was tricky to build
- The ADD HL flag preservation. Symptom: a naive write of just H/C/N would clobber S/Z/PV. Resolution: S_ADDHL_READ_F reads the current F, and S_ADDHL_WRITE_F writes the merged `(F & 0xC4) | H | C | (result_hi & 0x28)` (N cleared by omission).
- The SP-split across read and write states (each of S_LDRR_WRITE/S_INCRR_READ+WRITE/S_DECRR_READ+WRITE/S_ADDHL_READ_RR branches on rp==3 for obj_pc vs regfile). Verbose but mechanical.

### What warrants a second pair of eyes
- The ADD HL flag F5/F3 copy (`add16_res[15:8] & 0x28`) — the model's `_add16` does `f |= (r>>8) & (F_F5|F_F3)`; the RTL matches (3D1 has result 0x1001, high byte 0x10, F5/F3 = 0, so not exercised — add a test with a result high byte having bits 5/3 set).
- The SP variants (ADD HL,SP, INC SP, DEC SP, LD SP,nn) — 3D1-3D3 test BC/HL; add SP tests.
- The DEC rr wrap (0x0000 → 0xFFFF) — 3D3 covers HL; confirm BC/DE/SP wrap too.

### What should be done in the future
- Memory-operand LDs (LD r,(HL)/(HL),r/LD A,(BC)/(DE)/(nn)/LD (nn),A) so programs can touch RAM — the last big ISA gap before the prefixes.
- The DD/FD (IX/IY), CB (shifts/bits), ED (block) prefixes — the largest remaining ISA add.
- A 16-bit ALU object (refactor ADD HL out of the decode) if more 16-bit ops appear (ADC HL, SBC HL — not in the baseline).

### Code review instructions
- `cd pca_z80 && make sim_core` — expect `PASS: ... 16-bit ... matches oracle`.
- `make test` — expect mesh + object graph (with 16-bit) + 49 model + 16 assembler + 6 integration.
- `python3 sim/run_integ.py <t3d.asm>` (LD BC,2; LD HL,0x0FFF; ADD HL,BC; HALT) — expect PASS, HL=0x1001.
- Read `obj_decode.sv`'s S_LDRR_*/S_INCRR_*/S_DECRR_*/S_ADDHL_* states and the `pair_idx_of`/`rp_of` helpers.

### Technical details
- Files: `rtl/obj_decode.sv` (+~16 16-bit states, +helpers), `tools/zasm.py` (+INC/DEC rr, ADD HL,rr).
- Oracle: ADD HL,BC → HL=0x1001 H; INC BC 0xFFFF→0; DEC HL 0→0xFFFF. RTL matches.
- Synth: 0 errors. `make test` green (mesh + object graph + 49 model + 16 asm + 6 integ).
- Enum widened to 7 bits (~50 states).
- Slips: 3F.5 done (Step 15). 3D milestone slip to follow.

## Related

- `sources/SOURCES.md` — the evidence-anchored source index.
- Design doc `design-doc/01-pca-z80-system-intern-onboarding-guide.md` — the intern guide (Step 2).
- Sibling workspace `../2026-08-25--vm-cpu-gatemate/` — MATE-16, the structural template and toolchain reference.
