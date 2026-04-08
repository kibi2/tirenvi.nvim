# Test Specification

## About This Test Specification

* Define specifications first following a test-first approach
* Each test case corresponds to a single commit
* Tests are written in GFM (GitHub Flavored Markdown) table format
* The table format also serves as a real-world usage test for tirenvi

### Notes

* Since cell content can become lengthy, it may be difficult to read with standard Markdown rendering
* Viewing with tirenvi is recommended

---

## Test Case Template

### Column Width Restoration

| No | Preconditions | Action | Expected | Date | Notes | Commit |
| --- | --- | --- | --- | --- | --- | --- |
|  | CSV is displayed in tir-vim mode<br><br>csv tir-vim表示中 | Switch back to flat mode with `Tir toggle`<br>`echo b:tirenvi`<br>Tir toggleでflat表示に戻す<br>echo b:tirenvi | `columns` field exists<br><br>columnsフィールドあり | 2026/4/9 |  |  |


