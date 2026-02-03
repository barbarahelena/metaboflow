/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { GAPSEQ_ANNOTATE                       } from '../modules/local/gapseq/annotate'
include { GUTSMASH_GUTSMASH                     } from '../modules/local/gutsmash/gutsmash'
include { GUTSMASH_PERBIN                       } from '../modules/local/gutsmash/perbin'
include { GUTSMASH_PROCESS                      } from '../modules/local/gutsmash/process'
include { GUTSMASH_MERGE                        } from '../modules/local/gutsmash/merge'
include { DRAM_ANNOTATE                         } from '../modules/local/dram/dram'
include { DRAM_DB                               } from '../modules/local/dram/db'
include { paramsSummaryMap                      } from 'plugin/nf-validation'
include { paramsSummaryMultiqc                  } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML                } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                } from '../subworkflows/local/utils_metaboflow_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow METABO {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_depths      // channel: depths read in from --depths

    main:

    ch_versions = channel.empty()

    // 
    // MODULE: GAPSEQ for annotation
    //
    if(!params.skip_gapseq){
        GAPSEQ_ANNOTATE ( ch_samplesheet )
        ch_versions = ch_versions.mix(GAPSEQ_ANNOTATE.out.versions)
    }

    // 
    // MODULE: GUTSMASH for annotation
    // 
    if(!params.skip_gutsmash){
        GUTSMASH_GUTSMASH ( ch_samplesheet )
        ch_versions = ch_versions.mix(GUTSMASH_GUTSMASH.out.versions)

        GUTSMASH_PROCESS(GUTSMASH_GUTSMASH.out.regions_js)
        ch_versions = ch_versions.mix(GUTSMASH_PROCESS.out.versions)

        // Check if the TSV channel is empty
        GUTSMASH_PROCESS.out.tsv
            .ifEmpty { 
                log.warn "WARNING: GUTSMASH_PROCESS.out.tsv is empty - no regions found or process failed"
                return Channel.empty()
            }
            .map { meta, file -> [meta.bin_id, meta, file] }
            .set { ch_regions_keyed }

        // Key and group depths by bin_id
        ch_depths
            .map { it[0] }  // ← FIX: Extract meta from wrapping list
            .map { meta -> [meta.bin_id, meta] }
            .groupTuple()
            .set { ch_depths_grouped }

        // Join regions with depths by bin_id
        ch_regions_keyed
            .join(ch_depths_grouped, by: 0)
            .map { bin_id, regions_meta, regions_file, depth_list ->
                def combined_meta = regions_meta + [depths: depth_list]
                [combined_meta, depth_list, regions_file]
            }
            .set { ch_regions_with_depths }

        GUTSMASH_PERBIN ( ch_regions_with_depths )
        ch_versions = ch_versions.mix(GUTSMASH_PERBIN.out.versions)

        GUTSMASH_MERGE ( 
            GUTSMASH_PROCESS.out.tsv.map { meta, file -> file }.collect(), 
            GUTSMASH_PERBIN.out.pathways.collect() 
        )
    }

    if(!params.skip_dram){
        // 
        // MODULE: DRAM for annotation
        // 
        if (!params.dram_db) {
            DRAM_DB ()
            dram_db = DRAM_DB.out.databases
            ch_versions = ch_versions.mix(DRAM_DB.out.versions)
        } else {
            dram_db = params.dram_db
        }
        DRAM_ANNOTATE ( ch_samplesheet, dram_db )
        ch_versions = ch_versions.mix(DRAM_ANNOTATE.out.versions)
    }


    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
