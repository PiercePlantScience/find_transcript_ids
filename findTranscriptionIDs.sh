#!/usr/bin/env bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
#
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

DISABLE_PRETTY_STATS=true

#
# QUANT FILTERS
MINQ_TPM=10
MINQ_LENGTH=1000

#
INPUTDIR=./input
OUTPUTDIR=/tmp/findTranscriptIDs/output
LOGDIR=/tmp/findTranscriptionIDs/log
RUNLOG=$LOGDIR/RUNLOG

# make & reset stuff..
#[ ! -d "$INPUTDIR" ] && mkdir -p $INPUTDIR
[ ! -d "$OUTPUTDIR" ] && mkdir -p $OUTPUTDIR
[ ! -d "$LOGDIR" ] && mkdir -p $LOGDIR

# aggregated output header
AGGREGATED_HEADER='Name\tLength\tEffectiveLength\tTPM\tNumReads\tsprot_Top_BLASTX_hit\tsprot_Top_BLASTP_hit'
FOUND_RESULTS_TMPFILE=$OUTPUTDIR/foundTranscriptionIDs.tsv.txt
FOUND_RESULTS_FILE_UNIQ=$OUTPUTDIR/foundTranscriptionIDsUniq.tsv.txt
EMPTY_RESULTS_FILE=$OUTPUTDIR/emptyTranscriptionIDs.tsv.txt

# reset the file no matter what
echo -e "$AGGREGATED_HEADER" > $FOUND_RESULTS_FILE_UNIQ
echo -e "$AGGREGATED_HEADER" > $EMPTY_RESULTS_FILE
if [ -f "$FOUND_RESULTS_TMPFILE" ]
then
    cat /dev/null > $FOUND_RESULTS_TMPFILE
else
    touch $FOUND_RESULTS_TMPFILE
fi

startTimeInSec=$(date +%s)
STARTTIME=$(date -d "@$startTimeInSec" -u "+%Y-%m-%d %H:%M:%S UTC")
[ -f "$RUNLOG" ] && echo "[$STARTTIME]${0##*/}: Logging started.">$RUNLOG

# input files
QUANTSF_FILE=${1:-$INPUTDIR/quant.sf.tsv_testcase}
ANNOTATION_FILE=${2:-$INPUTDIR/annotation_report.tsv_testcase}

[ ! -f "$QUANTSF_FILE" ] && { [ -t 0 ] && echo "quant.sf file (${QUANTSF_FILE##*/}) missing, exiting.."; exit 1; }
[ ! -f "$ANNOTATION_FILE" ] && { [ -t 0 ] &&  echo "annotation report (${ANNOTATION_FILE##*/}) missing, exiting.."; exit 1; }
[ -t 0 ] && {
    echo "Matching up TranscriptIDs for following files:"
    echo "(${QUANTSF_FILE##*/})"
    echo "(${ANNOTATION_FILE##*/})"
    echo
}

# extract index transcriptionIDs from quant.sf file to drive our main loop
QUANTSF_TIDS=$(awk -v target="$MINQ_LENGTH" '$2 > target {print}' "$QUANTSF_FILE"| awk '{print $1}'|grep TRI| sort -u)
[ -t 0 ] && {
    echo "Results will be written to: (${FOUND_RESULTS_FILE_UNIQ})"
    totalQuantSfTIDS=$(grep -c TRI "$QUANTSF_FILE"| tr -d '\n')
    totalLengthFiltered=$(echo "$QUANTSF_TIDS"| wc -l| tr -d '\n')
    #totalLengthFiltered=0
    ## Use a while loop to count lines
    #while IFS= read -r _; do
    #    ((totalLengthFiltered++))
    #done <<< "$QUANTSF_TIDS"
    #####WEIRD: all of Sudden the folowing stop working
    echo "TPM/Filtering $totalLengthFiltered/$totalQuantSfTIDS unique TransctionIDs from ${QUANTSF_FILE##*/} file with (Length > $MINQ_LENGTH):"
    echo "This may take awhile.."
}
echo "[$(date -u "+%Y-%m-%d %H:%M:%S UTC")] QuantSfTPM.FILTERED:">>$RUNLOG


