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
- [ChangeLog](#changelog)

## Installation

## Usage

```bash
# assuming the qaunt.sf & trinotate_annotation_report.xls are of expected file types, formats, & in their expected location relative the current working directory

./findTranscriptionIDs.sh <quant.sf> <trinotate_annotation_report.xls>

# w/o parameters the script is expecting the hard-coded named files are in the input/wbc_quant directory.

./findTranscriptionIDs.sh
```

## Features

## Contributing

## ChangeLog

(updated 12/14/23) - refactor script for correct WBC quant.sf files

- script finished/tested: see attached zip, pending UAT.
- script now take input parameters of (quant.sf, trinotate_report) files & will default to looking for the named files in input/wbc_quant directory.
- script now outputs matches with empty BLASTX & BLASTP hits to log/NOTFOUND
- added aggregated header for output files
- TODO: add similarity% elimination logic by comparing BLAST data, if required; 2) make script both callable user & scripts
