module config.userconfig;

import config.baseconfig;
import config.configdir;
import config.utils;
import dyaml;
import url;

class UserConfig : BaseConfig {
    int numRetires = 5;
    bool useSSH = false;
    string storeDir;
    Url[] baseUrl = [DefaultUrl.Github];

    this() {
        storeDir = defaultConfigDir;
    }

    mixin makeFromYaml!UserConfig;

    static UserConfig load() {
        import std.path;
        import std.array;
        import std.file;

        auto conf = new UserConfig();
        immutable configFile = configDir.chainPath(defaultConfigFile).array;

        // If no UserConfig, use default UserConfig
        if (!exists(configFile))
            return conf;

        immutable file = loadYaml(configFile);
        if (file.type == NodeType.invalid)
            return conf;
        import std.traits;

        conf.fromYaml(file);
        return conf;
    }
}
