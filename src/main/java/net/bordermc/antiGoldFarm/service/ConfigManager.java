package net.bordermc.antiGoldFarm.service;

import net.bordermc.antiGoldFarm.AntiGoldFarm;
import org.bukkit.configuration.file.FileConfiguration;
import org.jetbrains.annotations.NotNull;

public class ConfigManager {
    private final AntiGoldFarm plugin;

    private boolean enabled;

    public ConfigManager(@NotNull AntiGoldFarm plugin) {
        this.plugin = plugin;
        reload();
    }

    public void reload() {
        plugin.reloadConfig();
        FileConfiguration config = plugin.getConfig();

        enabled = config.getBoolean("enabled", true);
    }

    public boolean enabled() {
        return enabled;
    }
}
