module args;

abstract class Subcommand {
}

struct Args {

    import std.getopt: Option;

    @noreturn
    private noreturn help(Option[] options = null, string msg = null) {
        import args.utils: genericHelp;

        genericHelp("Usage:
    gitpac clone URL
    gitpac fetch ALIAS|DIR
    gitpac pull ALIAS|DIR
    gitpac switch ALIAS|DIR BRANCH|TAG|HASH|REVISION_ALIAS
    gitpac config ALIAS|DIR
    gitpac make ALIAS|DIR
    gitpac install ALIAS|DIR

To get help for a specific subcommand use:
    gitpac SUBCMD --help (e.g. gitpac clone --help)
", options, msg);
    }

    @noreturn
    private noreturn version_() {
        import core.stdc.stdlib: exit;
        import std.stdio: writeln;
        import version_: get;

        writeln(get);
        exit(0);
    }

    import utils: propGet;

    mixin propGet!(Subcommand, "subcommand");

    this(string[] input) {
        assert(input.length > 0, "expecting first argunment to be the name of the application");

        if (input.length <= 1)
            help(null, "Expected a sub command");

        import std.functional: toDelegate;
        import std.algorithm: remove;
        import args.clonecmd: CloneCmd;

        // Each subcommand is handled by a dedicated handler
        switch (input[1]) {
            case "add":
            case "clone":
                input = input.remove(1);
                m_subcommand = new CloneCmd(input);
                break;
            case "fetch":
            case "pull":
            case "switch":
            case "config":
            case "make":
            case "install":
                import std.stdio: writeln;

                writeln(input[1], " not implemented");
                input = input.remove(1);
                break;
            default:
                break;
        }

        import std.getopt;

        // Remaining arguments are habndled as global flags
        bool ver;

        import utils;

        auto res = tryOrElse!(GetOptException)(getopt(
                input,
                config.passThrough,
                "v|version", "Print version.", &ver,
        ), (GetOptException e) => help(null, e.message.idup));

        if (res.helpWanted) {
            help(res.options);
        }
        if (ver) {
            version_();
        }

        import std.array: join;
        import std.range: drop;

        if (input.length != 1)
            help(res.options, "Unexpected arguments: " ~ input.drop(1).join(", "));
    }
}
