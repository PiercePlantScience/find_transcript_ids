# findTranscriptionIDs

![project banner](img/BANNER_findTranscriptionID_800x200.png)

<!-- [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/your-username/your-repo.svg)](https://github.com/your-username/your-repo/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/your-username/your-repo.svg)](https://github.com/your-username/your-repo/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/your-username/your-repo.svg)](https://github.com/your-username/your-repo/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/your-username/your-repo.svg)](https://github.com/your-username/your-repo/pulls) -->

<b>findTranscriptionIDs.sh -</b> is a simple shell script that take a <b>first-column unique index</b> source qaunt.sf file and will look for matches in a user supplied trinotate_annotated_report.xls file, and append BLASTX hit & BLASTP hit columns to a new TSV formated file containing the quant.sf data as well as the matched line(s) - in the case where multiple matches are found, currently, the solution is to create a duplicate quant.sf row to accommodate the multiple matches.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Contributing](#contributing)
- [Modification Roadmaps](#modificationroadmaps)
- [ChangeLog](#changelog)

## Installation

```bash
# clone repo
git clone https://github.com/PiercePlantScience/findTranscriptionIDs
```

## Usage

```bash
# Cd into working repo directory
cd findTranscriptonIDs

## Usage Examples

# assuming the qaunt.sf & trinotate_annotation_report.xls are of expected file types, formats,
# & in their expected location relative the current working directory

./findTranscriptionIDs.sh <quant.sf> <trinotate_annotation_report.xls>

# Ex. 1 if TSV data files are in the working directory
./findTranscriptionIDs.sh quant.sf trinotate_annotation_report.xls
# -or-
./findTranscriptionIDs.sh ./quant.sf ./trinotate_annotation_report.xls

# Ex. 2 if TSV data files are in the working directory, but in another subfolder(s)
# say ./input/..
./findTranscriptionIDs.sh ./input/wbc_quant/quant.sf ./input/wbc_quant/trinotate_annotation_report.xls
# -or-
./findTranscriptionIDs.sh input/wbc_quant/quant.sf input/wbc_quant/trinotate_annotation_report.xls

# The examples above all make use of the relative file path forms for the parametersx

# In the Ex. 3 below, the parameters used would be an example of the absolute path forms (and one can usually distinquish absulute from relative paths by the starting character, as absolute will always start with the '/' character)
./findTranscriptionIDs.sh /tmp/quant.sf /tmp/wbc_quant/trinotate_annotation_report.xls

# Ex. 4 you can obviously mix the different path forms..
./findTranscriptionIDs.sh input/wbc_quant/quant.sf /tmp/trinotate_annotation_report.xls

# Ex. 5 w/o parameters the script will run the test case tsv file in the input/ directory:
# - input/quant.sf.tsv_testcase
# - input/trinotate_annotate_report.tsv_testcase
./findTranscriptionIDs.sh
....
```

## Features

- added testing data for quick script validation.
- defaults to running test data when file parameter(s) is(are) provided.
- script includes detailed logging
- script is callable by user or script.
- (*future enhancements): various filtering possiblities, update more compliant logging out formats.

## Contributing

- setup your sshkey & add it to this repo
- then use git protocol to "clone" (i.e. git clone <git@github.com>:PiercePlantScience/findTranscriptionIDs.git)
- update & test your changes
- submit pull request

## Modification Roadmaps
(notes from my code review/refactor session on 1/21/24) - 

- to improve performance of 2 loops in the script, we can for the "1st-loop" (this loop does the TPM>10 & Length>1000 filtering) which currently does not utilize awk & probably can get a performance boost here by converting the current use of cut/tr and bash's if to produce the filtered QUANTSF file.  The 2nd-loop can probably benefit by being refactored into 2 loops (one loop would do something similar to TRINOTATE file not different from the filtering "1st-loop" for the QUANTSF file - since now we have way to rid some anything that's not plant related from TRINOTATE; the other loop would do pretty much same thing as the original "2nd-loop", but I'm looking to convert the current Hash loop variable to a Hash-of-Arrays here that can be used across all the loops mentioned.
- while working out the TRINOTATE filtering, I discovered what I believe can achieve the same by just greping for "Eukaryota" in the TRINOTATE file - this might work better than filtering out via - mouse, human, bacteria, fungi, (viruses).. from the TRINOATE file - 1 grep command instead of many.


(notes from 1/17/24 meeting for "filtering" improvements) - 

- new algo for resolving BLASTX & BLASTP diffs for same transactionsIDs, only keep duplicate IDs if from different ranges, otherwise keep the best sample.
- elimination of none plants genes using following keywords - mouse, human, bacteria, fungi, and possibly others.


## ChangeLog

(updated 12/18/23) -

- Fixed lingering dups in output file
- change parameter usage behaviour.. (you must now expicitly declare input files when calling script - see Usage in README)
- also, when parameter-less the script will now run the *_testcase input file to allow validation of script functionality
- Refactor code loops for better efficiency
- Update to UTC logging format & cleanup logging
- Support no-tty scripting us
- Test to run on git-bash windows & Debian/Ubuntu linux

(updated 12/14/23) - refactor script for correct WBC quant.sf files

- script finished/tested: see attached zip, pending UAT.
- script now take input parameters of (quant.sf, trinotate_report) files & will default to looking for the named files in input/wbc_quant directory.
- script now outputs matches with empty BLASTX & BLASTP hits to log/NOTFOUND.
- added aggregated header for output files.
- TODO: add similarity% elimination logic by comparing BLAST data, if required; 2) make script both callable user & scripts.
