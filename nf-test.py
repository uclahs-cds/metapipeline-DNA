""" Test NF-pipelines """
from __future__ import annotations
import argparse
import glob
import hashlib
from pathlib import Path
import subprocess as sp
import shutil
import os
from typing import List
import yaml


def parse_args() -> argparse.Namespace:
    """ Parse args """
    parser = argparse.ArgumentParser(
        prog='nf-test'
    )
    parser.add_argument(
        'CONFIG',
        type=Path,
        help='Path the the nextflow test config YAML file. If not given, it'
        'looks for nf-test.yaml or nf-test.yml',
        default=None,
        nargs='?'
    )
    return parser.parse_args()

def find_config_yaml(args:argparse.Namespace):
    """ Find the test config yaml """
    if args.CONFIG is None:
        if Path('./nf-test.yaml').exists():
            args.CONFIG = Path('./nf-test.yaml')
        elif Path('./nf-test.yml').exists():
            args.CONFIG = Path('./nf-test.yml')

def validate_yaml(path:Path):
    """ Validate the yaml. Potentially use yaml schema
    https://rx.codesimply.com/ """
    return True

def remove_nextflow_logs() -> None:
    """ """
    files = glob.glob('./.nextflow*')
    for file in files:
        if Path(file).is_dir():
            shutil.rmtree(file)
        else:
            os.remove(file)

def calculate_checksum(path:Path) -> str:
    """ Calculate checksum recursively.
    Args:
        path (Path): The path to the directory.
        stdout (bool): If true, the result is printed to stdout.
    """
    sum_val = hashlib.md5()
    with open(path, "rb") as handle:
        for byte_block in iter(lambda: handle.read(4096), b""):
            sum_val.update(byte_block)
    sum_val = sum_val.hexdigest()
    return sum_val

class NFTestAssert():
    def __init__(self, received:str, expected:str):
        """"""
        self.received = received
        self.expected = expected

    def assertExpected(self):
        """ """
        received_hash = calculate_checksum(self.received)
        expected_hash = calculate_checksum(self.expected)
        assert received_hash == expected_hash

class NFTestCase():
    def __init__(self, name:str=None, message:str=None, nf_script:str=None,
            nf_configs:List[str]=None, asserts:List[NFTestAssert]=None,
            temp_dir:str=None, remove_temp:bool=None, clean_logs:bool=True):
        """"""
        self.name = name
        self.message = message
        self.nf_script = nf_script
        self.nf_configs = nf_configs or []
        self.asserts = asserts or []
        self.temp_dir = temp_dir
        self.remove_temp = remove_temp
        self.clean_logs = clean_logs

    def test(self):
        self.submit()
        for ass in self.asserts:
            ass.assertExpected()
        if self.remove_temp:
            shutil.rmtree(self.temp_dir)
        if self.clean_logs:
            remove_nextflow_logs()

    def submit(self):
        config_arg = ''
        for nf_config in self.nf_configs:
            config_arg += f'-c {nf_config} '
        cmd = f"""
        NXF_WORK={self.temp_dir} \
        nextflow run \
            {self.nf_script} \
            {config_arg}
        """
        print(' '.join(cmd.split()), flush=True)
        sp.run(cmd, shell=True, check=True)

    def combine_global(self, _global:NFTestGlobal) -> None:
        """ """
        if _global.nf_config:
            self.nf_configs.insert(0, _global.nf_config)

        if self.remove_temp is None:
            if _global.remove_temp:
                self.remove_temp = _global.remove_temp
            else:
                self.remove_temp = False

        if not self.temp_dir:
            self.temp_dir = _global.temp_dir

        if not self.clean_logs:
            self.clean_logs = _global.clean_logs


class NFTestGlobal():
    def __init__(self, temp_dir:str, nf_config:str, remove_temp:bool,
            clean_logs:bool=True):
        """ """
        self.temp_dir = temp_dir
        self.nf_config = nf_config
        self.remove_temp = remove_temp
        self.clean_logs = clean_logs

class NFTestRunner():
    def __init__(self, _global:NFTestGlobal=None, cases:List[NFTestCase]=None):
        """ Constructor """
        self._global = _global
        self.cases = cases or []

    def load_from_config(self, config_yaml:str):
        """ """
        validate_yaml(config_yaml)
        with open(config_yaml, 'rt') as handle:
            config = yaml.safe_load(handle)
            self._global = NFTestGlobal(**config['global'])
            for case in config['cases']:
                if 'asserts' in case:
                    asserts = [NFTestAssert(**ass) for ass in case['asserts']]
                else:
                    asserts = []
                case['asserts'] = asserts
                case['nf_configs'] = [case['nf_config']]
                del case['nf_config']
                test_case = NFTestCase(**case)
                test_case.combine_global(self._global)
                self.cases.append(test_case)

    def main(self):
        """ """
        for case in self.cases:
            case.test()


def main():
    args = parse_args()
    find_config_yaml(args)
    runner = NFTestRunner()
    runner.load_from_config(args.CONFIG)
    runner.main()


if __name__ == '__main__':
    main()
