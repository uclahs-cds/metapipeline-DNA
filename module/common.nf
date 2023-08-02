import org.yaml.snakeyaml.Yaml

String combine_input_with_params(Map params_to_add,  File input_yaml = null) {
    Yaml yaml = new Yaml()
    def loaded_input = (input_yaml) ? yaml.load(input_yaml) : [:]

    String combined_yaml = yaml.dump(loaded_input + params_to_add)

    return combined_yaml
}
