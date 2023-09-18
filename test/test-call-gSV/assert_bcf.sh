#!/bin/bash
function md5_bcf {
    bcftools view -H $1 | md5sum | cut -f 1 -d ' '
}

if ! which bcftools &> /dev/null
then
    if ! module load bcftools &> /dev/null
    then
        echo "bcftools command not found! Comparison failed by default." >&2
        exit 1
    fi
fi

received=$(md5_bcf $1)
expected=$(md5_bcf $2)

if [ "$received" == "$expected" ]; then
    echo "BCF files are equal"
    exit 0
else
    echo "BCF files are not equal" >&2
    exit 1
fi
