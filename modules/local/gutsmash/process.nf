process GUTSMASH_PROCESS {
    tag "$meta.bin_id"
    label 'process_single'

    conda "conda-forge::pandas=2.3.3"
    container "community.wave.seqera.io/library/pandas:2.3.3--5a902bf824a79745"

    input:
    tuple val(meta), path(json)

    output:
    path "*_all_regions.tsv"        , emit: tsv
    path "versions.yml"        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    #!/usr/bin/env python3
import json
import sys
import pandas as pd
import re

with open("${json}") as f:
    raw = f.read()

# Extract the all_regions object using regex
match = re.search(r'all_regions\\s*=\\s*({.*?})\\s*;', raw, re.DOTALL)
if not match:
    raise ValueError("Could not find all_regions object in the file.")
all_regions_str = match.group(1)

# Parse as JSON
all_regions = json.loads(all_regions_str)

# Extract region keys from 'order' and build a list of region dicts
region_keys = all_regions.get("order", [])
regions = []
for key in region_keys:
    region = all_regions.get(key, {})
    region_out = region.copy()
    region_out["region_id"] = key
    region_out["bin_id"] = "${meta.bin_id}"
    region_out["id"] = "${meta.id}"
    region_out["class"] = region.get("class", "")
    regions.append(region_out)

# Convert to DataFrame and save as TSV (one row per region, only selected columns)
cols = ["region_id", "bin_id", "id", "class", "start", "end", "idx", "type", "products"]
df = pd.DataFrame(regions)
df = df[cols]
df.to_csv(f"${meta.bin_id}_all_regions.tsv", sep="\\t", index=False)

# Write versions.yml in Python
with open("versions.yml", "w") as v:
    v.write(f"${task.process}:\\n")
    v.write(f'  python: "{sys.version.split()[0]}"\\n')
    v.write(f'  pandas: "{pd.__version__}"\\n')
    """
}