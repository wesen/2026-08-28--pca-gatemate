---
Title: Build a Z80 on Plastic Cell Architecture (PCA) and deploy on the Olimex GateMateA1-EVB FPGA
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
DocType: index
Intent: long-term
Owners: []
RelatedFiles:
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/SOURCES.md
      Note: Evidence-anchored index of the collected PCA primary sources
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/design-doc/01-pca-z80-system-intern-onboarding-guide.md
      Note: The intern onboarding guide (the main deliverable)
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/reference/01-investigation-diary.md
      Note: The chronological investigation diary
    - Path: /home/manuel/code/wesen/2026-08-25--vm-cpu-gatemate/README.md
      Note: Sibling MATE-16 project — toolchain, board pins, conventions reused here
ExternalSources: []
Summary: Build a Z80 microprocessor as a graph of wired-logic objects on Plastic Cell Architecture (PCA) and deploy it on the Olimex GateMateA1-EVB FPGA, reusing the sibling MATE-16 toolchain and verification methodology.
LastUpdated: 2026-08-28T14:40:00-04:00
WhatFor: Coordinate the research, design, and phased implementation of a Z80 on PCA.
WhenToUse: Start here; read the intern guide and diary before any implementation.
---

# Build a Z80 on Plastic Cell Architecture (PCA) and deploy on the Olimex GateMateA1-EVB FPGA

## Overview

This ticket researches **Plastic Cell Architecture (PCA)** — NTT/Nagasaki-U's dynamically
reconfigurable hardware computer whose cells pair a fixed cellular-automaton "built-in
part" with a reconfigurable "sea-of-LUTs" plastic part — and designs a **Z80 8-bit
microprocessor mapped onto it as a graph of wired-logic objects** that talk by message
passing. The founding PCA paper's claim that "a von Neumann architecture is obtained if
only one cell part is extracted" is the justification: a Z80 is a von-Neumann CPU, so
mapping it onto PCA objects is the canonical PCA processor exercise. The design reuses
the sibling MATE-16 project's OSS CAD toolchain, GateMate board pins, held-request bus,
precise-fault, and verification-pyramid conventions. Current status: research + design
done; the intern onboarding guide (design-doc 01) and investigation diary (reference 01)
are written; the `pca_z80/` repo skeleton and RTL begin at Phase 0–1.

## Status

Current status: **active**

## Topics

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

## Tasks

See [tasks.md](./tasks.md) for the current task list.

## Changelog

See [changelog.md](./changelog.md) for recent changes and decisions.

## Structure

- design-doc/ - Architecture and design documents (the intern onboarding guide)
- reference/ - Investigation diary and context summaries
- playbooks/ - Command sequences and test procedures
- scripts/ - Probes, analyzers, build harness (created in later phases)
- various/ - Working notes and research
- archive/ - Deprecated or reference-only artifacts
