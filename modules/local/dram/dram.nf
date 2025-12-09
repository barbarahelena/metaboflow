process DRAM_ANNOTATE {
    tag "$meta.bin_id"
    label 'process_high'

    conda "bioconda::dram=1.5.0"
    container "biocontainers/dram:1.5.0--pyhdfd78af_0"
    // install databases!

    input:
    tuple val(meta), path(bin)
    path(db)

    output:
    tuple val(meta), path("*/annotations.tsv")       , emit: annotations
    tuple val(meta), path("*/genome_stats.tsv") , emit: genome_summary
    tuple val(meta), path("*/metabolism_summary.xlsx"), emit: functional_summary
    tuple val(meta), path("*/product.tsv")  , emit: product_summary, optional: true
    tuple val(meta), path("*/product.html")   , emit: product_html, optional: true
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # Create DRAM config file in JSON format
    cat > DRAM.config <<EOF
    {
      "search_databases": {
        "kegg": null,
        "kofam_hmm": "${db}/kofam_profiles.hmm",
        "kofam_ko_list": "${db}/kofam_ko_list.tsv",
        "uniref": "${db}/uniref90.20251113.mmsdb",
        "pfam": "${db}/pfam.mmspro",
        "dbcan": "${db}/dbCAN-HMMdb-V11.txt",
        "viral": "${db}/viral.mmsdb",
        "peptidase": "${db}/peptidases.20251115.mmsdb",
        "vogdb": "${db}/vog_annotations_latest.tsv",
        "camper_hmm": "${db}/CAMPER.hmm",
        "camper_fa_db": "${db}/CAMPER.fasta"
      },
      "database_descriptions": {
        "pfam_hmm": "${db}/Pfam-A.hmm.dat",
        "dbcan_fam_activities": "${db}/CAZyDB.08062022.fam-activities.txt",
        "dbcan_subfam_ec": "${db}/CAZyDB.08062022.fam.subfam.ec.txt",
        "vog_annotations": "${db}/vog_annotations_latest.tsv"
      },
      "dram_sheets": {
        "genome_summary_form": "${db}/genome_summary_form.20251113.tsv",
        "module_step_form": "${db}/module_step_form.20251113.tsv",
        "etc_module_database": "${db}/etc_module_database.20251113.tsv",
        "function_heatmap_form": "${db}/function_heatmap_form.20251113.tsv",
        "camper_fa_db_cutoffs": "${db}/CAMPER_blast_scores.tsv",
        "camper_hmm_cutoffs": "${db}/CAMPER_hmm_scores.tsv",
        "amg_database": "${db}/amg_database.20251113.tsv"
      },
      "dram_version": "1.5.0",
      "description_db": "${db}/description_db.sqlite",
      "setup_info": {
        "kofam_hmm": {
          "name": "KOfam db",
          "citation": "T. Aramaki, R. Blanc-Mathieu, H. Endo, K. Ohkubo, M. Kanehisa, S. Goto, and H. Ogata, \\"Kofamkoala: Kegg ortholog assignment based on profile hmm and adaptive score threshold,\\" Bioinformatics, vol. 36, no. 7, pp. 2251\\u20132252, 2020.",
          "Download time": "11/14/2025, 10:55:28",
          "Origin": "Downloaded by DRAM"
        },
        "kofam_ko_list": {
          "name": "KOfam KO list",
          "citation": "T. Aramaki, R. Blanc-Mathieu, H. Endo, K. Ohkubo, M. Kanehisa, S. Goto, and H. Ogata, \\"Kofamkoala: Kegg ortholog assignment based on profile hmm and adaptive score threshold,\\" Bioinformatics, vol. 36, no. 7, pp. 2251\\u20132252, 2020.",
          "Download time": "11/14/2025, 10:56:02",
          "Origin": "Downloaded by DRAM"
        }
      },
      "log_path": null
    }
    EOF

    # Run DRAM annotation with JSON config
    DRAM.py annotate \\
        -i ${bin} \\
        -o ${prefix} \\
        --threads ${task.cpus} \\
        --config_loc DRAM.config \\
        ${args}

    # Run DRAM distill with JSON config
    DRAM.py distill \\
        -i ${prefix}/annotations.tsv \\
        -o ${prefix} \\
        --config_loc DRAM.config \\
        --trna_path ${prefix}/trnas.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dram: \$(echo "1.5.0")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"  // Changed this line

    """
    mkdir -p dram_output_${prefix}
    touch dram_output_${prefix}/annotations.tsv
    touch dram_output_${prefix}/genes.faa
    touch dram_output_${prefix}/genes.fna
    touch dram_output_${prefix}/genes.gff
    touch dram_output_${prefix}/scaffolds.fna
    touch dram_output_${prefix}/trnas.tsv
    touch dram_output_${prefix}/rrnas.tsv
    touch dram_output_${prefix}/genome_summaries.tsv
    touch dram_output_${prefix}/metabolism_summary.tsv
    touch dram_output_${prefix}/product_summary.tsv
    touch dram_output_${prefix}/module_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dram: \$(echo "1.5.0")
    END_VERSIONS
    """
}
