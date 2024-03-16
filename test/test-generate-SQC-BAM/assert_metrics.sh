#!/bin/bash
function md5_metrics {
    cat "$1" | grep -v '^# ' | md5sum | cut -f 1 -d ' '
}

received=$(md5_metrics "$1")
expected=$(md5_metrics "$2")

if [ "$received" == "$expected" ]; then
    echo "Metrics files are equal"
    exit 0
else
    echo "Metrics files are not equal" >&2
    exit 1
fi
