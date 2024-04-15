#!/bin/bash

if [ "!{sbatch_ret}" != "-1" ]
then
    if echo "!{sbatch_ret}" | grep -q "Submitted batch job"
    then
        job_id=$(echo "!{sbatch_ret}" | cut -d ' ' -f 4)
        while squeue --noheader --format="%i" | grep -q "$job_id"
        do
            sleep 3
        done

        if sacct -j "$job_id" -o ExitCode --noheader | tr -d " " | sort -r | head -n 1 | grep -q "^0:0$"
        then
            :
        else
            echo "Process in '!{work_dir}' failed with non-zero exit code."
        fi
    fi
fi

pipeline_failures=""

exit_code_regex="^(.+)\\.([0-9]+)"
for pipeline_exit_path in "!{work_dir}"/PIPELINEEXITSTATUS/*
do
    pipeline_exit_file=$(basename $pipeline_exit_path)
    if [[ $pipeline_exit_file =~ $exit_code_regex ]]
    then
        pipeline_name="${BASH_REMATCH[1]}"
        pipeline_exit_code="${BASH_REMATCH[2]}"
        if [ ! "$pipeline_exit_code" -eq 0 ]
        then
            pipeline_failures="$pipeline_name, $pipeline_failures"
        fi
    fi
done

if [ -n "$pipeline_failures" ]
then
    echo "Process in '!{work_dir}' had failures in the following pipelines: $pipeline_failures"
fi
