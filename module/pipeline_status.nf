/*
*   Create the given directory and any necessary parent directories
*/
def create_directory(String directory_to_create) {
    new File(directory_to_create).mkdirs()
}

/*
*   Mark a pipeline as complete in directory
*   @input pipeline String Name of pipeline to mark as complete
*/
def mark_pipeline_complete(String pipeline) {
    params.pipeline_predecessor.each{ p, dependencies ->
        dependencies.removeAll{ it == pipeline };
        if (dependencies.isEmpty()) {
            File pipeline_ready_file = new File("${params.pipeline_status_directory}/${p}.ready")
            pipeline_ready_file.delete()
            pipeline_ready_file.createNewFile()
        }
    }
}

/*
*   Delete a completion file for testing purposes
*   @input pipeline String Name of pipeline to delete completion status
*/
def delete_completion_file(String pipeline) {
    new File("${params.pipeline_status_directory}/${pipeline}.ready").delete()
}

/*
*   Create a file to record the exit code of a pipeline
*   @input pipeline String Name of pipeline to mark as complete
*   @input exit_code Integer Exit code of pipeline
*/
def mark_pipeline_exit_code(String pipeline, Integer exit_code) {
    new File("${params.pipeline_exit_status_directory}/${pipeline}.${exit_code}").createNewFile()
}
