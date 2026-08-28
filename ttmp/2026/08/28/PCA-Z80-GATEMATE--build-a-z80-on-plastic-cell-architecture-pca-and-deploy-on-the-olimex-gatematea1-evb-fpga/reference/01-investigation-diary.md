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

## Related

- `sources/SOURCES.md` — the evidence-anchored source index.
- Design doc `design-doc/01-pca-z80-system-intern-onboarding-guide.md` — the intern guide (Step 2).
- Sibling workspace `../2026-08-25--vm-cpu-gatemate/` — MATE-16, the structural template and toolchain reference.
