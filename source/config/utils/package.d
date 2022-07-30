module config.utils;
import dyaml;
import std.file;
import std.traits;
import utils;

public import config.utils.tryas;

Node loadYaml(F)(auto ref F file)
if (isFileLike!F)
in (exists(file)) {
    auto loader = Loader.fromFile(file);
    if (loader.empty)
        return Node.init;

    return tryOrElse!YAMLException(
        loader
            .load(),
            (YAMLException e) => exitWithError(e.message)
    );
}
