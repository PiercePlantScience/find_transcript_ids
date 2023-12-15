## findTranscriptionIDs

findTranscriptionIDs.sh - refactor script for correct WBC quant.sf files

- script finished/tested: see attached zip, pending UAT.
- script now take input parameters of (quant.sf, trinotate_report) files & will default to looking for the named files in input/wbc_quant directory.
- script now outputs matches with empty BLASTX & BLASTP hits to log/NOTFOUND
- added aggregated header for output files
- TODO: add similarity% elimination logic by comparing BLAST data, if required; 2) make script both callable user & scripts

(updated 12/14/23)
