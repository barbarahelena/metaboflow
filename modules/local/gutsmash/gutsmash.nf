process GUTSMASH_GUTSMASH {
    tag "$meta.bin_id"
    label 'process_single'

    conda "bioconda::gutsmash=2.0.1"
    container "docker://barbarahelena/gutsmash:1.6"

    input:
    tuple val(meta), path(bin)

    output:
    tuple val(meta), path("*/regions.js")                           , emit: regions_js, optional: true
    tuple val(meta), path("*/knownclusterblast/")                   , emit: knownclusterblast_dir, optional: true
    tuple val(meta), path("*/knownclusterblast/*output.txt")        , emit: txt, optional: true
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.bin_id}"

    """
    python3 /usr/share/gutsmash/run_gutsmash.py \\
        --taxon bacteria \\
        --cb-knownclusters \\
        --pfam2go \\
        --smcog-trees \\
        --genefinding-tool prodigal \\
        --output-dir ${prefix} \\
        --cpus ${task.cpus} \\
        --debug \\
        ${args} \\
        ${bin}
    
    # Clean up HTML/CSS/SVG/images to save space (keep only regions.js and knownclusterblast)
    rm -rf ${prefix}/index.html ${prefix}/css/ ${prefix}/svg/ ${prefix}/images/ ${prefix}/js/ 2>/dev/null || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gutsmash: \$(python3 /usr/local/bin/run_gutsmash.py --version 2>&1 | grep -o '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+' || echo "2.0.1")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.bin_id}"

    """
    mkdir -p ${prefix}
    touch ${prefix}/index.html
    touch ${prefix}/${prefix}.gbk
    touch ${prefix}/${prefix}_regions.json
    touch ${prefix}/regions.js

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gutsmash: \$(echo "2.0.1")
    END_VERSIONS
    """
}
