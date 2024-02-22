#!/usr/bin/env bash
#
#

SCRIPT_TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
source .func/.find_transcript_ids_vars_n_functions

#
parse_arguments "$@"

echo "TPM_MIN is $TPM_MIN"
echo "LEN_MIN is $LEN_MIN"
echo "QUANTSF_FILE is $QUANTSF_FILE"
echo "TRINOTATE_FILE is $TRINOTATE_FILE"
echo "OUTPUT_DIR is $OUTPUT_DIR"

LOGDIR=$OUTPUT_DIR/log
TMPDIR=$OUTPUT_DIR/tmp
RUNLOG=$LOGDIR/RUNLOG
FOUND_FILE=$OUTPUT_DIR/FOUND.tsv.txt

source .func/.shell_functions

echo "LOGDIR is $LOGDIR"
echo "RUNLOG is $RUNLOG"
echo "FOUND_FILE is $FOUND_FILE"
#echo "NONPLANT_GREP_STRING is $NONPLANT_GREP_STRING"

[ ! -d "$LOGDIR" ] && mkdir -p $LOGDIR
[ ! -d "$TMPDIR" ] && mkdir -p $TMPDIR
[ ! -f "$QUANTSF_FILE" ] || [ ! -f "$TRINOTATE_FILE" ] && { 
    echo "Required Files:"
    echo "$QUANTSF_FILE and/or $TRINOTATE_FILE"
    echo "Not Found, Exiting.."
    exit 1
}

[ -t 0 ] && {
    echo "Matching up TranscriptIDs for following files:"
    echo "(${QUANTSF_FILE##*/})"
    echo "(${TRINOTATE_FILE##*/})"
    echo
}

# lets keep track of the script total runtime
script_start=$(date +%s.%N)

#
# PROCESS QUANT.SF
#
log_event "PROCESSING QUANT.SF ($QUANTSF_FILE) >>>>>"

# intermediary files
FILTERED_QUANTSF_FILE=$TMPDIR/filtered_quantsf_file
SORTED_FILTERED_QUANTSF_FILE=$TMPDIR/sorted_filtered_quantsf_file

# filter by LEN_MIN & TPM_MIN
# CMD: awk x > xmin & y > ymin *quant.sf file
##run_command "Filtering by LEN_MIN & TPM_MIN" "awk -F'\t' '\$2 > 1000 && \$4 > 10' \"$QUANTSF_FILE\" > \"$FILTERED_QUANTSF_FILE\""
#run_command "Filtering by LEN_MIN($LEN_MIN) & TPM_MIN($TPM_MIN)" "awk -F'\t' -v len_min=$LEN_MIN -v len_tpm=$LEN_TPM '\$2 > len_min && \$4 > len_tpm' \"$QUANTSF_FILE\" > \"$FILTERED_QUANTSF_FILE\""
run_command "Filtering by LEN_MIN($LEN_MIN) & TPM_MIN($TPM_MIN)" "awk -F'\t' -v len_min=$LEN_MIN -v len_tpm=$TPM_MIN '\$2 > len_min && \$4 > len_tpm' \"$QUANTSF_FILE\" > \"$FILTERED_QUANTSF_FILE\""

# CMD: sort & replace header in *quant.sf file
# sort and prep quant.sf file for join with our trinotate file
run_command "Sorting quant.sf" "sort -t $'\t' -k1,1 \"$FILTERED_QUANTSF_FILE\" > \"$SORTED_FILTERED_QUANTSF_FILE\""
run_command "Fixing quant.sf" "sed -i '1s/Name/transcript_id/' \"$SORTED_FILTERED_QUANTSF_FILE\""

# tally file proc results
count_sorted_filtered_quantsf_file=$(wc -l< $SORTED_FILTERED_QUANTSF_FILE); ((count_sorted_filtered_quantsf_file--))
count_quantsf_file=$(wc -l< $QUANTSF_FILE); ((count_quantsf_file--))
log_event "::quant.sf counts now: ($count_sorted_filtered_quantsf_file/$count_quantsf_file)"

