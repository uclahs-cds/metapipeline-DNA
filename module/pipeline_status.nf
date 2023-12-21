/*
*   Create directory for tracking pipeline status
*/
def create_status_directory() {
    new File(params.pipeline_status_directory).mkdirs()
}

/*
*   Mark a pipeline as complete in directory
*   @input pipeline String Name of pipeline to mark as complete
*/
def mark_pipeline_complete(String pipeline) {
    new File("${params.pipeline_status_directory}/${pipeline}.complete").createNewFile()
}

/*
*   Delete a completion file for testing purposes
*   @input pipeline String Name of pipeline to delete completion status
*/
def delete_completion_file(String pipeline) {
    new File("${params.pipeline_status_directory}/${pipeline}.complete").delete()
}
