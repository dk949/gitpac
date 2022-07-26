module url;
import std.sumtype;
import utils;

enum DefaultUrl {
    None
}

enum UrlType {
    Git,
    Http,
    Ftp
}

struct Url {
    SumType!(DefaultUrl, string) url = DefaultUrl.None;

    mixin propGet!(UrlType, "type");

    alias url this;

    void opAssign(T)(T val)
    if (is(T == DefaultUrl) || is(T == string)) {
        url = val;
    }

    this(T)(T val)
    if (is(T == DefaultUrl) || is(T == string)) {
        url = val;
    }

    this(string val, UrlType type) {
        url = val;
        m_type = type;
    }

    @safe pure
    string toString() const {
        import std.conv;

        return m_type.to!string ~ "(" ~ url.toString ~ ")";
    }
}
