module config.recipetypes;

import url;
import std.sumtype;

alias Remote = Url[];

struct Deps {
    string[] build;
    string[] runtime;
}
