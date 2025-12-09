process GUTSMASH_COLLAPSE {
    label 'process_low'

    conda "conda-forge::pandas=2.3.3"
    container "community.wave.seqera.io/library/pandas:2.3.3--5a902bf824a79745"

    input:
    path(tsvs)
    path(depths)

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

    files = "${tsvs}".split()
    dfs = [pd.read_csv(f, sep="\\t") for f in files]
    df = pd.concat(dfs, ignore_index=True)
    df.to_csv("all_clusters.tsv", sep="\\t", index=False)

    print("Wrote all_clusters.tsv.")

    depth = pd.read_csv("${depths}", sep="\t")
    depth.columns = depth.columns.map(str)
    depth["bin"] = depth["bin"].str.replace(".fa", "", regex=False)
    depth = depth[["bin"] + [c for c in depth.columns if "Depth" in c]]
    df = df.rename(columns={"bin_id": "bin"})
    depth.columns = depth.columns.map(str)
    depth["bin"] = depth["bin"].str.replace(".fa", "", regex=False)

    # Melt depth table to long format
    depth_long = depth.melt(id_vars=["bin"], var_name="sample", value_name="depth")
    # Merge with annotation
    merged = depth_long.merge(df, on="bin", how="left")
    merged = merged.explode("products")

    # Build population matrix: sum depth per sample x pathway class
    pop = (
        merged
        .groupby(["sample", "products"])["depth"]
        .sum()
        .unstack(fill_value=0)
        .reset_index()
    )

    pop.to_csv("population_pathways.tsv", sep="\\t", index=False)

    # Write versions.yml in Python
    with open("versions.yml", "w") as v:
        v.write(f"${task.process}:\\n")
        v.write(f'  python: "{sys.version.split()[0]}"\\n')
        v.write(f'  pandas: "{pd.__version__}"\\n')
    """

    stub:

    """
    

    """
}
