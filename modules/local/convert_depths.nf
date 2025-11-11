process CONVERT_DEPTHS {
    tag "${meta.id}"

    conda "bioconda::bioawk=1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioawk:1.0--hed695b0_5' :
        'biocontainers/bioawk:1.0--hed695b0_5' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path(fasta), path("*.tsv")           , emit: output
    path "versions.yml"                                   , emit: versions

    script:
    """
    # Extract coverage information from FASTA headers using sed
    echo "contigName\\tcontigLen\\ttotalAvgDepth" > depth_from_fasta.tsv
    grep "^>" ${fasta} | sed 's/^>//' | awk -F'_' '{
        # Reconstruct full contig name by finding the length and cov positions
        len_pos = 0; cov_pos = 0;
        for (i = 1; i <= NF; i++) {
            if (\$i == "length") len_pos = i;
            if (\$i == "cov") cov_pos = i;
        }
        # Extract length and coverage values
        length_val = \$(len_pos + 1);
        cov_val = \$(cov_pos + 1);
        print \$0 "\\t" length_val "\\t" cov_val
    }' >> depth_from_fasta.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioawk: \$(bioawk --version | cut -f 3 -d ' ' )
    END_VERSIONS
    """
}
