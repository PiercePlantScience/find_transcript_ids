## find_transcript_ids

![project banner](img/BANNER_findTranscriptionID_800x200.png)

<b>find_transcript_ids.sh -</b> is a simple shell script that take a <b>first-column unique index</b> source qaunt.sf file and will look for matches in a user supplied trinotate_annotated_report.xls file, and append BLASTX hit & BLASTP hit columns to a new TSV formated text file containing the quant.sf data as well as the matched line(s) - in the case where multiple matches are found, currently, the solution is to create a duplicate quant.sf row to accommodate the multiple matches (a one-to-many join essentially..).

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Contributing](#contributing)
- [Modifications](#modifications)
- [ChangeLog](#changelog)

## Installation

```bash
# clone repo
git clone https://github.com/PiercePlantScience/find_transcript_ids
```

## Usage

```bash
# Cd into working repo directory
cd find_transcript_ids

## Usage Examples

# assuming the qaunt.sf & trinotate_annotation_report.xls are of expected file types, formats,
# & in their expected location relative the current working directory

./find_transcript_ids.sh <quant.sf> <trinotate_annotation_report.xls>

# Ex. 1 if TSV data files are in the working directory
./find_transcript_ids.sh quant.sf trinotate_annotation_report.xls
# -or-
./find_transcript_ids.sh ./quant.sf ./trinotate_annotation_report.xls

# Ex. 2 if TSV data files are in the working directory, but in another subfolder(s)
# say ./input/..
./find_transcript_ids.sh ./input/wbc_quant/quant.sf ./input/wbc_quant/trinotate_annotation_report.xls
# -or-
./find_transcript_ids.sh input/wbc_quant/quant.sf input/wbc_quant/trinotate_annotation_report.xls

# The examples above all make use of the relative file path forms for the parametersx

# In the Ex. 3 below, the parameters used would be an example of the absolute path forms (and one can usually distinquish absulute from relative paths by the starting character, as absolute will always start with the '/' character)
./find_transcript_ids.sh /tmp/quant.sf /tmp/wbc_quant/trinotate_annotation_report.xls

# Ex. 4 you can obviously mix the different path forms..
./find_transcript_ids.sh input/wbc_quant/quant.sf /tmp/trinotate_annotation_report.xls

# Ex. 5 w/o parameters the script will run the test case tsv file in the input/ directory:
# - input/quant.sf.tsv_testcase
# - input/trinotate_annotate_report.tsv_testcase
./find_transcript_ids.sh
....
```

## Features

- This scipt now take user tweakable TPM_MIN, LEN_MIN, OUTPUT_DIR, TEST & HELP options..

```bash
$ ./find_transcription_ids.sh -h
Usage: ./find_transcription_ids.sh [options] [quant.sf] [trinotate.tsv]

Options:
  --TPM_MIN=<value>       Set the minimum TPM value
  --LEN_MIN=<value>       Set the minimum length value
  --OUTPUT_DIR=<value>    Set the RESULT file output directory (defaults to: /tmp/find_transcription_ids.sh)
                          **Must be User writable
  --TEST                    Run the built-in testcase to validate script
  -h, --help              Display this help message

Positional Arguments:
  quant.sf                Quant.sf file
  trinotate.tsv           Trinotate file

(**NOTE: Both these files are required to be in TSV format)

Example:
  ./find_transcription_ids.sh --TPM_MIN=15 --LEN_MIN=1500 quant.sf trinoate.tsv

```

- The script now uses 0 FORLOOPs is completely refactor & is significantly faster than the previous version - can now complete real workload  on my dev laptop ;)
