process GAPSEQ_ANNOTATE {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::gapseq=1.4.0"
    container "biocontainers/gapseq:1.4.0--h9ee0642_1"

    input:
    tuple val(meta), path(bins)

    output:
    tuple val(meta), path("mags_cluster_${prefix}/*"), emit: annotated_bins
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p mags_cluster/
    cp ${bins} mags_cluster/
    
    gapseq annotate ${args} --input mags_cluster/ --output mags_cluster_${prefix}/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gapseq: \$(gapseq -v 2>&1 | head -1 | sed 's/gapseq version: //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p mags_cluster_${prefix}/
    touch mags_cluster_${prefix}/annotated_bins.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gapseq: \$(gapseq -v 2>&1 | head -1 | sed 's/gapseq version: //')
    END_VERSIONS
    """
}
