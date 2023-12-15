#!/usr/bin/env bash
#
#

#
INPUTDIR=./input
OUTPUTDIR=./output
LOGDIR=./log
RUNLOG=$LOGDIR/RUNLOG
NOTFOUNDLOG=$LOGDIR/NOTFOUND

# aggregated output header
AGGREATED_HEADER='Name\tLength\tEffectiveLength\tTPM\tNumReads\tsprot_Top_BLASTX_hit\tsprot_Top_BLASTP_hit'
FIND_RESULTS_FILE=$OUTPUTDIR/findTranscriptionIDs.tsv.txt

# make & reset stuff..
[ ! -d "$INPUTDIR" ] && mkdir $INPUTDIR
[ ! -d "$OUTPUTDIR" ] && mkdir $OUTPUTDIR
[ ! -d "$LOGDIR" ] && mkdir $LOGDIR
[ -f "$RUNLOG" ] && > $RUNLOG
[ -f "$NOTFOUNDLOG" ] && echo -e "$AGGREATED_HEADER"> $NOTFOUNDLOG
[ -f "$FIND_RESULTS_FILE" ] && echo -e "$AGGREATED_HEADER"> $FIND_RESULTS_FILE

# input files
QUANT_FILE=${1:-$INPUTDIR/wbc_quant/wbc.quant.sf}
TRINOTATE_FILE=${2:-$INPUTDIR/wbc_quant/trinotate_annotation_report.xls}
echo "Matching up TranscriptIDs for following files:"
echo "(${QUANT_FILE##*/})"
echo "(${TRINOTATE_FILE##*/})"
echo

# extract index transcriptionIDs from quant.sf file to drive our main loop
##TRANSCRIPTION_IDS_20=$(grep TRI $QUANT_FILE| awk '{print $1}'| sort -u| head -200)     # TEST EX.: to run only 1st 200
TRANSCRIPTION_IDS=$(grep TRI $QUANT_FILE| awk '{print $1}'| sort -u)

echo "Results will be written to: (${FIND_RESULTS_FILE})"
echo "Seeking $(echo "$TRANSCRIPTION_IDS"| wc -l) unique TransctionIDs from file: ${QUANT_FILE##*/}"


# MAIN LOOP
for TID in $(echo "$TRANSCRIPTION_IDS")
do
    QUANT_BITS=$(grep $TID $QUANT_FILE|tr -d '\n')
    TRINOTATE_BITS=$(grep $TID $TRINOTATE_FILE|cut -f3,7|tr -d '\n')

    echo -n "."
    regex_trinotate_empty="^.+[A-Z]+.+$"        # inverse match, is this good enough?
    #[[ $TRINOTATE_BITS =~ $regex_trinotate_empty ]] || echo "$TID: NOT FOUND" >> $RUNLOG
    [[ $TRINOTATE_BITS =~ $regex_trinotate_empty ]] || echo -e "$QUANT_BITS\t$TRINOTATE_BITS" >> $NOTFOUNDLOG
    
    # out put results
    [[ $TRINOTATE_BITS =~ $regex_trinotate_empty ]] && echo -e "$QUANT_BITS\t$TRINOTATE_BITS" >> $FIND_RESULTS_FILE
done

echo Done.