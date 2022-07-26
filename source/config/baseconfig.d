module config.baseconfig;

import dyaml;
import config.utils;
import std.traits;

class BaseConfig {
    protected void fromYamlImpl(This)(auto ref inout(Node) node)
    if (is(This : BaseConfig)) {
        static foreach (field; FieldNameTuple!This)
            if (field in node)
                __traits(getMember, cast(This) this, field)
                    = node[field].tryAs!(typeof(__traits(getMember, cast(This) this, field)));
    }

    abstract void fromYaml(ref Node node);
    abstract void fromYaml(Node node);

    // Derived classes must implement static functino load.
    static BaseConfig load() @disable;
}

mixin template makeFromYaml(This) {
    override void fromYaml(Node node) {
        fromYaml(node);
    }

    override void fromYaml(ref Node node) {
        fromYamlImpl!This(node);
    }
}
