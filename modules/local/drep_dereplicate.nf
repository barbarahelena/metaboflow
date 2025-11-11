process DREP_DEREPLICATE {
    label 'process_medium'

    conda "bioconda::drep=3.5.0"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/drep:3.5.0--pyhdfd78af_0'
        : 'biocontainers/drep:3.5.0--pyhdfd78af_0'}"

    input:
    path(fastas, stageAs: "fastas/*")
    val(ANI)
    val(contamination)
    val(completeness)
    path(quality)

    output:
    path("bins"), emit: directory
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    # Create genomeInfo file with FASTA paths for DRep (CSV format)
    echo "genome,completeness,contamination" > genome_info.csv
    tail -n +2 ${quality} | cut -f1,2,3 | while IFS=\$'\\t' read -r genome_name completeness contamination; do
        echo "fastas/\${genome_name}.fa,\$completeness,\$contamination" >> genome_info.csv
    done
    head -n 10 genome_info.csv
    
    dRep \\
        dereplicate \\
        --genomeInfo genome_info.csv \\
        -comp ${completeness} \\
        -con ${contamination} \\
        -pa ${ANI} \\
        -p ${task.cpus} \\
        ${args} \\
        -g fastas/*.fa \\
        --skip_plots \\
        bins
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drep: \$(dRep | head -n 2 | sed 's/.*v//g;s/ .*//g' | tail -n 1)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    echo "${args}"
    mkdir -p ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drep: \$(dRep | head -n 2 | sed 's/.*v//g;s/ .*//g' | tail -n 1)
    END_VERSIONS
    """
}