# QuantSfFILTER
declare -A filteredQuantSf
filtered_records=0
for TID in $QUANTSF_TIDS
do
    QUANTSF_BITS=$(grep -w "$TID" "$QUANTSF_FILE"| uniq| tr -d '\n')
    #quantsf_tmp_length=$(echo "$QUANTSF_BITS"| cut -f2)
    #quantsf_tmp_effective_length=$(echo "$QUANTSF_BITS"| cut -f3)
    quantsf_tmp_tpm=$(echo "$QUANTSF_BITS"| cut -f4| tr -d '\n')
    #quantsf_tmp_num_reads=$(echo "$QUANTSF_BITS"| cut -f5)
    #quantsf_length=${quantsf_tmp_length%.*}
    quantsf_tpm=${quantsf_tmp_tpm%%.*}
    [ -z "$quantsf_tpm" ] && quantsf_tpm=0

    # QUANTSF FILTER SECTION
    ##if [ "$quantsf_tpm" -lt "$MINQ_TPM" ] || [ "$quantsf_length" -lt "$MINQ_LENGTH" ]
    if [ "$quantsf_tpm" -lt "$MINQ_TPM" ]
    then
	    echo -n "$TID($quantsf_tpm) ">>$RUNLOG
        continue
    fi

    # screen stats the current line and print the progress
    filtered_records=$((filtered_records + 1))
    [ -t 0 ] && {
        if $DISABLE_PRETTY_STATS
        then
            echo -n .
        else
            echo -ne "\rTPM/Filtered records: $filtered_records / $(echo "$QUANTSF_TIDS"| wc -l)"
        fi
    }
    # insert into hash for next step Mainloop processing
    filteredQuantSf["$TID"]="$QUANTSF_BITS"
done
[ -t 0 ] && echo .

processed_records=0
[ -t 0 ] && echo "Processing ${#filteredQuantSf[@]} filtered TransctionIDs from QuantSf:"
# MAIN LOOP
for TID in "${!filteredQuantSf[@]}"
do
    ANNOTATION_BITS=$(grep -w "$TID" "$ANNOTATION_FILE"| cut -f3,7| uniq)
    [ -z "$ANNOTATION_BITS" ] && numMatch=0 || numMatch=$(echo "$ANNOTATION_BITS"| wc -l)

    # Clear the current line and print the progress
    processed_records=$((processed_records + 1))
    [ -t 0 ] && {
        if $DISABLE_PRETTY_STATS
        then
            echo -n .
        else
            echo -ne "\rProcessed records: $processed_records / ${#filteredQuantSf[@]}"
        fi
    }

    # REGEX ANNOTATION EMPTY
    regex_annotation_empty="^.+[A-Z]+.+$"        # inverse match, is this good enough?

    [[ $ANNOTATION_BITS =~ $regex_annotation_empty ]]|| echo -e "$(echo "${filteredQuantSf[$TID]}"|tr -d '\n')\t$(echo "$ANNOTATION_BITS"|tr -d '\n')">>$EMPTY_RESULTS_FILE

    if [ "$numMatch" -gt 0 ]
    then
        while IFS= read -r MATCHED_BITS; do
            # Process each line here
             MATCHED_BITS=$(echo "$MATCHED_BITS"|tr -d '\n')
             [[ $MATCHED_BITS =~ $regex_annotation_empty ]]&& echo -e "${filteredQuantSf[$TID]}\t$MATCHED_BITS">>$FOUND_RESULTS_TMPFILE
        done <<< "$ANNOTATION_BITS"
	echo "[$(date -u "+%Y-%m-%d %H:%M:%S UTC")] $TID: TPM($(echo -e "${filteredQuantSf[$TID]}"|cut -f4)) found($numMatch)">>$RUNLOG
    else
        # log notfound
	echo "[$(date -u "+%Y-%m-%d %H:%M:%S UTC")] $TID: TPM($(echo -e "${filteredQuantSf[$TID]}"|cut -f4)) NOTFOUND">>$RUNLOG
    fi
done
[ -t 0 ] && echo .

# sort -u the result file and sum the dups
[ -f "$FOUND_RESULTS_TMPFILE" ] && {
    wcResults=$(wc -l $FOUND_RESULTS_TMPFILE| awk '{print $1}'|tr -d '\n')
    sort -u $FOUND_RESULTS_TMPFILE>>$FOUND_RESULTS_FILE_UNIQ
    wcUniqResults=$(wc -l $FOUND_RESULTS_FILE_UNIQ| awk '{print $1}'|tr -d '\n')
    wcUniqResults=$((wcUniqResults-1))
    if [ "$wcResults" -ne "$wcUniqResults" ]
    then
    	dupResults=$((wcResults - wcUniqResults))
    	[ -t 0 ] && echo "wcResults($wcResults), wcUniqResults($wcUniqResults)"
    	echo "[$(date -u "+%Y-%m-%d %H:%M:%S UTC")] Total Dup Results was: $dupResults">>$RUNLOG
    fi
	rm -f "$FOUND_RESULTS_TMPFILE"
    numOfEmpty=$(wc -l $EMPTY_RESULTS_FILE| awk '{print $1}'| tr -d '\n')
    [ "$numOfEmpty" -le 1 ] && rm -f "$EMPTY_RESULTS_FILE"
    echo "[$(date -u "+%Y-%m-%d %H:%M:%S UTC")] Total Unique Results was: $wcUniqResults">>$RUNLOG
}

# end stats
stopTimeInSec=$(date +%s)
STOPTIME=$(date -d "@$stopTimeInSec" -u "+%Y-%m-%d %H:%M:%S UTC")
echo "[$STOPTIME] ${0##*/}: Logging stopped.">>$RUNLOG
[ -t 0 ] && echo "Total runtime was: $((stopTimeInSec - startTimeInSec)) seconds."
