---
name: no-modificar-archivos-originales
description: Threadbare es open-source; no modificar archivos originales del proyecto base
metadata:
  type: feedback
---

El proyecto (Threadbare) es open-source. NO se deben modificar los archivos originales del juego base (player.gd, player.tscn, enums.gd, project.godot, game_state.gd, tilesets, escenas base, etc.).

**Why:** Mantener el fork limpio frente a upstream y evitar conflictos al actualizar.

**How to apply:** Toda funcionalidad nueva (mecánicas, props, habilidades) debe vivir en archivos nuevos dentro de la carpeta de la quest correspondiente (ej. `scenes/quests/lore_quests/quest_004/`). Para integrarse sin tocar el core: reusar flags de habilidad ya existentes pero no usados por el core (ABILITY_C y modifiers — player.gd solo usa ABILITY_A, ABILITY_B y ABILITY_B_MODIFIER_1), registrar input actions en runtime con `InputMap.add_action()`, usar capas de colisión por número o detección por grupos (`get_nodes_in_group`), y enganchar lógica vía señales/grupos existentes. Relacionado: [[void-test-folder]] si existe.
