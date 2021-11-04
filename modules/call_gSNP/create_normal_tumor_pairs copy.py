""" Create paired input csv for call-gSNP """
import argparse
import csv
from pathlib import Path


def parse_args():
    """ parse args """
    parser = argparse.ArgumentParser()
    parser.add_argument('INPUT', type=Path)
    parser.add_argument('OUTPUT', type=Path)
    parser.add_argument(
        '--state-field', type=str, default='state',
        help='The column name for state'
    )
    parser.add_argument(
        '--state-normal', type=str, default='normal',
        help='The level to indicate normal state'
    )
    parser.add_argument(
        '--state-tumor', type=str, default='tumor',
        help='The level to indicate tumor state'
    )
    return parser.parse_args()

def main():
    """ main """
    args = parse_args()
    normals = []
    tumors = []
    with open(args.INPUT, 'rt') as handle:
        reader = csv.DictReader(handle)
        for line in reader:
            if line[args.state_field] == args.state_normal:
                normals.append(line)
            elif line[args.state_field] == args.state_tumor:
                tumors.append(line)
            else:
                raise ValueError('Can not interprate the state field')
    if len(normals) > 1:
        raise ValueError('Multiple normal sample found')
    normal = normals[0]
    with open(args.OUTPUT, 'w') as handle:
        fieldnames = [
            'patient',
            'tumor_sample', 'normal_sample',
            'tumor_site',   'normal_site',
            'tumor_bam_sm', 'normal_bam_sm',
            'tumor_bam',    'normal_bam'
        ]
        writer = csv.DictWriter(handle, fieldnames)
        writer.writeheader()
        for tumor in tumors:
            pair = {
                fieldnames[0]: tumor['patient'],
                fieldnames[1]: tumor['sample'],
                fieldnames[2]: normal['sample'],
                fieldnames[3]: tumor['site'],
                fieldnames[4]: normal['site'],
                fieldnames[5]: tumor['bam_header_sm'],
                fieldnames[6]: normal['bam_header_sm'],
                fieldnames[7]: tumor['bam'],
                fieldnames[8]: normal['bam']
            }
            writer.writerow(pair)

if __name__ == '__main__':
    main()
