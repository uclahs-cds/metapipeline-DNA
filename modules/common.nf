/*
    Module for common groovy functions.
*/

/*
    Generate command line args. Argument from `arg_list` will be added to the returned value if it
    is specified in the `par`

    input:
        par: Can be either a config object or a groovy map.
        arg_list: A list of values.

    output:
        A string of command line args.
*/
def generate_args(par, arg_list) {
    def args = ''
    for (it in arg_list) {
        if (par.containsKey(it)) {
            args += " --${it} ${par[it]}"
        }
    }
    return args
}
