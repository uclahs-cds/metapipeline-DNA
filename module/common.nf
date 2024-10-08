import org.yaml.snakeyaml.Yaml

/**
*   Function to take a set of parameters and combine with existing params from YAML if YAML is provided
*   Returns string representing combined params
*/
String combine_input_with_params(Map params_to_add,  File input_yaml = null) {
    Yaml yaml = new Yaml();
    def loaded_input = (input_yaml) ? yaml.load(input_yaml) : [:];

    String combined_yaml = yaml.dump(loaded_input + params_to_add);

    return combined_yaml;
}

/**
*   Generate command line arguments for a child Nextflow run to use the same weblog
*/
String generate_weblog_args() {
    if (getSession().config.navigate('weblog.enabled') as Boolean) {
        return "-with-weblog ${getSession().config.navigate('weblog.url')}";
    }
    return "";
}

String identify_file(filepath) {
    def file_found = file(filepath);

    if (file_found in List) {
        assert file_found.size() == 1 : "Failed to identify a single file for `${filepath}`: `${file_found}`";
        file_found = file_found[0];
    }

    assert file_found.exists() : "Identified file `${file_found}` does not exist!";
    return file_found.toRealPath().toString();
}

/**
*   Generate commands to control graceful failure of downstream pipelines
*/
String generate_graceful_error_controller(Map ext) {
    String disable = 'export DISABLE_FAIL=""';
    String enable = 'export ENABLE_FAIL=""';
    String capture = 'capture_exit_code () { export EXIT_CODE=$?; }';

    if (ext && ext.containsKey('fail_gracefully') && ext.fail_gracefully) {
        disable = 'export DISABLE_FAIL="set +e"';
        enable = 'export ENABLE_FAIL="set -e"';
    }

    return "${disable} && ${enable} && ${capture}";
}

/**
*   Function to delete a file once it has been copied over to a final destination
*/
void delete_file(String filepath, output_filepattern) {
    File expected_file = new File(filepath);
    Integer expected_bytes = expected_file.length(); // The size of the file in bytes

    String output_filepath = '';

    // Wait and find the output file
    Boolean keep_looking = true;
    while (keep_looking) {
        try {
            // Try to access the final output file
            output_filepath = identify_file(output_filepattern);
            System.out.println("Found: ${output_filepath}");
            keep_looking = false;
        } catch (AssertionError e) {
            if (e.toString().replace(' ', '').contains('[]0')) {
                // Output file not found (empty list of identified files) so wait and retry
                sleep(5000);
            } else {
                // Error with output file existence, skip deletion
                keep_looking = false;
                System.out.println("Failed to find final output file: ${output_filepattern}, not deleting ${filepath}.");
                return;
            }
        }
    }

    File output_file = new File(output_filepath);
    Integer output_bytes = output_file.length();

    // Wait until final output file matches size in bytes with original file then delete original
    while (output_bytes != expected_bytes) {
        sleep(5000);
        output_bytes = output_file.length();
    }

    expected_file.delete();
}
