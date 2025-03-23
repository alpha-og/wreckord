# Wreckord

A simple script to generate all the required latex code for the OS Lab based on the template used.

## Prerequisites

- LaTeX
- `jq`
- `bash`

## Setup

1. Clone this repository

```bash
git clone https://github.com/alpha-og/wreckord.git
cd wreckord
```

2. Copy the files for each problem into the corresponding directories. For example, when considering `p12` (problem 12), copy the proogram into `p12/code.c` and the output screenshots into `p12/o-1.png`, `p12/o-2.png`, etc.

## Usage

1. `chmod +x ./wreckord.sh`
2. Run the script `./wreckord.sh`

The script will generate and place the output files into `out/` directory. For convenience, the script also copies the dependencies of each problem (code, images, aim, algorithm) into the `out/pxx` directory. Dropping the `out/` directory into overleaf is all you need to do to obtain the final document.
