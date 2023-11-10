import org.yaml.snakeyaml.Yaml

/**
*   Function to take a set of parameters and combine with existing params from YAML if YAML is provided
*   Returns string representing combined params
*/
String combine_input_with_params(Map params_to_add,  File input_yaml = null) {
    Yaml yaml = new Yaml()
    def loaded_input = (input_yaml) ? yaml.load(input_yaml) : [:]

    String combined_yaml = yaml.dump(loaded_input + params_to_add)

    return combined_yaml
}

String identify_file(filepath) {
    def file_found = file(filepath);

    if (file_found in List) {
        assert file_found.size() == 1
        file_found = file_found[0]
    }

    assert file_found.exists();
    return file_found.toRealPath().toString()
}

void delete_file(String filepath, String output_filepattern) {
    File expected_file = new File(filepath);
    Integer expected_bytes = expected_file.length();

    String output_filepath = '';

    // Wait and find the output file
    Boolean keep_looking = true;
    while (keep_looking) {
        try {
            output_filepath = identify_file(output_filepattern);
            keep_looking = false;
        } catch (AssertionError e) {
            if (e.toString().replace(' ', '').contains('[]0')) {
                sleep(5000); // Sleep 5 seconds then try to find output file again
            } else {
                keep_looking = false;
                System.out.println("Failed to find final output file: ${output_filepattern}, not deleting ${filepath}.");
                return;
            }
        }
    }

    File output_file = new File(output_filepath);
    Integer output_bytes = output_file.length();
    while (output_bytes != expected_bytes) {
        sleep(5000);
    }

    expected_file.delete()
}
