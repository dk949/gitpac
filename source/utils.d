module utils;

/**
 * Declares a private member variable `m_name` and a public memebr function
 * `name` returning it.
 *
 * If size of `T` is greater than size of size_t (i.e. it probably doesn't fit
 * into a register), a `ref const(T)` will be returned instead.
 *
 * Params:
 *   T = Type of property
 *   name = name of property
 */
mixin template propGet(alias T, string name) {

    mixin("private " ~ T.stringof ~ " m_" ~ name ~ ";");

    // dfmt off
    static if (T.sizeof <= size_t.sizeof)
        mixin("
            pure @safe @nogc nothrow
            const("~ T.stringof ~ ") " ~ name ~ "() const {
                return m_"
                ~ name ~ ";
            }
            ");
    else
        mixin("
            pure @safe @nogc nothrow
            ref const(" ~ T.stringof ~ ") " ~ name ~ "() const return {
                return m_"
                ~ name ~ ";
            }
            ");
    // dfmt on
}

// TODO: rewrite this in terms of Nullable
version (none) {
    ref typeof(imported!"std.range".front(declval!Range)) monadof(string func, Range, Rest...)(
        auto ref Range r, auto ref Rest rest)
    if (__traits(compiles, r is null)) {
        if (r is null)
            return null;
        else {
            static if (__traits(compiles, r.empty))
                if (r.empty)
                    return null;
            import std;

            mixin("return " ~ func ~ "(r, rest);");
        }
    }
}

/**
 * Get the value or the result of a delegate called with the exception the value
 * throws.
 *
 * Specify which exception shoudl be caulgh in the template parameter. All other
 * exceptions are unaffected.
 *
 * Params:
 *   t = lazy evaluated value which can throw
 *   o = delegate to be called if `t` throws
 * Returns: Either `t` if `t` does not throw, or the result of `o(e)` where `e` is
 * the caught exception.
 */
auto ref T tryOrElse(E, T, Fn)(lazy T t, auto ref Fn o) //if (is(typeof(o(declval!E)) : T))
{
    try
        return t;
    catch (E e)
        return o(e);
}

// This is a temporary solution.
@noreturn
noreturn exitWithError(Args...)(auto ref Args args)
if (!is(Args[0] : Exception)) {
    import std.stdio;
    import core.stdc.stdlib: exit;

    stderr.writeln(args);
    exit(1);
}

@noreturn
noreturn exitWithError(E : Exception, Args...)(E err, auto ref Args args) {
    import std.stdio;
    import core.stdc.stdlib: exit;

    stderr.writeln(args);
    throw err;
}

/// Works like C++ std::declval.
T declval(T)();

pure @safe
string dump(T)(auto ref T t) {
    import std.array;
    import std.traits;
    import std.conv;

    auto o = appender!string;
    o.put("{\n");
    foreach (f; FieldNameTuple!T) {
        o.put(f);
        o.put(": ");
        o.put(__traits(getMember, t, f).to!string);
        o.put(",\n");
    }
    o.put("\n}\n");
    return o.data;
}

auto constCastSwitch(choices...)(const Object obj) {
    import std.algorithm;

    return castSwitch!(choices)(cast(Object) obj);
}

template ident(T) {
    T delegate(T) ident = (T t) => t;
}

import std.sumtype;

ref auto get(T, S)(auto ref S from)
if (isSumType!(S)) {
    return from.tryMatch!(ident!T);
}

import std.traits, std.stdio;

/// Either a string or a file. Most interfaces either accept both or have overloads for both.
enum bool isFileLike(F) = isSomeString!F || isFileHandle!F;

debug {
    ref inout(T) dbg(string msg = "", T)(scope return ref inout(T) inp) {
        import std.stdio;

        stderr.writeln("[DEBUG] Debug: ", msg, ": ", inp);
        return inp;
    }

    inout(T) dbg(string msg = "", T)(inout(T) inp) {
        import std.stdio;

        stderr.writeln("[DEBUG] Debug: ", msg, ": ", inp);
        return inp;
    }

    void dbg(string msg = "")() {
        import std.stdio;

        stderr.writeln("[DEBUG] Debug: ", msg, ": ", inp);
    }
} else {
    ref inout(T) dbg(string msg = "", T)(return ref inout(T) inp) {
        return inp;
    }

    inout(T) dbg(string msg = "", T)(inout(T) inp) {
        return inp;
    }

    void dbg(string msg = "")() {
    }
}

debug {
    void dwriteln(Args...)(auto ref Args args) {
        import std.stdio;

        stderr.writeln("[DEBUG] ", args);
    }
} else {
    void dwriteln(Args...)(auto ref Args) {
        notImplemented("in release mode");
    }
}

void notImplemented(string msg = null) {
    assert(0, "Not implemented" ~ (msg ? " " ~ msg : ""));
}

void unreachable(string msg = null) {
    assert(0, "Unreachable" ~ (msg ? " " ~ msg : ""));
}
