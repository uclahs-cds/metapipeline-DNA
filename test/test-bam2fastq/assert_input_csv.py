#!/bin/env python
""" Assert input csv generated for align-DNA is correct """
import argparse
from pathlib import Path
import csv


def parse_args():
    """ parse args """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'RECEIVED',
        type=Path,
        help='Path to the received input-csv'
    )
    parser.add_argument(
        'EXPECTED',
        type=Path,
        help='Path to the expected input-csv'
    )
    return parser.parse_args()

def main():
    """ Main entrypoint """
    args = parse_args()
    with open(args.RECEIVED, 'rt') as x, open(args.EXPECTED, 'rt') as y:
        received = csv.DictReader(x)
        expected = csv.DictReader(y)
        for rec, exp in zip(received, expected):
            assert rec['read_group_identifier'] == exp['read_group_identifier']
            assert rec['sequencing_center'] == exp['sequencing_center']
            assert rec['library_identifier'] == exp['library_identifier']
            assert rec['platform_technology'] == exp['platform_technology']
            rec_r1 = Path(rec['read1_fastq']).name
            exp_r1 = Path(rec['read1_fastq']).name
            assert rec_r1 == exp_r1
            rec_r2 = Path(rec['read2_fastq']).name
            exp_r2 = Path(rec['read2_fastq']).name
            assert rec_r2 == exp_r2
    print('Assertion passed', flush=True)


if __name__ == '__main__':
    main()
