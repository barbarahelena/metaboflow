process GUTSMASH_PERBIN {
    tag "$meta.bin_id"
    label 'process_single'

    conda "conda-forge::pandas=2.3.3"
    container "community.wave.seqera.io/library/pandas:2.3.3--5a902bf824a79745"

    input:
    tuple val(meta), val(depth_list), path(binregions)

    output:
    path "${meta.bin_id}/${meta.bin_id}_population_pathways.tsv" , emit: pathways
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def bin_id = meta.bin_id
    def depths_list = depth_list.collect { "['${it.sample_id}', ${it.depth}]" }.join(", ")
    """
    #!/usr/bin/env python3
    import pandas as pd
    import sys
    import os

    # Create bin directory
    os.makedirs("${bin_id}", exist_ok=True)

    # Read the bin regions file
    df = pd.read_csv("${binregions}", sep="\\t")
    
    # Parse depth information from depth_list
    depths_data = [${depths_list}]
    depth_long = pd.DataFrame(depths_data, columns=["sample", "depth"])
    
    # Add bin_id to regions dataframe
    df["bin"] = "${bin_id}"
    
    # Explode products if it's a list/array column
    if "products" in df.columns:
        df = df.explode("products")
    
    # Cross join: each pathway/product with each sample depth
    df["key"] = 1
    depth_long["key"] = 1
    merged = df.merge(depth_long, on="key").drop("key", axis=1)
    
    # Build population matrix: sum depth per sample x pathway/product
    if "products" in merged.columns:
        pop = (
            merged
            .groupby(["sample", "products"])["depth"]
            .sum()
            .unstack(fill_value=0)
            .reset_index()
        )
    else:
        pop = depth_long
    
    # Save directly to work directory (not in subdirectory)
    pop.to_csv("${bin_id}/${bin_id}_population_pathways.tsv", sep="\\t", index=False)

    # Write versions.yml
    with open("versions.yml", "w") as v:
        v.write(f"${task.process}:\\n")
        v.write(f'  python: "{sys.version.split()[0]}"\\n')
        v.write(f'  pandas: "{pd.__version__}"\\n')
    """

    stub:
    """
    touch ${meta.bin_id}_population_pathways.tsv
    touch versions.yml
    """
}
