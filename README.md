<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/metaboflow_logo_dark.png">
    <img alt="metaboflow" src="docs/images/nf-core-metaboflow_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/metaboflow/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/metaboflow/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/metaboflow/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/metaboflow/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)


## Introduction

**metaboflow** is a bioinformatics pipeline that does binning, including qc and refinement, and runs the gapseq pipeline.

1. [`Gapseq`] pipeline for metabolic pathway profiling
2. ['GutSMASH'] for biosynthetic gene cluster detection
3. ['DRAM'] for functional annotation of metagenomic data

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.


First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fasta
sample1,sample1_contigs.fasta
```
Each row represents an assembly of a sample.

Now, download the GTDB-Tk database and untar:
```bash
wget https://data.ace.uq.edu.au/public/gtdb/data/releases/release226/226.0/auxillary_files/gtdbtk_package/full_package/gtdbtk_r226_data.tar.gz
tar -xvf gtdbtk_r226_data.tar.gz
```

Now, you can run the pipeline using:

```bash
nextflow run barbarahelena/metaboflow \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --gtdbtk_database </path/to/database> \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/metaboflow/usage) and the [parameter documentation](https://nf-co.re/metaboflow/parameters).

## Pipeline output

For more details about the output files and reports, please refer to the
[output documentation](docs/output).

## Credits
metaboflow was originally written by barbarahelena, using many nf-core modules and subworkflows, especially from the mag nf-core pipeline, and gapseq itself. I suggest that you cite those tools/pipelines when using this pipeline.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#metaboflow` channel](https://nfcore.slack.com/channels/metaboflow) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations
This is still a work in progress.

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
