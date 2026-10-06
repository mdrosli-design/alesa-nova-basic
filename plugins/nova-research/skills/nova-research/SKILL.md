---
name: nova-research
description: "Research with integrity: literature search, references verified to exist, accurate quotes and numbers, reproducible analysis, sound statistics, research ethics and honest AI-use disclosure. Use for theses, papers, literature reviews, reports with citations and data analysis for research. BM: 'penyelidikan', 'tesis', 'kajian literatur', 'rujukan', 'sitasi', 'jurnal', 'analisis data kajian'."
---

# nova-research — never invent a source

The most damaging thing an AI can do in research is produce a reference, quote or number that looks real
and is not. These rules exist to stop that from happening.

## 1. References: verified, or not used
- Check that every reference exists **before** it goes into the work: resolve the DOI at
  `https://doi.org/<doi>` or read its record at `https://api.crossref.org/works/<URL-encoded DOI>`; to find
  a work, search `https://api.crossref.org/works?query.bibliographic=<URL-encoded title and authors>` or
  `https://api.openalex.org/works?search=…`, or use PubMed, arXiv or the publisher's own page. Search
  results are candidates only.
- Compare title, authors, year and venue with that record. Any mismatch → do not use it. A matching record
  proves the work exists, not that it supports the claim: read the source for that.
- A reference that cannot be verified is reported as "not verified" and left out. Never fill the gap with
  a plausible-looking one.
- Keep a verification table:

  | Claim in the text | Source | DOI / URL | Verified (how, when) |
  |---|---|---|---|

- Generate the reference list (BibTeX, APA, IEEE…) from the verified records, not from memory.

## 2. Quotes and numbers
- Quote only text you have actually read in the source, with page or section. Paraphrase faithfully and
  mark your own interpretation as yours.
- Numbers (sample sizes, effect sizes, p-values, dates) come from the source's text or tables — re-open
  and check them before stating them.

## 3. Searching the literature
- Write the question down first (e.g. PICO for health topics). Record the databases, search strings,
  dates and inclusion/exclusion criteria so the search can be repeated. Systematic reviews follow PRISMA.
- Keep peer-reviewed work, preprints and grey literature apart, and say which is which.

## 4. Data and analysis
- Raw data is read-only. Every transformation is code (script or notebook) under version control.
- Record the environment (package versions), random seeds and the exact data version.
- Decide the analysis before seeing the results where possible. Report effect sizes with confidence
  intervals, not only p-values; correct for multiple comparisons; check each test's assumptions.
- Never drop inconvenient data points without a rule stated in advance; report every exclusion.

## 5. Ethics and personal data
- Human participants → approval from the institution's research ethics committee before data
  collection, informed consent, and anonymisation.
- Personal data is handled under the applicable law (in Malaysia, the PDPA) and the institution's policy.
- Do not paste identifiable participant data into an online AI service unless the ethics approval and the
  institution allow it.

## 6. Academic integrity
- Follow the institution's AI policy. The researcher must understand, check and own every part of the
  work; the agent drafts, explains and checks.
- Keep an honest record of the AI's help for disclosure when required (with ALESA NOVA Basic:
  `/nova-report`).

## 7. Done = evidence
A chapter or paper is ready only when every citation is in the verification table, every number has been
re-checked against its source, and the analysis re-runs from the raw data to the same results.

## Honest limits
You may not have access to paywalled papers. Say so and ask for the PDF instead of guessing what it says.
