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
    new File("${params.pipeline_status_directory}/${pipeline}.complete").createNewFile()
}

/*
*   Delete a completion file for testing purposes
*   @input pipeline String Name of pipeline to delete completion status
*/
def delete_completion_file(String pipeline) {
    new File("${params.pipeline_status_directory}/${pipeline}.complete").delete()
}
