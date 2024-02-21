#!/bin/bash
function md5_bed {
    md5sum $1 | cut -f 1 -d ' '
}

received=$(md5_bed $1)
expected=$(md5_bed $2)

if [ "$received" == "$expected" ]; then
    echo "BED files are equal"
    exit 0
else
    echo "BED files are not equal" >&2
    exit 1
fi
