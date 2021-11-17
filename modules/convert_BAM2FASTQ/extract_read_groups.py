""" Extract read groups from a BAM header and returns a CSV """
import argparse
from pathlib import Path
import sys
import pysam


BAM_HAS_NO_RG_ERROR = 'BAM file has no RG'

def parse_args() -> argparse.Namespace:
    """ Parse args """
    parser = argparse.ArgumentParser(
        'extract_read_groups.py'
    )
    parser.add_argument(
        '-i', '--input-bam',
        type=Path,
        help='Path to the input BAM file',
        metavar='<file>',
        required=True
    )
    parser.add_argument(
        '-o', '--output-csv',
        type=Path,
        help='Path to the output CSV file.',
        metavar='<file>',
        required=True
    )
    parser.add_argument(
        '--sequencing-center',
        type=str,
        help='CN tag to override the value from BAMs.',
        metavar='<value>',
        default=None
    )
    parser.add_argument(
        '--platform-unit',
        type=str,
        help='PU tag to override the value from BAMs.',
        metavar='<value>',
        default=None
    )
    return parser.parse_args()

def create_read_groups(bam:Path, output:Path, sequencing_center:str,
        platform_unit:str) -> None:
    """ Create a read group CSV file from a BAM """
    bam_file = pysam.AlignmentFile(bam, mode='r')
    header = bam_file.header
    if 'RG' not in header:
        raise ValueError(BAM_HAS_NO_RG_ERROR)
    read_groups = header['RG']

    fields = [
        'index',
        'read_group_identifier',
        'sequencing_center',
        'library_identifier',
        'platform_technology',
        'platform_unit',
        'sample',
        'lane'
    ]

    fields_map = {
        'read_group_identifier': 'ID',
        'sequencing_center': 'CN',
        'library_identifier': 'LB',
        'platform_technology': 'PL',
        'platform_unit': 'PU',
        'sample': 'SM'
    }

    with open(output, 'wt') as handle:
        handle.write(','.join(fields) + '\n')
        for i, read_group in enumerate(read_groups):
            row = []
            for field in fields:
                if field in ['index', 'lane']:
                    row.append(str(i))
                elif field == 'sequencing_center' and sequencing_center:
                    row.append(sequencing_center)
                elif field == 'platform_unit' and platform_unit:
                    row.append(platform_unit)
                else:
                    row.append(read_group[fields_map[field]])
            handle.write(','.join(row) + '\n')

def main():
    """ Main entry point """
    args = parse_args()
    try:
        create_read_groups(args.input_bam, args.output_csv)
    except ValueError as error:
        if error.args[0] == BAM_HAS_NO_RG_ERROR:
            print(BAM_HAS_NO_RG_ERROR, file=sys.stderr)
            sys.exit(1)

if __name__ == '__main__':
    main()
