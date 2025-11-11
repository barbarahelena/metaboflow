/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CONVERT_DEPTHS                        } from '../modules/local/convert_depths'
include { METABAT2_METABAT2                     } from '../modules/local/metabat2/metabat2/main'
include { GUNZIP as GUNZIP_BINS                 } from '../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_UNBINS               } from '../modules/nf-core/gunzip/main'
include { CHECKM2_DATABASEDOWNLOAD              } from '../modules/nf-core/checkm2/databasedownload/main'
include { CHECKM2_PREDICT                       } from '../modules/nf-core/checkm2/predict/main'
include { DREP_DEREPLICATE                      } from '../modules/local/drep_dereplicate'
include { GTDBTK_CLASSIFYWF                     } from '../modules/nf-core/gtdbtk/classifywf/main' 
include { GAPSEQ_ANNOTATE                       } from '../modules/local/gapseq/annotate' 
include { GAPSEQ_PANGENOME                      } from '../modules/local/gapseq/pangenome'
include { GAPSEQ_MODEL                          } from '../modules/local/gapseq/model'
include { GAPSEQ_FLUXANALYSIS                   } from '../modules/local/gapseq/fluxanalysis'      
include { MULTIQC                               } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap                      } from 'plugin/nf-validation'
include { paramsSummaryMultiqc                  } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML                } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                } from '../subworkflows/local/utils_gapseqflow_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GAPSEQ {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    // Get coverage from fastas
    CONVERT_DEPTHS( ch_samplesheet )
    ch_metabat2_input = CONVERT_DEPTHS.out.output.map { meta, assembly, depth ->
        def meta_new = meta + [binner: 'MetaBAT2']
        [meta_new, assembly, depth]
    }
    ch_versions = ch_versions.mix(CONVERT_DEPTHS.out.versions.first())

    //
    // MODULE: METABAT2 for binning
    //
    METABAT2_METABAT2( ch_metabat2_input )
    ch_versions = ch_versions.mix(METABAT2_METABAT2.out.versions.first())

    //
    // MODULE: Gunzip for binning files
    //
    // METABAT2_METABAT2.out.fasta.view()
    ch_bins_gz = METABAT2_METABAT2.out.fasta.transpose()
    GUNZIP_BINS ( ch_bins_gz )
    ch_bins = GUNZIP_BINS.out.gunzip
        .groupTuple(by: 0)

    ch_unbins_gz = METABAT2_METABAT2.out.unbinned.transpose()
    GUNZIP_UNBINS ( ch_unbins_gz )
    ch_unbinned_bins = GUNZIP_UNBINS.out.gunzip
        .groupTuple(by: 0)

    //
    // MODULE: CHECKM2 for bin quality control
    //
    if(!params.checkm2_db) {
        CHECKM2_DATABASEDOWNLOAD(params.checkm2_db_version)
        ch_checkm2_db = CHECKM2_DATABASEDOWNLOAD.out.database
    } else {
        ch_checkm2_db = Channel.fromPath(params.checkm2_db)
    }

    ch_checkm2_database = ch_checkm2_db.map { db ->
        def dbmeta = [id: 'checkm2']
        [dbmeta, db]
    }.first()
    
    CHECKM2_PREDICT( ch_bins, ch_checkm2_database )

    ch_qc_summaries = CHECKM2_PREDICT.out.checkm2_tsv
        .map { _meta, summary -> [[id: 'checkm2'], summary] }
        .groupTuple()
    ch_versions = ch_versions.mix(CHECKM2_PREDICT.out.versions.first())

    // 
    // MODULE: DRep for dereplication - collect all bins for dereplication
    //
    ch_bins_for_drep = ch_bins
        .map { meta, bin_list -> bin_list }
        .flatten()
        .collect()
    
    ch_checkm2_for_drep = CHECKM2_PREDICT.out.checkm2_tsv
        .map { meta, tsv -> tsv }
        .collect()
    
    DREP_DEREPLICATE (
        ch_bins_for_drep,
        params.derep_minimum_identity, 
        params.contamination_threshold,
        params.completeness_threshold,
        ch_checkm2_for_drep
    )
    ch_filtered_bins = DREP_DEREPLICATE.out.directory
        .map { directory ->
            def meta = [id: 'drep_dereplicated', binner: 'DRep', refinement: 'dereplicated']
            [meta, directory]
        }

    //
    // MODULE: GTDB-Tk for taxonomic classification
    //
    ch_gtdbtk_db = Channel.fromPath(params.gtdbtk_database)
    ch_gtdbtk_database = ch_gtdbtk_db.map { db ->
        def dbmeta = [id: params.gtdbtk_db_name]
        [dbmeta, db]
    }
    
    GTDBTK_CLASSIFYWF (
        ch_filtered_bins,
        ch_gtdbtk_database,
        false,
        []
    )
    ch_versions = ch_versions.mix(GTDBTK_CLASSIFYWF.out.versions.first())

    // 
    // MODULE: GAPSEQ for annotation
    // 
    // GAPSEQ_ANNOTATE ( ch_filtered_bins )

    // // Cluster bins by GTDB-Tk classification
    // ch_bins_for_clustering = GTDBTK_CLASSIFYWF.out.bins
    //     .groupTuple()
    
    // //
    // // MODULE: Pandraft
    // //
    // GAPSEQ_PANGENOME ()

    // //
    // // MODULE: GAPSEQ model
    // // 
    // GAPSEQ_MODEL ()

    // // 
    // // MODULE: GAPSEQ flux analysis
    // //
    // GAPSEQ_FLUXANALYSIS ()
    
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
