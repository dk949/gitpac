module args.utils;

import std.getopt;

auto getpos(size_t N)(ref string[] args) {
    import std.range, std.algorithm;
    import std.typecons: tuple;

    string[N] pos;
    size_t[] rmList;
    size_t idx;
    bool sep;
    foreach (i, arg; args.drop(1)) {
        if (arg == "--") {
            sep = true;
            continue;
        }
        if (!sep && arg.startsWith("-"))
            continue;
        if (idx >= N)
            break;
        pos[idx++] = arg;
        rmList ~= i + 1;
    }
    return tuple(pos, rmList);
}

@noreturn
noreturn genericHelp(string pre, Option[] options = null, string msg = null) {
    import core.stdc.stdlib: exit;
    import std.stdio;

    if (msg)
        stderr.writeln(msg, '\n');

    auto o = (msg ? stderr : stdout);
    o.writeln(pre);
    foreach (option; options) {
        if (option.optShort)
            o.writefln("%s|%-12s  %s", option.optShort, option.optLong, option.help);
        else
            o.writefln("   %-12s  %s", option.optLong, option.help);
    }

    exit(msg ? 1 : 0);
}
