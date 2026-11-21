# Show Damage (text)

Shows the damage you deal to other players as plain text: in the center of the screen, in the
hint box or in chat. Hits landed within about 0.1 s (SourceMod timer resolution: shotgun
pellets, one grenade hitting several players) are summed and shown as one line, e.g. `- 87 HP`.

Text only: no materials, particles or sounds, so players download nothing.

This is a port of **Show Damage 1.0.7 by exvel**, the plugin that reports
`sm_show_damage_version 1.0.7` on many servers, to the srcdslab conventions (new syntax,
methodmaps, MultiColors, CI builds for SourceMod 1.12 and 1.13). The behaviour and the cvar names
are unchanged.

- Original thread: https://forums.alliedmods.net/showthread.php?t=85901
- Original download: `ShowDamage_v1.0.7.zip`
  ([attachment 60615](https://forums.alliedmods.net/attachment.php?attachmentid=60615)),
  imported verbatim as the first commit of this repository.

## Requirements

- SourceMod 1.12 or newer (built and tested by CI against 1.12 and 1.13).
- `clientprefs` extension (shipped with SourceMod) for the per-player on/off switch.
- No gamedata: works on 32-bit and 64-bit servers alike.
- Build dependency only: [MultiColors](https://github.com/srcdslab/sm-plugin-MultiColors)
  (`multicolors.inc`, compiled into the plugin).

## Installation

Download the archive for your SourceMod version from the
[releases](https://github.com/srcdslab/sm-plugin-ShowDamageText/releases)
(`-sm1.12` or `-sm1.13`) and extract it into `cstrike/`:

```
addons/sourcemod/plugins/ShowDamageText.smx
addons/sourcemod/translations/ShowDamageText.phrases.txt
```

`cfg/sourcemod/plugin.showdamage.cfg` is created on the first start.

If you are replacing the original plugin, delete `addons/sourcemod/plugins/showdamage.smx` and
`addons/sourcemod/translations/showdamage.phrases.txt`. The config file and the players' saved
choices (cookie `Show Damage On/Off`) are reused as they are.

## Server ConVars

| ConVar | Default | Description |
| --- | --- | --- |
| `sm_show_damage` | `1` | Enable (1) or disable (0) the plugin. |
| `sm_show_damage_ff` | `0` | Also show damage dealt to teammates. Enable it on deathmatch (non-team) servers. |
| `sm_show_damage_own_dmg` | `0` | Also show damage you deal to yourself (e.g. your own HE grenade). |
| `sm_show_damage_text_area` | `1` | Where the text is shown: 1 = center of the screen, 2 = hint box, 3 = chat. |
| `sm_show_damage_version` | `1.0.7-srcdslab` | Plugin version (read only). |

## Player settings

Players can turn the display on or off for themselves in the `!settings` menu
(**Show Damage: On/Off**). The choice is saved with clientprefs.

## Translations

`ShowDamageText.phrases.txt`: English, Russian (upstream) and French. The chat line
(`sm_show_damage_text_area 3`) accepts MultiColors tags such as `{green}`.

## Relation to sm-plugin-ShowDamage

[srcdslab/sm-plugin-ShowDamage](https://github.com/srcdslab/sm-plugin-ShowDamage) (GammaCase's
Fortnite-style hit numbers) is a different plugin that needs custom materials and particles. The
two are not meant to run on the same server:

- They share no cvar, command or cookie name, but both are called "Show Damage" in
  `sm plugins list` and both use the `sm_show_damage_` cvar prefix.
- The upstream file names `showdamage.smx` / `showdamage.phrases.txt` differed from
  `ShowDamage.smx` / `ShowDamage.phrases.txt` only by case, which collides on a case-insensitive
  file system. This port ships `ShowDamageText.smx` and `ShowDamageText.phrases.txt` instead.

## Credits

- [exvel](https://forums.alliedmods.net/member.php?u=17252), author of Show Damage.
- srcdslab, port and maintenance.

## License

GPL-3.0, like SourceMod and the plugins it loads. See [LICENSE](LICENSE).
