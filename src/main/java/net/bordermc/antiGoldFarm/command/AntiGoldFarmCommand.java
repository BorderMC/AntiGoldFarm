package net.bordermc.antiGoldFarm.command;

import net.bordermc.antiGoldFarm.service.ConfigManager;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.bukkit.command.TabCompleter;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.List;
import java.util.Locale;

public class AntiGoldFarmCommand implements CommandExecutor, TabCompleter {
    private final ConfigManager config;

    private static final List<String> SUBCOMMANDS = List.of(
            "reload"
    );

    public AntiGoldFarmCommand(@NotNull ConfigManager config) {
        this.config = config;
    }

    @Override
    public boolean onCommand(@NotNull CommandSender sender, @NotNull Command command, @NotNull String label, @NotNull String[] args) {
        if (args.length == 1 && args[0].equalsIgnoreCase("reload")) {
            config.reload();
            sender.sendMessage(Component.text("AntiGoldFarm configuration reloaded.", NamedTextColor.GREEN));
            return true;
        }

        sender.sendMessage(Component.text("Usage: /" + label + " reload", NamedTextColor.RED));
        return true;
    }

    @Override
    public @Nullable List<String> onTabComplete(@NotNull CommandSender sender, @NotNull Command command, @NotNull String label, @NotNull String @NotNull [] args) {
        if (args.length != 1) {
            return List.of();
        }

        String input = args[0].toLowerCase(Locale.ROOT);

        return SUBCOMMANDS.stream()
                .filter(subcommand -> subcommand.startsWith(input))
                .toList();
    }
}
