#!/usr/bin/env bash
#
#

#
INPUTDIR=./input
OUTPUTDIR=./output
LOGDIR=./log
RUNLOG=$LOGDIR/RUNLOG
FIND_RESULTS_FILE=$OUTPUTDIR/findTranscriptionIDs.tsv.txt
[ ! -d "$INPUTDIR" ] && mkdir $INPUTDIR
[ ! -d "$OUTPUTDIR" ] && mkdir $OUTPUTDIR
[ ! -d "$LOGDIR" ] && mkdir $LOGDIR
[ -f "$RUNLOG" ] && > $RUNLOG
[ -f "$FIND_RESULTS_FILE" ] && > $FIND_RESULTS_FILE

# input files
QUANT_FILE=${1:-$INPUTDIR/wbc_quant/wbc.quant.sf}
TRINOTATE_FILE=${2:-$INPUTDIR/wbc_quant/trinotate_annotation_report.xls}
echo "Matching up TranscriptIDs for following files:"
echo "(${QUANT_FILE##*/})"
echo "(${TRINOTATE_FILE##*/})"
echo
#

# extract index transcriptionIDs from quant.sf file to drive our main loop
TRANSCRIPTION_IDS_20=$(grep TRI $QUANT_FILE| awk '{print $1}'| sort -u| head -20)     # TEST MODE: run only 1st 20
#TRANSCRIPTION_IDS=$(grep TRI $QUANT_FILE| awk '{print $1}'| sort -u)

echo "Results will be written to: (${FIND_RESULTS_FILE})"
echo "Seeking $(echo "$TRANSCRIPTION_IDS_20"| wc -l) unique TransctionIDs from file: ${QUANT_FILE##*/}"


# MAIN LOOP
for TID in $(echo "$TRANSCRIPTION_IDS_20")
do
    QUANT_BITS=$(grep $TID $QUANT_FILE|tr -d '\n')
    TRINOTATE_BITS=$(grep $TID $TRINOTATE_FILE|cut -f3,7|tr -d '\n')

    echo -n "."
    # log for Not found in Trinotate
    ##[ -z "$TRINOTATE_BITS" ] && echo "$TID: NOT FOUND" >> $RUNLOG  
    #[[ "$TRINOTATE_BITS" =~ "(?=.*\t)(?=.*\.)" ]] && echo "$TID: NOT FOUND" >> $RUNLOG || echo "$TID: $TRINOkTATE_BITS" >> $RUNLOG
    #regex_trinotate_empty="^[\t.]*$"
    ##regex_trinotate_empty='^[\.\t]+$'
    #regex_trinotate_empty='(^|\t)(\t|\.|..)($|\t)'
    regex_trinotate_empty='^(\.?|\.\.?)\t(\.?|\.\.?)\t(\.?|\.\.?)\t(\.?|\.\.?)$'
    ##[[ "$TRINOTATE_BITS" =~ "^[.\t]+$" ]] && echo "$TID: NOT FOUND" >> $RUNLOG || echo "$TID: $TRINOTATE_BITS" >> $RUNLOG
    #[[ "$TRINOTATE_BITS" =~ ^[\.\t]+$ ]] && echo "$TID: NOT FOUND" >> $RUNLOG
    [[ $TRINOTATE_BITS =~ $regex_trinotate_empty ]] && echo "$TID: NOT FOUND" >> $RUNLOG
    #echo "$TID: $TRINOTATE_BITS" >> ./trinotate_bits
    
    # out put results
    ##[ ! -z "$TRINOTATE_BITS" ] && echo -e "$QUANT_BITS\t$TRINOTATE_BITS" >> $FIND_RESULTS_FILE 
    [[ "$TRINOTATE_BITS" =~ "^\.\t\.$" ]] || echo -e "$QUANT_BITS\t$TRINOTATE_BITS" >> $FIND_RESULTS_FILE
done

echo Done.