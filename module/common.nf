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
