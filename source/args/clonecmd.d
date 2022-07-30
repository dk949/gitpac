module args.clonecmd;

import args.utils;
import args;
import std.getopt;
import std.sumtype;
import url;
import utils;

class CloneCmd : Subcommand {

    struct Store {
    }

    alias Dir = SumType!(Store, string);

    mixin propGet!(bool, "noRecurse");
    mixin propGet!(Url, "url");
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
        import std.file;
        import std.algorithm;

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

        foreach_reverse (size_t rm; pos[1]) {
            args = args.remove(rm);
        }
    }
}
