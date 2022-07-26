module args.clonecmd;

import args.utils: getpos, genericHelp;
import args;
import utils: propGet, monadof, tryOrElse;
import std.getopt;

class CloneCmd : Subcommand {
    import std.sumtype;

    struct Store {
    }

    alias Dir = SumType!(Store, string);

    mixin propGet!(bool, "noRecurse");
    mixin propGet!(string, "url");
    mixin propGet!(string, "alias_");
    mixin propGet!(Dir, "dir");

    @noreturn
    private noreturn help(Option[] options, string msg = null) {

        genericHelp(
            "clone URl [-s|--store|DIR] [-a|alias ALIAS] [--no-recurse]
    downlaod contents of the repository pointed to by the URL.

By default:
    Alias is derived from the repository URL
    Location is the current working directory
    All submodules will be downloaded recursively.
", options, msg);
    }

    this(ref string[] args) {

        bool store;

        auto res = tryOrElse!(GetOptException)(getopt(
                args,
                config.passThrough,
                config.keepEndOfOptions,
                "no-recurse", "Do not recurse submodules.", &m_noRecurse,
                "s|store", "Clone repository into storage, not CWD.", &store,
                "a|alias", "Alias this package will be referred by.", &m_alias_
        ), (GetOptException e) => help(null, e.message.idup));

        if (res.helpWanted) {
            help(res.options);
        }

        import std.file: getcwd;

        auto pos = getpos!2(args);
        if (!pos[0][0])
            help(res.options, "clone requires a URL");
        else
            m_url = pos[0][0];

        if (pos[0][1]) {
            if (store)
                help(res.options, "Cannot specify both --store and directory for clone");
            else
                m_dir = pos[0][1];
        } else {
            if (store)
                m_dir = Store();
            else
                m_dir = getcwd();
        }
        import std.algorithm: remove;
        import std.range;

        foreach_reverse (size_t rm; pos[1]) {
            args = args.remove(rm);
        }
    }
}
