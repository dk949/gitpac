module config.utils.tryas;

import dyaml;
import std.conv;
import std.exception;
import std.traits;
import utils;

class TryAsException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

string tryAs(T : string)(Node n) {

    if (n.type == NodeType.binary) {
        import std.string;
        import std.utf;

        auto ret = n
            .as!(ubyte[])
            .assumeUTF();
        tryOrElse!UTFException(ret.validate, (UTFException e) => exitWithError(
                "Could not convert base64 to UTF", e.message));
        return ret.idup;
    }
    enforce!TryAsException(
        // Note: YAML always infers the type of a field from a literal, so even
        //  if the user intended for a literal to be a string literal it may get
        //  parsed as one of the following by accident.
        n.type == NodeType.string
            || n.type == NodeType.null_
            || n.type == NodeType.boolean
            || n.type == NodeType.integer
            || n.type == NodeType.decimal
            || n.type == NodeType.timestamp,
            n.type.text ~ " is not convertible to a string"
    );
    return n.as!string;
}

bool tryAs(T : bool)(Node n) {
    enforce!TryAsException(
        n.type == NodeType.boolean,
        n.type.text ~ " is not a boolean"
    );
    return n.as!bool;
}

T tryAs(T)(Node n)
if (isIntegral!T) {
    enforce!TryAsException(
        n.type == NodeType.integer,
        n.type.text ~ " is not an integer"
    );
    return n.as!T;
}

T tryAs(T)(Node n)
if (isFloatingPoint!T) {
    enforce!TryAsException(
        n.type == NodeType.decimal,
        n.type.text ~ " is not a decimal"
    );
    return n.as!T;
}

T tryAs(T)(Node n)
if (isArray!T) {
    enforce!TryAsException(n.type == NodeType.sequence, n.type.text ~ " is not a sequence");
    import std.range;

    alias Elem = typeof(declval!T.front);
    auto a = appender!T;

    foreach (Node node; n) {
        a.put(node.tryAs!Elem);
    }

    return a.data;
}

T tryAs(T)(Node n)
if (isAssociativeArray!T) {
    import std.range;

    enforce!TryAsException(n.type == NodeType.mapping, n.type.text ~ " is not a mapping");
    alias Key = typeof(declval!T.keys.front);
    alias Value = typeof(declval!T.values.front);
    Key[Value] output;
    foreach (Node key, Node value; n) {
        output[key.tryAs!Key] = value.tryAs!Value;
    }
    return output;
}

import config.recipetypes;

Deps tryAs(T : Deps)(Node n) {
    enforce!TryAsException(
        n.type == NodeType.mapping,
        n.type.text ~ " is not a mapping of dependencies"
    );
    auto deps = Deps();
    foreach (string key, Node value; n) {
        switch (key) {
            case "build":
                deps.build = tryAs!(string[])(value);
                break;
            case "runtime":
                deps.runtime = tryAs!(string[])(value);
                break;
            default:
                exitWithError("unexpected key in dependencies mapping");

        }
    }
    return deps;
}

import url;

/*
remote: https://url.com
remote:
    http: https://url.com/download
    git : https://git.url.com/
    ftp : ftp://ftp.url.com/
 */
Remote tryAs(T : Remote)(Node n) {
    if (n.type == NodeType.null_)
        return Remote([Url(DefaultUrl.None)]);

    if (n.type == NodeType.mapping) {
        import std.array;

        auto a = appender!(Url[]);
        foreach (string t, Node node; n) {
            enforce!TryAsException(
                node.type == NodeType.string,
                "Typed URL has to be a string"
            );
            switch (t) {
                case "git":
                    a.put(Url(node.as!string, UrlType.Git));
                    break;
                case "http":
                    a.put(Url(node.as!string, UrlType.Http));
                    break;
                case "ftp":
                    a.put(Url(node.as!string, UrlType.Ftp));
                    break;
                default:
                    exitWithError("Unknown url type `", t, "`. Tyr one of `git`, `http` or `ftp`");
            }
        }
        return Remote(a.data);
    }

    enforce!TryAsException(
        n.type == NodeType.string,
        n.type.text ~ " is not a string or null"
    );
    return Remote([Url(n.as!string)]);
}

Url tryAs(T : Url)(Node n) {
    enforce!TryAsException(n.type == NodeType.string, n.type.text ~ " is not a string");
    return Url(n.as!string);
}
