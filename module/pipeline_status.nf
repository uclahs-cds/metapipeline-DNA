def create_status_directory() {
    new File(params.pipeline_status_directory).mkdirs()
}

def mark_pipeline_complete(String pipeline) {
    new File("${params.pipeline_status_directory}/${pipeline}.complete").createNewFile()
}
