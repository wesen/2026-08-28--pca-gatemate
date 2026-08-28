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

## Related

- `sources/SOURCES.md` — the evidence-anchored source index.
- Design doc `design-doc/01-pca-z80-system-intern-onboarding-guide.md` — the intern guide (Step 2).
- Sibling workspace `../2026-08-25--vm-cpu-gatemate/` — MATE-16, the structural template and toolchain reference.
