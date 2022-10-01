module downloader;
import url;
import utils;
import args.clonecmd;
import std.sumtype;
import config;

void downloadGit(string remote, string dest) {
    notImplemented;
}

void downloadGitHub(string remote, string dest) {

    notImplemented;
}

void downloadFtp(string remote, string dest) {
    notImplemented;

}

void downloadHttp(string remote, string dest) {
    notImplemented;
}

void download(const ref Url url, CloneCmd.Dir dir, const UserConfig conf) {
    string remote = url.get!string;
    string dest = dir.match!(
        (CloneCmd.Store _) => conf.storeDir,
        ident!string
    );

    void function(string, string) dl;

    final switch (url.type) {
        case UrlType.GitHub:
            dl = &downloadGitHub;
            break;
        case UrlType.Git:
            dl = &downloadGit;
            break;
        case UrlType.Ftp:
            dl = &downloadFtp;
            break;
        case UrlType.Http:
            dl = &downloadHttp;
            break;
        case UrlType.NameOnly:
        case UrlType.OwnerName:
        case UrlType.RemoteGithub:
            unreachable;
    }

    dl(remote, dest);
}
