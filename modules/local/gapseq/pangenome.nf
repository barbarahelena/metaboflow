process GAPSEQ_PANGENOME {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::gapseq=1.4.0"
    container "biocontainers/gapseq:1.4.0--h9ee0642_1"

    input:
    tuple val(meta), path(magcluster) stage as "mags_cluster_annotated/"

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    gapseq pangenome --input mags_cluster_annotated/ --output pangenome_X/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gapseq: \$(gapseq -v 2>&1 | head -1 | sed 's/gapseq version: //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gapseq: \$(gapseq -v 2>&1 | head -1 | sed 's/gapseq version: //')
    END_VERSIONS
    """
}
