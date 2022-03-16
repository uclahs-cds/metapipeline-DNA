""" Create input csv for align-DNA """
import argparse
from pathlib import Path
import csv


def parse_args():
    """ parse args """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-r', '--read-groups',
        type=Path,
        help='Read groups'
    )
    parser.add_argument(
        '-q', '--fastq-files',
        type=Path,
        help='FASTQ files',
        nargs='+'
    )
    parser.add_argument(
        '-o', '--output-path',
        type=Path,
        help='Path to the output file'
    )
    return parser.parse_args()

def main():
    """ Main entrypoint """
    args = parse_args()
    with open(args.read_groups, 'rt', encoding='utf8') as in_handle, \
            open(args.output_path, 'w', encoding='utf8') as out_handle:
        reader = csv.DictReader(in_handle)
        fields = reader.fieldnames + ['read1_fastq', 'read2_fastq']
        writer = csv.DictWriter(out_handle, fields)
        writer.writeheader()
        for record in reader:
            fastq:Path
            rg_id = record['read_group_identifier']
            for fastq in args.fastq_files:
                if 'read1_fastq' in record and 'read2_fastq' in record:
                    break
                if fastq.name == f"collated_{rg_id}_R1.fq.gz":
                    record['read1_fastq'] = str(fastq.absolute())
                    continue
                if fastq.name == f"collated_{rg_id}_R2.fq.gz":
                    record['read2_fastq'] = str(fastq.absolute())
            if 'read1_fastq' not in record:
                raise ValueError('R1 FASTQ not found')
            if 'read2_fastq' not in record:
                raise ValueError('R2 FASTQ not found')
            writer.writerow(record)

if __name__ == '__main__':
    main()
