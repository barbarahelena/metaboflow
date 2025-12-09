process DRAM_DB {
    label 'process_high'
    
    conda "bioconda::dram=1.5.0"
    container "biocontainers/dram:1.5.0--pyhdfd78af_0"
    
    output:
    path("dram_databases")          , emit: databases
    path("DRAM.config")             , emit: config
    path "versions.yml"             , emit: versions
    
    when:
    task.ext.when == null || task.ext.when
    
    script:
    def args = task.ext.args ?: ''

    """
    mkdir -p dram_databases
    
    echo "Setting up DRAM databases..."
    
    # Prepare databases
    DRAM-setup.py prepare_databases \\
        --output_dir dram_databases \\
        --config_loc DRAM.config \\
        --threads ${task.cpus} \\
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dram: \$(DRAM.py --version 2>&1 | grep -o 'DRAM [0-9.]*' | sed 's/DRAM //' || echo "1.5.0")
    END_VERSIONS
    """
    
    stub:
    """
    mkdir -p dram_databases
    touch dram_databases/kofam_profiles.hmm
    touch dram_databases/kofam_ko_list.tsv
    touch dram_databases/pfam
    touch dram_databases/Pfam-A.hmm.dat
    touch dram_databases/dbCAN-HMMdb-V11.txt
    touch DRAM.config
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dram: \$(echo "1.5.0")
    END_VERSIONS
    """
}