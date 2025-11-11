process RENAME_POSTDASTOOL {
    tag "${meta.id}"
    label 'process_low'

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(bins)

    output:
    tuple val(meta), path("Refined-${meta.id}.*.fa", includeInputs: true), optional:true, emit: refined_bins
    tuple val(meta), path("DASToolUnbinned-${meta.id}.fa"),                 optional:true, emit: refined_unbins

    script:
    """
    if [[ -f unbinned.fa ]]; then
        mv unbinned.fa DASToolUnbinned-${meta.id}.fa
    fi
    """
}
