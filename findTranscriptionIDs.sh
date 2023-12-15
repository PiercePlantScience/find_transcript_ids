#!/usr/bin/env bash
#
#
# QUANT FILTERS
MINQ_TPM=10
MINQ_LENGTH=1000

#
INPUTDIR=./input
OUTPUTDIR=./output
LOGDIR=./log
RUNLOG=$LOGDIR/RUNLOG
NOTFOUNDLOG=$LOGDIR/NOTFOUND

# aggregated output header
AGGREATED_HEADER='Name\tLength\tEffectiveLength\tTPM\tNumReads\tsprot_Top_BLASTX_hit\tsprot_Top_BLASTP_hit'
FOUND_RESULTS_FILE=$OUTPUTDIR/foundTranscriptionIDs.tsv.txt
EMPTY_RESULTS_FILE=$OUTPUTDIR/emptyTranscriptionIDs.tsv.txt

# make & reset stuff..
[ ! -d "$INPUTDIR" ] && mkdir $INPUTDIR
[ ! -d "$OUTPUTDIR" ] && mkdir $OUTPUTDIR
[ ! -d "$LOGDIR" ] && mkdir $LOGDIR
[ -f "$NOTFOUNDLOG" ] && echo -e "$AGGREATED_HEADER"> $NOTFOUNDLOG
[ -f "$FOUND_RESULTS_FILE" ] && echo -e "$AGGREATED_HEADER"> $FOUND_RESULTS_FILE
[ -f "$EMPTY_RESULTS_FILE" ] && echo -e "$AGGREATED_HEADER"> $EMPTY_RESULTS_FILE

startTimeInSec=$(date +%s)
STARTTIME=$(date -d "@$startTimeInSec" +"%D %T")
[ -f "$RUNLOG" ] && echo "[${0##*/}] started at: $STARTTIME">$RUNLOG

# input files
QUANT_FILE=${1:-$INPUTDIR/wbc_quant/wbc.quant.sf}
ANNOTATION_FILE=${2:-$INPUTDIR/wbc_quant/trinotate_annotation_report.xls}
echo "Matching up TranscriptIDs for following files:"
echo "(${QUANT_FILE##*/})"
echo "(${ANNOTATION_FILE##*/})"
echo

# extract index transcriptionIDs from quant.sf file to drive our main loop
#TRANSCRIPTION_IDS=$(grep TRI "$QUANT_FILE"| awk '{print $1}'| sort -u| head -50)     # TEST EX.: to run only 1st 50
TRANSCRIPTION_IDS=$(grep TRI "$QUANT_FILE"| awk '{print $1}'| sort -u)

echo "Results will be written to: (${FOUND_RESULTS_FILE})"
echo "Seeking $(echo "$TRANSCRIPTION_IDS"| wc -l) unique TransctionIDs from file: ${QUANT_FILE##*/}"


# MAIN LOOP
for TID in $TRANSCRIPTION_IDS
do
    QUANT_BITS=$(grep -w "$TID" "$QUANT_FILE"| uniq| tr -d '\n')
    quant_tmp_length=$(echo "$QUANT_BITS"| cut -f2)
    quant_length=${quant_tmp_length%.*}
    quant_tmp_tpm=$(echo "$QUANT_BITS"| cut -f4)
    quant_tpm=${quant_tmp_tpm%.*}

    # QUANT FILTER SECTION
    if [ "$quant_tpm" -lt "$MINQ_TPM" ] || [ "$quant_length" -lt "$MINQ_LENGTH" ]
    then
        echo "$TID: TPM($quant_tpm), Length($quant_length) QuantFILTERED">>$RUNLOG
        continue
    fi

    ANNOTATION_BITS=$(grep -w "$TID" "$ANNOTATION_FILE"| cut -f3,7| uniq)
    [ -z "$ANNOTATION_BITS" ] && numMatch=0 || numMatch=$(echo "$ANNOTATION_BITS"| wc -l)

    echo -n "."

    # REGEX ANNOTATION EMPTY
    regex_annotation_empty="^.+[A-Z]+.+$"        # inverse match, is this good enough?

    [[ $ANNOTATION_BITS =~ $regex_annotation_empty ]]|| echo -e "$(echo "$QUANT_BITS"|tr -d '\n')\t$(echo "$ANNOTATION_BITS"|tr -d '\n')">>$EMPTY_RESULTS_FILE
    
    if [ "$numMatch" -gt 0 ]
    then
        # for MATCHED_BITS in ${ANNOTATION_BITS}
        # do
        #     # output results
        #     #[[ $ANNOTATION_BITS =~ $regex_annotation_empty ]]&& echo -e "$QUANT_BITS\t$ANNOTATION_BITS">>$FOUND_RESULTS_FILE
        #     #MATCHED_BITS=${MATCHED_BITS/s/[[:space:]]*$//}
        #     MATCHED_BITS=$(echo "$MATCHED_BITS"|tr -d '\n')
        #     [[ $MATCHED_BITS =~ $regex_annotation_empty ]]&& echo -e "$QUANT_BITS\t$MATCHED_BITS">>$FOUND_RESULTS_FILE
        # done
        while IFS= read -r MATCHED_BITS; do
            # Process each line here
             MATCHED_BITS=$(echo "$MATCHED_BITS"|tr -d '\n')
             [[ $MATCHED_BITS =~ $regex_annotation_empty ]]&& echo -e "$QUANT_BITS\t$MATCHED_BITS">>$FOUND_RESULTS_FILE
        done <<< "$ANNOTATION_BITS"
        echo "$TID: TPM($quant_tpm), Length($quant_length), found($numMatch)">>$RUNLOG
    else
        # log notfound
        echo "$TID: TPM($quant_tpm), Length($quant_length), NOTFOUND">>$RUNLOG
    fi
done

echo Done.
stopTimeInSec=$(date +%s)
STOPTIME=$(date -d "@$stopTimeInSec" +"%D %T")
echo "[${0##*/}] ended at: $STOPTIME">>$RUNLOG
echo "Total runtime was: $((stopTimeInSec - startTimeInSec)) seconds."