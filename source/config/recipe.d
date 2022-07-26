module config.recipe;
import dyaml;
import config.baseconfig;
import config.utils;
import url;

public import config.recipetypes;

class Recipe : BaseConfig {
    import std.traits;
    import std.stdio;

    Remote remote;
    string[] build;
    string[] clean;
    string[] install;
    Deps deps;
    string[] diff;

    mixin makeFromYaml!Recipe;

    static Recipe load(F)(auto ref F file)
    if (isSomeString!F || is(F == File))
    in (imported!"std.file".exists(file)) {

        auto rec = new Recipe();
        immutable yaml = loadYaml(file);
        if (yaml.type == NodeType.invalid)
            return rec;

        rec.fromYaml(yaml);
        return rec;
    }
}

struct Recipes {
    Recipe[] m_recipes;

    alias m_recipes this;

    static Recipes load() {
        import config.configdir;
        import std.array;
        import std.stdio;
        import std.file;
        import std.path;

        immutable recipeDir = configDir.chainPath(defaultRecipeDir).array;

        if (!exists(recipeDir))
            return Recipes();

        auto a = appender!(Recipe[]);

        foreach (ent; dirEntries(recipeDir, "*.yaml", SpanMode.shallow))
            a.put(Recipe.load(ent.name));

        return Recipes(a.data);
    }
}
