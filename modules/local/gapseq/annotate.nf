process GAPSEQ_ANNOTATE {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::gapseq=1.4.0"
    container "biocontainers/gapseq:1.4.0--h9ee0642_1"

    input:
    tuple val(meta), path(bin)

    output:
    tuple val(meta), path("*-Pathways.tbl")          , emit: pathways
    tuple val(meta), path("*-Reactions.tbl")         , emit: reactions
    tuple val(meta), path("*-Transporter.tbl")       , emit: transporters
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    # Run gapseq find to predict pathways and reactions
    gapseq find -p all -t ${args} ${bin}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gapseq: \$(gapseq -v 2>&1 | head -1 | sed 's/gapseq version: //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p gapseq_annotated_${prefix}/
    touch gapseq_annotated_${prefix}/${prefix}-Pathways.tbl
    touch gapseq_annotated_${prefix}/${prefix}-Reactions.tbl
    touch gapseq_annotated_${prefix}/${prefix}-Transporter.tbl

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gapseq: \$(gapseq -v 2>&1 | head -1 | sed 's/gapseq version: //')
    END_VERSIONS
    """
}
