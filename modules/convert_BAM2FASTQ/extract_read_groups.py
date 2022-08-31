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
    parser.add_argument(
        '--id-for-pu',
        action='store_true',
        help='Use the ID value for PU tag'
    )
    return parser.parse_args()

def create_read_groups(bam:Path, output:Path, sequencing_center:str,
        platform_unit:str, id_for_pu:bool) -> None:
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
        'sequencing_center': 'LB',
        'library_identifier': 'LB',
        'platform_technology': 'PL',
        'platform_unit': 'PU',
        'sample': 'SM'
    }

    with open(output, 'wt', encoding='utf8') as handle:
        handle.write(','.join(fields) + '\n')
        for i, read_group in enumerate(read_groups):
            row = []
            for field in fields:
                if field in ['index', 'lane']:
                    row.append(str(i))
                elif field == 'sequencing_center' and sequencing_center:
                    row.append(sequencing_center)
                elif field == 'platform_unit' and platform_unit or id_for_pu:
                    if id_for_pu:
                        row.append(read_group['ID'])
                    else:
                        row.append(platform_unit)
                else:
                    row.append(read_group[fields_map[field]])
            handle.write(','.join(row) + '\n')

def main():
    """ Main entry point """
    args = parse_args()
    try:
        create_read_groups(
            bam=args.input_bam,
            output=args.output_csv,
            sequencing_center=args.sequencing_center,
            platform_unit=args.platform_unit,
            id_for_pu=args.id_for_pu
        )
    except ValueError as error:
        if error.args[0] == BAM_HAS_NO_RG_ERROR:
            print(BAM_HAS_NO_RG_ERROR, file=sys.stderr)
            sys.exit(1)

if __name__ == '__main__':
    main()
