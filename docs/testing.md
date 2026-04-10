# Test Specification

## About This Test Specification

* This document follows a test-first approach, where specifications are defined before implementation
* Each test case is intended to correspond to a single commit
* Tests are written in GFM (GitHub Flavored Markdown) table format
* The table format also serves as a real-world usage test for tirenvi

## Purpose

* This specification is not guaranteed to always reflect the latest state of the codebase
* Its primary purpose is to record the process of feature development, changes, and fixes over time
* It should serve as a reference for understanding how and why certain behaviors were implemented

## Usage

* The document can be used to investigate regressions by tracing past test cases and related changes
* It is also intended to support future modifications by allowing previously implemented behaviors to be reviewed and reused
* Test cases are written with practical usage in mind, often including multi-line and multi-byte content

## Notes

* Since cell content can become lengthy, it may be difficult to read with standard Markdown rendering
* Viewing with tirenvi is recommended

---

## Test Case Template

### Column Width Restoration

* branch name: feat/persist-column-width-on-toggle

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
| 0bf87d5 | md is displayed in tir-vim mode<br><br>md tir-vim表示中 | Switch back to flat mode with `Tir toggle`<br>`echo b:tirenvi`<br>Tir toggleでflat表示に戻す<br>echo b:tirenvi | `widths` field exists<br><br>widths[iblock][icol]フィールドに幅保持 | 2026/4/10 |  | feat: persist column widths on tir toggle |

