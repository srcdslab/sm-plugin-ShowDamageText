## Release Notes

## [1.0.7-srcdslab]

First srcdslab release, ported from Show Damage 1.0.7 by exvel
(https://forums.alliedmods.net/showthread.php?t=85901). Behaviour, cvar names, the config file
name (`plugin.showdamage.cfg`) and the clientprefs cookie name are unchanged.

### Changed

- srcdslab layout (`addons/sourcemod/{scripting,translations}`), new syntax
  (`#pragma semicolon 1`, `#pragma newdecls required`) and methodmaps (`ConVar`, `Event`, `Cookie`).
- Plugin and translation files renamed to `ShowDamageText.smx` and `ShowDamageText.phrases.txt`
  (the upstream `showdamage.*` names collided, by case only, with
  [sm-plugin-ShowDamage](https://github.com/srcdslab/sm-plugin-ShowDamage)).
- Chat colors use [MultiColors](https://github.com/srcdslab/sm-plugin-MultiColors) instead of
  exvel's old `colors.inc`.
- Removed the obsolete `FCVAR_PLUGIN` flag.
- `myinfo` URL points to this repository.

### Fixed

- The display timer gets the attacker's userid instead of the client index, so a player who leaves
  within the same 0.1 s no longer gets their damage shown to whoever takes the slot.
- A new player in a slot no longer inherits the previous player's on/off choice or pending damage
  (reset in `OnClientConnected`).
- Cookies are read for players already in game when the plugin is loaded late.
- `player_hurt` with an invalid victim no longer throws an error in the frame-based mode (games
  without damage in `player_hurt`).
- The attacker is checked to be in game before `IsFakeClient`.

### Added

- French translation.
- CI: builds for SourceMod 1.12 and 1.13, translation check, `latest` and tagged releases with one
  archive per SourceMod version, Dependabot for GitHub Actions.
