module config.recipe;

import config.baseconfig;
import config.utils;
import dyaml;
import url;
import utils;
import std.traits;

public import config.recipetypes;

class Recipe : BaseConfig {
    import std.stdio;

    string name;
    Remote remote;
    string[] build;
    string[] clean;
    string[] install;
    Deps deps;
    string[string] env;
    string[] diff;

    mixin makeFromYaml!Recipe;

    static Recipe load(F)(auto ref F file)
    if (isFileLike!F)
    in (imported!"std.file".exists(file)) {

        auto rec = new Recipe();
        immutable yaml = loadYaml(file);
        if (yaml.type == NodeType.invalid)
            return rec;

        import std.range, std.algorithm, std.path;

        rec.name = yaml.startMark.name.baseName.stripExtension;
        rec.fromYaml(yaml);
        return rec;
    }

    override string toString() const {
        import std.array, std.conv;

        auto a = appender!string;
        a.reserve(this.sizeof * 4); // probably better than nothing, but not remotely perfect
        a.put("{\n");
        static foreach (field; FieldNameTuple!Recipe) {
            a.put("\t");
            a.put(field);
            a.put(": ");
            a.put(__traits(getMember, this, field).to!string);
            a.put(", \n");
        }
        a.put("}");
        return a.data;
    }
}

struct Recipes {
    Recipe[] recipes;

    alias recipes this;
    private static const string recipeDir;
    static this() {
        import config.configdir;
        import std.path;
        import std.array;

        recipeDir = configDir.chainPath(defaultRecipeDir).array;
    }

    static Recipes load() {
        import std.array;

        import std.file;
        import std.path;

        if (!exists(recipeDir))
            return Recipes();

        auto a = appender!(Recipe[]);

        foreach (const ref ent; dirEntries(recipeDir, "*.yaml", SpanMode.shallow))
            a.put(Recipe.load(ent.name));

        return Recipes(a.data);
    }

    static Recipe findByFileName(
        alias fn = (string a, string b) => a == b,
        F
    )(
        auto ref F file,
        bool* single = null
    )
    if (isFileLike!F) {
        import std.file, std.path, std.algorithm, std.range, std.array;

        auto entries = dirEntries(recipeDir, "*.yaml", SpanMode.shallow);
        auto found = entries
            .map!(l => l.name.baseName)
            .find!fn(file)
            .array;
        if (found.empty)
            return null;
        if (single)
            *single = found.length == 1;
        return Recipe.load(found.front.absolutePath(recipeDir));
    }

    static Recipe findByRecipeName(S)(Recipe[] recs, auto ref S file)
    if (isSomeString!S) {
        import std.algorithm, std.range;

        auto found = recs.find!`a.name == b`(file);
        if (found.empty)
            return null;
        return found.front;
    }

    static Recipe find(Url url) {
        import std.file;

        if (!exists(recipeDir))
            return null;

        if (immutable ownerName = url.ownerName) {
            import std.array, std.algorithm, utils;

            auto s = ownerName.split('/');
            immutable owner = s[0];
            immutable name = s[1];

            if (auto found = findByFileName(owner ~ "%" ~ name ~ ".yaml"))
                return found;

            if (auto found = findByFileName(name ~ ".yaml"))
                return found;

            auto recs = Recipes.load();

            if (auto found = findByRecipeName(recs, ownerName))
                return found;

            if (auto found = findByRecipeName(recs, name))
                return found;

            return null;

        } else {
            immutable name = url.nameOnly;

            if (auto found = findByFileName(name ~ ".yaml"))
                return found;

            import std.array;

            bool single;
            if (auto found = findByFileName!((string a, string b) {
                    auto s = a.split('%');
                    return s.length > 1 ? s[1] == b : false;
                })(name, &single)) {
                if (single) {
                    debug {
                        import std.stdio;

                        writeln("[DEBUG] Warning: owner not specified,",
                            " found 1 package with specified owner and matching name");
                    } else {
                        assert(false, "not implemented for release");
                    }
                    if (name == found.name) {
                        debug {
                            import std.stdio;

                            writeln("\tname specified in recipe matches fully.");
                        } else {
                            assert(false, "not implemented for release");
                        }
                        return found;
                    } else {
                        debug {
                            import std.stdio;

                            writeln("[DEBUG] Prompt: Use package `", found.name, "`? (y/N)");
                            return found;
                        } else {
                            assert(false, "not implemented for release");
                        }
                    }
                } else {
                    debug {
                        import std.stdio;

                        writeln("[DEBUG] Prompt: package available from different owners");
                        assert(false, "not implemented");
                    } else {
                        assert(false, "not implemented for release");
                    }
                }
            }

            auto recs = Recipes.load();

            if (auto found = findByRecipeName(recs, name))
                return found;

            return null;
        }
    }

}

private void mapRecipes(alias fn)(auto ref inout(string) dir) {
    import std.file;

    foreach (const ref ent; dirEntries(dir, "*.yaml", SpanMode.shallow))
        fn(ent);
}
