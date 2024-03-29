process CREATE_INDEX_FILE {
    container 'adbennett/pandas_excel:2.0.2'

    input:
    path index_file
    path plate_file
    path metadata
    val assays

    output:
    path "indices.csv", emit: index_file

    when:
    task.ext.when == null || task.ext.when

    script:
    def index_file = "'$index_file'"
    def plate_file = "'$plate_file'"
    def metadata   = "'$metadata'"
    def assays     = "'$assays'"
    """
    #!/usr/bin/env python3

    # Setup
    import pandas as pd
    assay_list = ${assays}.split(",")

    metadata_df = pd.read_csv(${metadata})

    if ${index_file} == "valid_index_file.csv":
        index_df = pd.read_csv(${index_file})
        index_df.to_csv("indices.csv", index=False)
    else:
        # Create df with all columns needed for indices file
        index_df = pd.DataFrame(columns = ["sample_id", "assay", "index_seq_fw", "index_seq_rv", "full_primer_seq_fw", "full_primer_seq_rv", "fw_no", "rv_no"])
        
        for assay in assay_list:
            curr_plate_df = pd.read_excel(${plate_file}, sheet_name = assay + "_plate", dtype=str)
            curr_index_df = pd.read_excel(${plate_file}, sheet_name = assay + "_index", dtype=str)

            # Loop through each sample in plate df, then get all the information needed for that sample
            for col in curr_plate_df.columns:
                if col != "f_primers":
                    for row in range(len(curr_plate_df.index)):
                        if not pd.isna(curr_plate_df.at[row,col]):
                            fw_no = col
                            rv_no = curr_plate_df.at[row,"f_primers"]

                            entry = pd.DataFrame({ \
                                "sample_id":[curr_plate_df.at[row,col]], \
                                "assay":[assay], \
                                "index_seq_fw":[curr_index_df.loc[curr_index_df["primer_#"] == fw_no, "tags"].values[0]], \
                                "index_seq_rv":[curr_index_df.loc[curr_index_df["primer_#"] == rv_no, "tags"].values[0]], \
                                "full_primer_seq_fw":[curr_index_df.loc[curr_index_df["primer_#"] == fw_no, "primer_seq"].values[0]], \
                                "full_primer_seq_rv":[curr_index_df.loc[curr_index_df["primer_#"] == rv_no, "primer_seq"].values[0]], \
                                "fw_no":[fw_no], \
                                "rv_no":[rv_no] })
                            index_df = pd.concat([index_df, entry], ignore_index=True)
        
        index_df.to_csv("indices.csv", index=False)
    """ 
}