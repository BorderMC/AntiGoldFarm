package net.bordermc.antiGoldFarm.listener;

import net.bordermc.antiGoldFarm.service.ConfigManager;
import org.bukkit.Material;
import org.bukkit.entity.EntityType;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.EntityDeathEvent;
import org.jetbrains.annotations.NotNull;

public class AntiGoldFarmListener implements Listener {
    private final ConfigManager config;

    public AntiGoldFarmListener(@NotNull ConfigManager config) {
        this.config = config;
    }

    @EventHandler
    public void onEntityDeath(@NotNull EntityDeathEvent event) {
        if (!config.enabled()) return;

        if (event.getEntityType() == EntityType.ZOMBIFIED_PIGLIN || event.getEntityType() == EntityType.PIGLIN || event.getEntityType() == EntityType.PIGLIN_BRUTE) {
            event.getDrops().removeIf(item -> isGolden(item.getType()));
        }
    }

    public static boolean isGolden(@NotNull Material type) {
        return switch (type) {
            case GOLD_INGOT,
                 GOLDEN_SWORD,
                 GOLDEN_AXE,
                 GOLDEN_SHOVEL,
                 GOLDEN_PICKAXE,
                 GOLDEN_SPEAR,
                 GOLDEN_HOE,
                 GOLDEN_HELMET,
                 GOLDEN_CHESTPLATE,
                 GOLDEN_LEGGINGS,
                 GOLDEN_BOOTS,
                 GOLD_NUGGET -> true;
            default -> false;
        };
    }
}