#
# PROCESS TRINOTATE FILE
#
log_event "PROCESSING TRINOTATE ($TRINOTATE_FILE) >>>>>"

# intermediary files
EUKARYOTA_FILTERED_TRINOTATE_FILE=$TMPDIR/eukaryota_filtered_trinotate_file
TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE=$TMPDIR/trimmed_eukaryota_filtered_trinotate_file
UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE=$TMPDIR/uniqued_trimmed_eukaryota_filtered_trinotate_file
SORTED_UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE=$TMPDIR/sorted_uniqued_trimmed_eukaryota_filtered_trinotate_file
JOIN_FILE=$TMPDIR/join_file

# filtering only for 'Eukaryota', trimming for only transcript_id|BLASTX|BLASTP
# CMD: grep 'Eukaryota' in *trinotate file & cut out only needed columns: tid|blastx|blastp
run_command "Filtering 'Eukaryota' from trinotate file" "(head -n 1 \"$TRINOTATE_FILE\" && tail -n +2 \"$TRINOTATE_FILE\" | grep \"Eukaryota\") > \"$EUKARYOTA_FILTERED_TRINOTATE_FILE\""
run_command "Trimming BLASTX & BLASTP" "cut -f2,3,7 \"$EUKARYOTA_FILTERED_TRINOTATE_FILE\" > \"$TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE\""

# prep header & remove dups in our intermediary working file
# CMD: sort/uniq the *trinotate file
run_command "Removing Dups Step #1: Prep Intermmediate file's header" "head -n 1 \"$TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE\" > \"$UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE\""
run_command "Removing Dups, Step #2: Storing & removing Dups" "tail -n +2 \"$TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE\" | sort -ut $'\t' >> \"$UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE\""

# prep/sort trinotate for join operation w/quant.sf
# CMD: sort again the *trinotate file
run_command "Resorted the Newly minted Intermmediate file" "sort -t $'\t' -k1,1 \"$UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE\" > \"$SORTED_UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE\""

# tally file proc results
count_sorted_uniqued_trimmed_eukaryota_filtered_trinotate_file=$(wc -l< $SORTED_UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE)
((count_sorted_uniqued_trimmed_eukaryota_filtered_trinotate_file--))
count_trinotate_file=$(wc -l< $TRINOTATE_FILE); ((count_trinotate_file--))
log_event "::trinotate counts now: ($count_sorted_uniqued_trimmed_eukaryota_filtered_trinotate_file/$count_trinotate_file)"

#
# JOINING quant.sf & trinotate file
# CMD: join(ing) *trinotate & *quant.sf files
#
log_event "JOINING FILES quant.sf ($count_sorted_filtered_quantsf_file rows) & trinotate ($count_sorted_uniqued_trimmed_eukaryota_filtered_trinotate_file rows) intermediary files >>>>>"
log_event "quant.sf intermediary ($SORTED_FILTERED_QUANTSF_FILE)"
log_event "trinotate intermediary ($SORTED_UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE)"
run_command "Joining quant.sf & trinotate file" "join -t $'\t' \"$SORTED_FILTERED_QUANTSF_FILE\" \"$SORTED_UNIQUED_TRIMMED_EUKARYOTA_FILTERED_TRINOTATE_FILE\" > \"$JOIN_FILE\""

# filtering out non-plants
# CMD: grep -V "NONPLANT_GREP_STRING" from the *joined file
run_command "Last Step, filtering out non-plants" "grep -vi \"$NONPLANT_GREP_STRING\" \"$JOIN_FILE\" > \"$FOUND_FILE\""

# final count
count_found_file=$(wc -l< $FOUND_FILE); ((count_found_file--))
log_event "::Resulting Join File count is: ($count_found_file)"

#
#  JOB EXIT tasks: tally Join results & total script runtime
#
script_end=$(date +%s.%N)
script_run_duration=$(awk "BEGIN {print $script_end - $script_start}")
log_event "Script Runtime was: (${script_run_duration}s)"
log_event "RESULTING FOUND FILE is here - ($FOUND_FILE)"
echo
