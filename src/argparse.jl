function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--test"
            help = "run file test procedure (2 procs, 3 iters)"
            action = :store_true
        "--addprocs"
            help = "another option with an argument"
            arg_type = Int
            default = 19
        "--iter"
            arg_type = Int
            default = 100
    end

    parsed_args = parse_args(s)
    if parsed_args["test"]
        parsed_args["addprocs"] = 2
        parsed_args["iter"] = 3
    end
    return parsed_args
end
