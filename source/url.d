module url;
import std.sumtype;
import utils;

class UrlException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

enum DefaultUrl : string {
    None = null,
    Github = "https://github.com"
}

private enum Full = 0b0001_0000;
private enum GitRemoteId = 0b1000_0000;

// dfmt off
enum UrlType {
    Git       = 0b_0001_0001,
    GitHub, // Using git protocol, but with support for github API
    Http,
    Ftp,

    NameOnly  = 0b_0010_0000,

    OwnerName = 0b_0100_0000,

    // Possibly support other remotes (gitlab?)
    RemoteGithub    = 0b_1000_0001,
}
// dfmt on

bool isFull(UrlType t) {
    return (t & Full) != 0;
}

bool isRemoteId(UrlType t) {
    return (t & GitRemoteId) != 0;
}

private bool isUrl(string str) {
    import std.uri;

    if (str.length < 4 || str[0 .. 4] != "http")
        return uriLength("https://" ~ str) > 0;
    else
        return uriLength(str) > 0;

}

struct Url {
    import std.regex;

    SumType!(DefaultUrl, string) url = DefaultUrl.None;

    mixin propGet!(UrlType, "type");

    alias url this;

    void opAssign(T)(T val)
    if (is(T == DefaultUrl) || is(T == string)) {
        url = val;
    }

    /**
     * Determines the type of the url from the string.
     *
     * For higher control over url type and value use the two argument ctor.
     *
     * Params:
     *   val = url to be decoded
     */
    this(string val) {
        if (val.matchFirst(githubRegex))
            this(DefaultUrl.Github, UrlType.RemoteGithub);

        else if (val.matchFirst(githubNameRegex))
            this(val, UrlType.NameOnly);

        else if (val.matchFirst(githubOwnerNameRegex))
            this(val, UrlType.OwnerName);

        else
            this(val, UrlType.Git);
    }

    this(DefaultUrl val) {
        final switch (val) {
            // Default behaviour if no URL is specified: value = none, type = git
            case DefaultUrl.None:
                url = val;
                m_type = UrlType.Git;
                break;
            case DefaultUrl.Github:
                url = DefaultUrl.Github;
                m_type = UrlType.RemoteGithub;
                break;
        }

    }

    this(string val, UrlType type) {
        import std.exception;
        import std.conv;

        if (type.isFull) {
            enforce!UrlException(val.isUrl,
                "Full url has to be a valid URL. "
                    ~ val
                    ~ " is invalid."
            );
        }
        url = val;
        m_type = type;
    }

    @safe pure
    string toString() const {
        import std.conv;

        return m_type.to!string ~ "(" ~ url.to!string ~ ")";
    }

    /**
     * Get owner/name part of teh URL if available.
     *
     * Only URLs of type OwnerName and Github can have an owner/name.
     *
     * Returns: string containing owner/name part of the url if available, null otherwise
     */
    string ownerName() const {
        final switch (m_type) {
            case UrlType.OwnerName:
                return url.get!string; // simple case
            case UrlType.Git:
            case UrlType.Http:
            case UrlType.Ftp:
            case UrlType.NameOnly:
                return null; // no owner available
            case UrlType.RemoteGithub:
                return exitWithError("cannot get owner and name of a remote id");
            case UrlType.GitHub:
                import std.range, std.algorithm;

                return url
                    .get!string
                    .findSplitAfter("github.com/")[1]
                    .findSplitBefore(".git")[0]
                    .stripRight('/');
        }
    }

