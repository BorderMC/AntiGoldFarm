package net.bordermc.antiGoldFarm;

import net.bordermc.antiGoldFarm.command.AntiGoldFarmCommand;
import net.bordermc.antiGoldFarm.listener.AntiGoldFarmListener;
import net.bordermc.antiGoldFarm.service.ConfigManager;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.Objects;

public final class AntiGoldFarm extends JavaPlugin {
    private final ConfigManager config;

    public AntiGoldFarm() {
        this.config = new ConfigManager(this);
    }

    @Override
    public void onEnable() {
        // Config initialization
        saveDefaultConfig();
        config.reload();

        // Listener & command registration
        Objects.requireNonNull(getCommand("antigoldfarm"), "Command 'antigoldfarm' is not defined in plugin.yml")
                .setExecutor(new AntiGoldFarmCommand(config));

        getServer().getPluginManager().registerEvents(
                new AntiGoldFarmListener(config), this
        );
    }
}
