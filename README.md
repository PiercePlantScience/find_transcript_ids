## find_transcript_ids

[![CI](https://github.com/PiercePlantScience/find_transcript_ids/actions/workflows/ci.yml/badge.svg)](https://github.com/PiercePlantScience/find_transcript_ids/actions/workflows/ci.yml)

![project banner](img/BANNER_findTranscriptionID_800x200.png)

<b>find_transcript_ids.sh -</b> is a simple shell script that take a <b>first-column unique index</b> source qaunt.sf file and will look for matches in a user supplied trinotate_annotated_report.xls file, and append BLASTX hit & BLASTP hit columns to a new TSV formated text file containing the quant.sf data as well as the matched line(s) - in the case where multiple matches are found, currently, the solution is to create a duplicate quant.sf row to accommodate the multiple matches (a one-to-many join essentially..).

Originally, the initial version of this script uses 2 FOR LOOPS to look for matches by iterate over the unique transcript_id from the qaunt_sf file and look for matches from the trinotate file - this method was found to be too expensive, and is essentially the "Brute Force" solution to the task.  By making more efficient use of linux's/unix's AWK & SORT/JOIN utilities, the same task can be accomplish with significantly less compute power -  more of this can be found in the [Details](#details) section.


## Table of Contents

- [Details](#details)
- [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Contributing](#contributing)
- [Modifications](#modifications)
- [ChangeLog](#changelog)

## Details

### Script Layout

Script is named: <b>find_transcript_ids.sh</b> and has the following dependcies files under a hidden system directory called: <b>.func/</b> -

```bash
.func/
`-- .find_transcript_ids_vars_n_functions
`-- .shell_functions
```

<b>.func/.find_transcript_ids_vars_n_functions - </b>contains variables and functions relating to the transcript process.<br>
<b>.func/.shell_functions - </b>contains functions that support general shell functions, such as paramater handling, help menus, user feedbacks, logging, & timestamps/accumulators.
<br>
<br>
The script probably error on the side of too many named VARIABLES for all the intermediate files, and this was done to allow ease of debugging, ultimately - so all command step changes can be backtraced (so debugged enabled by default;)..
<br>
Here's explicit list of them (Note: the default /tmp output dir can be changed with command line option: "--OUTPUT_DIR=<user-writable-dir>") -
```bash
(TO ADD..)
```
<br>
Here are the main linux/unix commands used in sequence in <b>find_transcript_ids.sh - </b>

- <b>awk</b> x > xmin & y > ymin <i>*quant.sf</i> file
- <b>sort</b> & replace header in <i>*quant.sf</i> file
- <b>grep</b> 'Eukaryota' in <i>*trinotate</i> file & cut out only needed columns: <b>tid|blastx|blastp</b>
- <b>sort/uniq</b> the <i>*trinotate</i> file
- <b>sort</b> again the <i>*trinotate</i> file
- <b>join</b>(ing) <i>*trinotate</i> & <i>*quant.sf</i> files
- <b>grep</b> -V "NONPLANT_GREP_STRING" from the <i>*joined</i> file

(***this script have been tested to work with git bash for windows**)

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
