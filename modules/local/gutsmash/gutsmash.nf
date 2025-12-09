process GUTSMASH_GUTSMASH {
    tag "$meta.bin_id"
    label 'process_medium'

    conda "bioconda::gutsmash=2.0.1"
    container "docker://barbarahelena/gutsmash:1.6"

    input:
    tuple val(meta), path(bin)

    output:
    tuple val(meta), path("gutsmash_output_*/index.html")              , emit: html_report
    tuple val(meta), path("gutsmash_output_*/*.gbk")                  , emit: genbank_files, optional: true
    tuple val(meta), path("gutsmash_output_*/*.json")                 , emit: json_results, optional: true
    tuple val(meta), path("gutsmash_output_*/regions.js")             , emit: regions_js, optional: true
    tuple val(meta), path("gutsmash_output_*/knownclusterblast/")     , emit: knownclusterblast_dir, optional: true
    tuple val(meta), path("gutsmash_output_*/knownclusterblastoutput.txt"), emit: txt, optional: true
    tuple val(meta), path("gutsmash_output_*/*.zip")                  , emit: zip_results, optional: true
    tuple val(meta), path("gutsmash_output_*/css/")                   , emit: css_dir, optional: true
    tuple val(meta), path("gutsmash_output_*/images/")                , emit: images_dir, optional: true
    tuple val(meta), path("gutsmash_output_*/js/")                    , emit: js_dir, optional: true
    tuple val(meta), path("gutsmash_output_*/svg/")                   , emit: svg_dir, optional: true
    path "versions.yml"                                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.bin_id}"

    """
    # Run gutSMASH with minimal detection mode
    python3 /usr/share/gutsmash/run_gutsmash.py \\
        --minimal \\
        --cb-knownclusters \\
        --enable-genefunctions \\
        --genefinding-tool prodigal \\
        --output-dir gutsmash_output_${prefix} \\
        --cpus ${task.cpus} \\
        ${args} \\
        ${bin}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gutsmash: \$(python3 /usr/local/bin/run_gutsmash.py --version 2>&1 | grep -o '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+' || echo "2.0.1")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.bin_id}"

    """
    mkdir -p gutsmash_output_${prefix}
    touch gutsmash_output_${prefix}/index.html
    touch gutsmash_output_${prefix}/${prefix}.gbk
    touch gutsmash_output_${prefix}/${prefix}_regions.json
    touch gutsmash_output_${prefix}/regions.js

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gutsmash: \$(echo "2.0.1")
    END_VERSIONS
    """
}
