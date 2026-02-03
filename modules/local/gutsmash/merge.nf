process GUTSMASH_MERGE {
    label 'process_single'

    conda "conda-forge::pandas=2.3.3"
    container "community.wave.seqera.io/library/pandas:2.3.3--5a902bf824a79745"

    input:
    path(region_tsvs)
    path(depth_tsvs)

    output:
    path "all_clusters.tsv"        , emit: clusters
    path "population_pathways.tsv" , emit: pathways
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    #!/usr/bin/env python3
    import pandas as pd
    import sys
    import glob

    # Merge all region TSVs (from gutsmash_process)
    region_files = glob.glob("*binregions.tsv")
    region_dfs = [pd.read_csv(f, sep="\\t") for f in region_files]
    all_regions = pd.concat(region_dfs, ignore_index=True)
    all_regions.to_csv("all_clusters.tsv", sep="\\t", index=False)
    
    print(f"Merged {len(region_files)} region files into all_clusters.tsv")

    # Merge all per-bin population pathway TSVs
    pathway_files = glob.glob("*_population_pathways.tsv")
    pathway_dfs = [pd.read_csv(f, sep="\\t") for f in pathway_files]
    
    # Concatenate and aggregate across bins
    all_pathways = pd.concat(pathway_dfs, ignore_index=True)
    
    # Sum depths per sample x product across all bins
    pop = (
        all_pathways
        .groupby("sample")
        .sum(numeric_only=True)
        .reset_index()
    )
    
    pop.to_csv("population_pathways.tsv", sep="\\t", index=False)
    
    print(f"Merged {len(pathway_files)} pathway files into population_pathways.tsv")

    # Write versions.yml
    with open("versions.yml", "w") as v:
        v.write(f"${task.process}:\\n")
        v.write(f'  python: "{sys.version.split()[0]}"\\n')
        v.write(f'  pandas: "{pd.__version__}"\\n')
    """

    stub:
    """
    touch all_clusters.tsv
    touch population_pathways.tsv
    touch versions.yml
    """
}
