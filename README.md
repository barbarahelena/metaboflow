<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/metaboflow_logo_dark.png">
    <img alt="metaboflow" src="docs/images/nf-core-metaboflow_logo_light.png">
  </picture>
</h1>

[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)


## Introduction

**metaboflow** is a bioinformatics pipeline that performs metabolic pathway profiling and functional annotation of microbial genomes and metagenome-assembled genomes (MAGs). It is built using [Nextflow](https://www.nextflow.io/).

1. [`Gapseq`](https://gapseq.readthedocs.io/en/latest/) pipeline for metabolic pathway profiling
2. [`GutSMASH`](https://github.com/victoriapascal/gutsmash/) for metabolic gene cluster detection
3. [`DRAM`](https://github.com/WrightonLabCSU/DRAM) for functional annotation of metagenomes

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

I recoommend to perform assembly of metagenomic data and binning prior to running metaboflow. You can use e.g. the [nf-core/mag](https://nf-co.re/mag) pipeline for this purpose. The resulting bins (fasta files) can then be used as input for metaboflow.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fasta
sample1,sample1_contigs.fasta
```
Each row represents a bin.

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
metaboflow was originally written by barbarahelena. I'm using different tools in this pipeline that you should cite if you use metaboflow in your research. Please see the [CITATIONS.md](CITATIONS.md) file for more details.

## Contributions and Support
If you would like to contribute to this pipeline, don't hesitate to get in touch.

## Citations
This pipeline uses Gapseq, GutSMASH, DRAM and other tools. Please cite the respective publications when using this pipeline in your research.

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
