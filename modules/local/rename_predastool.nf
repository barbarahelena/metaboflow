process RENAME_PREDASTOOL {
    tag "${meta.assembler}-${meta.binner}-${meta.id}"
    label 'process_low'

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(bins)

    output:
    tuple val(meta), path("Refined-${meta.id}*"), emit: renamed_bins

    script:
    """
    if [ -n "${bins}" ]
    then
        for bin in ${bins}; do
            if [[ \${bin} =~ ${meta.id}.([_[:alnum:]]+).fa ]]; then
                num=\${BASH_REMATCH[1]}
                mv \${bin} Refined-${meta.id}.\${num}.fa
            else
                echo "ERROR: the bin filename \${bin} does not match the expected format '${meta.id}.([_[:alnum:]]+).fa'!"
                exit 1
            fi
        done
    fi
    """
}
