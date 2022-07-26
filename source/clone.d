module clone;
import config;
import args;
import utils;
import args.clonecmd;

int clone(const CloneCmd cmd, const UserConfig conf) {
    import std.stdio;

    auto recs = Recipes.load();
    foreach(size_t i, rec; recs){
        writeln(i, ": ", rec.dump);
    }
    return 0;
}
