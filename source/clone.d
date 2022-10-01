module clone;
import config;
import args;
import utils;
import args.clonecmd;
import std.sumtype;
import url;
import downloader;

private void tryDownload(const ref Url url, const CloneCmd cmd, const UserConfig conf) {
    import std.stdio;

    if (url.type.isFull) {
        dwriteln("Info: downloading ", url);
        url.download(cmd.dir, conf);
    } else if (url.type == UrlType.NameOnly) {
        foreach (base; conf.baseUrl) {
            if (base != DefaultUrl.Github) {
               // TODO: try download
            }
        }

    } else if (url.type.isRemoteId) {
        unreachable("Url cannot be a remote ID at this point");
    } else {
        unreachable;
    }

    final switch (url.type) {
        case UrlType.GitHub:
        case UrlType.Git:
        case UrlType.Http:
        case UrlType.Ftp:
            break;
        case UrlType.NameOnly:
        case UrlType.OwnerName:
            break;
        case UrlType.RemoteGithub:
            unreachable;
    }

}

int clone(const CloneCmd cmd, const UserConfig conf) {
    import std.stdio;

    auto url = cmd.url;
    if (url.type.isRemoteId)
        exitWithError("expecting package name or url, got remote name instead");
    if (const found = Recipes.find(url)) {
        found.writeln;
    } else {
        dwriteln("Warning: Could not find recipe for ", url);
        url.tryDownload(cmd, conf);
    }

    return 0;
}
