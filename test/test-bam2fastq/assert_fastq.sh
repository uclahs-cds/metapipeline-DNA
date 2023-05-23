#!/bin/bash
function md5_fastq {
    zcat $1 | md5sum | cut -f 1 -d ' '
}

received=$(md5_fastq $1)
expected=$(md5_fastq $2)

if [ "$received" == "$expected" ]; then
    echo "FASTQ files are equal"
    exit 0
else
    echo "FASTQ files are not equal" >&2
    exit 1
fi
