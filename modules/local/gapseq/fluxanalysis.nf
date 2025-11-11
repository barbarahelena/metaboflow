process GAPSEQ_FLUXANALYSIS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::gapseq=1.4.0"
    container "biocontainers/gapseq:1.4.0--h9ee0642_1"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    samtools \\
        sort \\
        $args \\
        -@ $task.cpus \\
        -o ${prefix}.bam \\
        -T $prefix \\
        $bam

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
