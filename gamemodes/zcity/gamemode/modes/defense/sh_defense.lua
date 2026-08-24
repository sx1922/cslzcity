local MODE = MODE

zb = zb or {}
zb.Points = zb.Points or {}

zb.Points.NPC_DEFENSE_SPAWN= zb.Points.NPC_DEFENSE_SPAWN or {}
zb.Points.NPC_DEFENSE_SPAWN.Color = Color(243,9,9)
zb.Points.NPC_DEFENSE_SPAWN.Name = "NPC_DEFENSE_SPAWN"

zb.Points.PLY_DEFENSE_SPAWN = zb.Points.PLY_DEFENSE_SPAWN or {}
zb.Points.PLY_DEFENSE_SPAWN.Color = Color(51,243,9)
zb.Points.PLY_DEFENSE_SPAWN.Name = "PLY_DEFENSE_SPAWN"

zb.Points.DEFENSE_POINT = zb.Points.DEFENSE_POINT or {}
zb.Points.DEFENSE_POINT.Color = Color(13,9,243)
zb.Points.DEFENSE_POINT.Name = "DEFENSE_POINT"


MODE.SUBMODES = {
    STANDARD = {
        name = "标准",
        description = "经典6波联合军攻击",
        waves = 6,
        enemy_type = "combine"
    },
    EXTENDED = {
        name = "扩展",
        description = "扩展模式：12波包含BOSS和特殊敌人",
        waves = 12,
        enemy_type = "combine"
    },
    ZOMBIE = {
        name = "僵尸",
        description = "6波僵尸末日",
        waves = 6,
        enemy_type = "zombie"
    }
}