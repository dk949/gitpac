import std.stdio;
import std.traits;
import std.algorithm;
import args;
import args.clonecmd;
import config;
import clone: clone;
import utils;

int main(string[] a) {
    try {
        const args = Args(a);
        const config = UserConfig.load();

        return args.subcommand.constCastSwitch!(
            (CloneCmd c) => clone(c, config)
        );

    } catch (Exception e) {
        debug {
            writeln("[DEBUG] Error:\n", e);
            return 3;
        } else {
            stderr.writeln("Error: ", e.message);
            return 1;
        }
    }
}
