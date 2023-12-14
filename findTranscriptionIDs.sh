#!/usr/bin/env bash
#
#

#
INPUTDIR=./input
OUTPUTDIR=./output
LOGDIR=./log
RUNLOG=$LOGDIR/RUNLOG
NOTFOUNDLOG=$LOGDIR/NOTFOUND
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
##TRANSCRIPTION_IDS_20=$(grep TRI $QUANT_FILE| awk '{print $1}'| sort -u| head -200)     # TEST MODE: run only 1st 20
TRANSCRIPTION_IDS=$(grep TRI $QUANT_FILE| awk '{print $1}'| sort -u)

echo "Results will be written to: (${FIND_RESULTS_FILE})"
echo "Seeking $(echo "$TRANSCRIPTION_IDS"| wc -l) unique TransctionIDs from file: ${QUANT_FILE##*/}"


# MAIN LOOP
for TID in $(echo "$TRANSCRIPTION_IDS")
do
    QUANT_BITS=$(grep $TID $QUANT_FILE|tr -d '\n')
    TRINOTATE_BITS=$(grep $TID $TRINOTATE_FILE|cut -f3,7|tr -d '\n')

    echo -n "."
    regex_trinotate_empty="^.+[A-Z]+.+$"        # inverse match, good eough?
    #[[ $TRINOTATE_BITS =~ $regex_trinotate_empty ]] || echo "$TID: NOT FOUND" >> $RUNLOG
    [[ $TRINOTATE_BITS =~ $regex_trinotate_empty ]] || echo -e "$QUANT_BITS\t$TRINOTATE_BITS" >> $NOTFOUNDLOG
    
    # out put results
    [[ $TRINOTATE_BITS =~ $regex_trinotate_empty ]] && echo -e "$QUANT_BITS\t$TRINOTATE_BITS" >> $FIND_RESULTS_FILE
done

echo Done.