# metaboflow: Output

## Introduction

This document describes the output produced by the pipeline. All paths listed below are relative to the top-level results directory specified with `--outdir`.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes metagenomic bins through up to three annotation tools:

- [gutSMASH](#gutsmash) — Metabolic gene cluster detection *(enabled by default)*
- [gapseq](#gapseq) — Metabolic pathway prediction *(disabled by default)*
- [DRAM](#dram) — Functional annotation of metagenomes *(disabled by default)*
- [Pipeline information](#pipeline-information) — Nextflow execution reports

---

## gutSMASH

gutSMASH detects specialised primary metabolic gene clusters (SMGCs) in microbial genomes using the [gutSMASH](https://github.com/victoriapascal/gutsmash/) tool.

### gutSMASH annotation (`GUTSMASH_GUTSMASH`)

<details markdown="1">
<summary>Output files</summary>

- `gutsmash/<bin_id>/`
  - `regions.js`: JavaScript-formatted file containing all detected genomic region data for the bin.
  - `knownclusterblast/`: Directory containing known cluster BLAST results.
    - `*output.txt`: Per-region BLAST output against known clusters.

</details>

Raw gutSMASH output per bin. The `regions.js` file contains coordinates, product types, and cluster annotations for all detected SMGCs.

### Region processing (`GUTSMASH_PROCESS`)

<details markdown="1">
<summary>Output files</summary>

- `gutsmash/<bin_id>/`
  - `<bin_id>_binregions.tsv`: Tab-separated table of detected regions for this bin. Columns: `region_id`, `bin_id`, `start`, `end`, `idx`, `type`, `products`. Only produced when at least one region is found.

</details>

Parses the raw `regions.js` output into a structured TSV table. Bins with no detected regions produce no output file.

### Per-bin population pathways (`GUTSMASH_PERBIN`) *(requires `--depths`)*

<details markdown="1">
<summary>Output files</summary>

- `gutsmash/<bin_id>/`
  - `<bin_id>_population_pathways.tsv`: Tab-separated matrix with one row per sample and one column per detected product/pathway, with depth values as entries.

</details>

Combines region annotations with sample depth information to calculate the abundance-weighted pathway presence across samples. **This step is only run when `--depths` is provided.**

### Merged results (`GUTSMASH_MERGE`)

<details markdown="1">
<summary>Output files</summary>

- `gutsmash/`
  - `all_clusters.tsv`: Merged table of all detected SMGC regions across all bins. Contains `region_id`, `bin_id`, `start`, `end`, `idx`, `type`, and `products` columns.
  - `population_pathways.tsv`: Merged population-level pathway matrix aggregated across all bins, summed per sample. Empty if `--depths` was not provided.

</details>

The final merged outputs integrating results from all bins. `all_clusters.tsv` is always produced. `population_pathways.tsv` contains meaningful data only when depth information was supplied.

---

## gapseq

gapseq predicts metabolic pathways and reconstructs metabolic models for each bin using [gapseq](https://gapseq.readthedocs.io/en/latest/). **Disabled by default — enable with `--skip_gapseq false`.**

### Pathway annotation (`GAPSEQ_ANNOTATE`)

<details markdown="1">
<summary>Output files</summary>

- `gapseq/<bin_id>/`
  - `*-Pathways.tbl`: Table of predicted metabolic pathways for this bin.
  - `*-Reactions.tbl`: Table of predicted metabolic reactions.
  - `*-Transporter.tbl`: Table of predicted transporter reactions.

</details>

Runs `gapseq find -p all` to predict all known bacterial metabolic pathways and reactions. Each bin produces three output tables covering pathways, reactions, and transporters.

---

## DRAM

DRAM (Distilled and Refined Annotation of Metabolism) provides comprehensive functional annotation of microbial genomes using [DRAM](https://github.com/WrightonLabCSU/DRAM). **Disabled by default — enable with `--skip_dram false`.**

### Database setup (`DRAM_DB`) *(only when `--dram_db` is not specified)*

<details markdown="1">
<summary>Output files</summary>

- `dram_databases/`: Directory containing all downloaded DRAM reference databases (KOfam, UniRef90, Pfam, dbCAN, VOGDB, CAMPER, peptidases, etc.).
- `DRAM.config`: DRAM configuration file pointing to the prepared databases.

</details>

Automatically downloads and prepares all DRAM reference databases. This step is skipped when an existing database directory is provided via `--dram_db`. Database preparation requires several hours and ~60 GB of disk space.

### Functional annotation (`DRAM_ANNOTATE`)

<details markdown="1">
<summary>Output files</summary>

- `dram/<bin_id>/`
  - `annotations.tsv`: Full gene-level annotation table with database hits across KOfam, UniRef90, Pfam, dbCAN, VOGDB, CAMPER, and peptidase databases.
  - `genome_stats.tsv`: Summary statistics for the annotated genome (completeness, contamination, coding density, etc.).
  - `metabolism_summary.xlsx`: Excel workbook summarising metabolic modules, KEGG pathways, and functional categories.
  - `product.tsv` *(optional)*: Product summary table.
  - `product.html` *(optional)*: Interactive HTML product visualisation.

</details>

Runs `DRAM.py annotate` on each bin to produce a comprehensive gene-level functional annotation. The `annotations.tsv` is the primary output for downstream analyses. The `metabolism_summary.xlsx` provides an interpretable overview of metabolic capabilities.

---

## Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - `execution_report.html`: Nextflow execution report with per-task resource usage.
  - `execution_timeline.html`: Timeline view of task execution.
  - `execution_trace.txt`: Tab-delimited trace file with runtime and resource metrics for every task.
  - `pipeline_dag.dot` / `pipeline_dag.svg`: Directed acyclic graph (DAG) of the pipeline.
  - `software_versions.yml`: Versions of all software tools used in the pipeline run.
  - `params.json`: All parameters used in this run, for reproducibility.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. These allow you to troubleshoot errors and review resource usage. The `software_versions.yml` file records tool versions for reporting and reproducibility.

