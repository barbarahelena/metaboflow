process GUTSMASH_PROCESS {
    tag "$meta.bin_id"
    label 'process_single'

    conda "conda-forge::pandas=2.3.3"
    container "community.wave.seqera.io/library/pandas:2.3.3--5a902bf824a79745"

    input:
    tuple val(meta), path(json)

    output:
    tuple val(meta), path("${meta.bin_id}/*_binregions.tsv"), optional: true , emit: tsv
    path "versions.yml"                                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    #!/usr/bin/env python3
    import json
    import sys
    import pandas as pd
    import re
    import os

    # Create bin directory
    os.makedirs("${meta.bin_id}", exist_ok=True)

    with open("${json}") as f:
        raw = f.read()

    # Extract the all_regions object using regex
    match = re.search(r'all_regions\\s*=\\s*({.*?})\\s*;', raw, re.DOTALL)
    if not match:
        print(f"WARNING: Could not find all_regions object in ${meta.bin_id} - skipping", file=sys.stderr)
        # Write versions and exit without creating TSV
        with open("versions.yml", "w") as v:
            v.write(f"${task.process}:\\n")
            v.write(f'  python: "{sys.version.split()[0]}"\\n')
            v.write(f'  pandas: "{pd.__version__}"\\n')
        sys.exit(0)
    
    all_regions_str = match.group(1)

    # Parse as JSON
    try:
        all_regions = json.loads(all_regions_str)
    except json.JSONDecodeError as e:
        print(f"WARNING: Could not parse all_regions JSON in ${meta.bin_id}: {e} - skipping", file=sys.stderr)
        with open("versions.yml", "w") as v:
            v.write(f"${task.process}:\\n")
            v.write(f'  python: "{sys.version.split()[0]}"\\n')
            v.write(f'  pandas: "{pd.__version__}"\\n')
        sys.exit(0)

    # Extract region keys from 'order' and build a list of region dicts
    region_keys = all_regions.get("order", [])
    
    # Check if there are any regions
    if not region_keys:
        print(f"WARNING: No regions found in ${meta.bin_id} - skipping", file=sys.stderr)
        with open("versions.yml", "w") as v:
            v.write(f"${task.process}:\\n")
            v.write(f'  python: "{sys.version.split()[0]}"\\n')
            v.write(f'  pandas: "{pd.__version__}"\\n')
        sys.exit(0)
    
    regions = []
    for key in region_keys:
        region = all_regions.get(key, {})
        region_out = region.copy()
        region_out["region_id"] = key
        region_out["bin_id"] = "${meta.bin_id}"
        regions.append(region_out)

    # Convert to DataFrame and save as TSV (one row per region, only selected columns)
    cols = ["region_id", "bin_id", "start", "end", "idx", "type", "products"]
    df = pd.DataFrame(regions)
    df = df[cols]
    df.to_csv("${meta.bin_id}/${meta.bin_id}_binregions.tsv", sep="\\t", index=False)
    
    print(f"Successfully processed {len(regions)} regions for ${meta.bin_id}")

    # Write versions.yml in Python
    with open("versions.yml", "w") as v:
        v.write(f"${task.process}:\\n")
        v.write(f'  python: "{sys.version.split()[0]}"\\n')
        v.write(f'  pandas: "{pd.__version__}"\\n')
    """

    stub:
    """
    mkdir -p ${meta.bin_id}
    touch ${meta.bin_id}/${meta.bin_id}_binregions.tsv
    touch versions.yml
    """
}