    string nameOnly() const {
        import std.array;

        final switch (m_type) {
            case UrlType.NameOnly:
                return url.get!string; // simple case
            case UrlType.OwnerName:
                return url.get!string.split('/').back; // simple case
            case UrlType.GitHub:
            case UrlType.Git:
            case UrlType.Http:
            case UrlType.Ftp:
                import std.path;

                return url.get!string.baseName(".git");
            case UrlType.RemoteGithub:
                return exitWithError("cannot get owner and name of a remote id");
        }

    }

private:
    immutable static githubRegex = ctRegex!(`
            (?#either the url, or just the word github)

            (?:^
                (?:https?://)?
                    (?:www\.)?
                        github\.com/?
            $) |
            (?:^
                github
            $)

            `, "xi");
    unittest {
        assert("http://github.com".matchFirst(githubRegex), "http");
        assert("https://github.com".matchFirst(githubRegex), "https");
        assert("www.github.com".matchFirst(githubRegex), "www");
        assert("github.com".matchFirst(githubRegex), "nothing");

        assert("http://www.github.com".matchFirst(githubRegex), "http and www");
        assert("https://www.github.com".matchFirst(githubRegex), "https and www");

        assert("http://github.com/".matchFirst(githubRegex), "http with trailing slash");
        assert("https://github.com/".matchFirst(githubRegex), "https with trailing slash");
        assert("www.github.com/".matchFirst(githubRegex), "www with trailing slash");
        assert("github.com/".matchFirst(githubRegex), "nothing with trailing slash");

        assert("http://www.github.com/".matchFirst(githubRegex), "http and www with trailing slash");
        assert("https://www.github.com/".matchFirst(githubRegex), "https and www with trailing slash");

        assert("hTtp://github.com".matchFirst(githubRegex), "case insensitive in http");
        assert("wwW.github.com".matchFirst(githubRegex), "case insensitive in www");

        assert("http://www.Github.com".matchFirst(githubRegex), "case insensitive in name");
        assert("http://github.cOm/".matchFirst(githubRegex), "case insensitive in top level domain");

        assert("github".matchFirst(githubRegex), "just name");
        assert("GitHub".matchFirst(githubRegex), "case insensitive just name");

        assert(!"kfjhkasdjfhk".matchFirst(githubRegex), "not anything");
        assert(!"".matchFirst(githubRegex), "not empty");
        assert(!"https://github".matchFirst(githubRegex), "not partial");
    }

    // https://github.com/shinnn/github-username-regex
    immutable static githubNameRegex = ctRegex!(`
        ^
            [a-z\d]
            (?:
                [a-z\d] |
                - (?= [a-z\d] )
            ) {0,38}
        $
        `, "xi");
    unittest {

        // Valid
        assert("hello".matchFirst(githubNameRegex), "only alpha");
        assert("hello123".matchFirst(githubNameRegex), "only alphanum");
        assert("hello-123".matchFirst(githubNameRegex), "alphanum with hyphen");

        // Github username may only contain alphanumeric characters or hyphens.
        assert(!"hello-1.23".matchFirst(githubNameRegex), "non alphanum");

        // Github username cannot have multiple consecutive hyphens.
        assert(!"hello--123".matchFirst(githubNameRegex), "consecutive hyphens");

        // Github username cannot begin or end with a hyphen.
        assert(!"-hello123".matchFirst(githubNameRegex), "begin with hyphen");
        assert(!"hello123-".matchFirst(githubNameRegex), "end with hyphen");

        // Maximum is 39 characters.
        assert("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa".matchFirst(githubNameRegex), "max length");
        assert(!"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaA".matchFirst(githubNameRegex), "too long");

        // Min is 1
        assert(!"".matchFirst(githubNameRegex), "empty");
        assert("a".matchFirst(githubNameRegex), "one char");
    }

    // https://stackoverflow.com/a/59082561/17162018
    immutable static githubOwnerNameRegex = ctRegex!(`
    ^
        [a-z\d_.-]{1,100}/
        [a-z\d]
        (?:
            [a-z\d] |
            - (?= [a-z\d] )
        ){0,38}
    $
        `, "xi");

    immutable static githubRepoRegex = ctRegex!(`
            (?:^
                (?:https?://)? (?:www\.)?

                github\.com
                    / [a-z\d_.-]{1,100}
                    / [a-z\d](?: [a-z\d] | - (?= [a-z\d] ) ){0,38}

                    (?:\.git)?/?

            $)
            `, "xi");
}
