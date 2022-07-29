module config.baseconfig;

import dyaml;
import config.utils;
import std.traits;

class BaseConfig {
    protected void fromYamlImpl(This)(Node node)
    if (is(This : BaseConfig)) {
        //Note: node is copied, because this function will remove elements from it
        static foreach (field; FieldNameTuple!This)
            if (field in node) {
                __traits(getMember, cast(This) this, field)
                    = node[field].tryAs!(typeof(__traits(getMember, cast(This) this, field)));
                node.removeAt(field);
            }
        import std.range;

        import std.stdio;

        if (!node.empty) {
            debug {
                import std.stdio;

                stderr.writeln("[DEBUG] Warning: Found unknown keys in ", node.startMark.name, ":");
                foreach (key; node.mappingKeys!string) {
                    stderr.writeln("\t", key);
                }
            } else {
                static assert(0, "Figure out how to handle warnings");
            }
        }
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
