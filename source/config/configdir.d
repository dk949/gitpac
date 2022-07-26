module config.configdir;
import std.array;
import std.file;
import std.path;
import std.process;
import std.functional;
import utils;
package:

immutable defaultConfigBaseName = "gitpac";
immutable configDirEnvVariableName = "GITPAC_CONFIG_DIR";

immutable defaultConfigFile = "config.yaml";
immutable defaultRecipeDir = "recipes";

alias configDir = memoize!configDirNoMemo;
alias defaultConfigDir = memoize!defaultConfigDirNoMemo;

private string defaultConfigDirNoMemo() {

    string configDir;

    if (immutable xdgConfigDir = environment.get("XDG_CONFIG_HOME"))
        configDir = xdgConfigDir;
    else if (immutable homeDir = environment.get("HOME"))
        configDir = homeDir.chainPath(".config").array;
    else
        exitWithError("Could not deretmine config directory.
Please define $XDG_CONFIG_HOME or $HOME environment variables");

    if (!exists(configDir))
        exitWithError(
            "The config directory as defined by $XDG_CONFIG_HOME or $HOME/.config does not exist.
Please create it or check the values of these variables are correct");

    configDir = configDir.chainPath(defaultConfigBaseName).array;
    if (!exists(configDir))
        mkdir(configDir);
    return configDir;
}

private string configDirNoMemo() {
    return environment.get(configDirEnvVariableName, defaultConfigDir);
}

