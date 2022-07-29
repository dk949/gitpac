module config.recipetypes;

import url;
import std.sumtype;

struct Remote{
    Url[] urls;
    alias urls this;
}

struct Deps {
    string[] build;
    string[] runtime;
}
