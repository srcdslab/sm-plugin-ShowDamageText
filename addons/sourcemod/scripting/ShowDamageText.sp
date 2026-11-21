#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <multicolors>

#define PLUGIN_VERSION "1.0.7-srcdslab"

public Plugin myinfo =
{
	name = "Show Damage",
	author = "exvel",
	description = "Shows damage in the center of the screen.",
	version = PLUGIN_VERSION,
	url = "https://github.com/srcdslab/sm-plugin-ShowDamageText"
};

int g_iPlayerOldHealth[MAXPLAYERS + 1];
int g_iPlayerDamage[MAXPLAYERS + 1];
bool g_bBlockTimer[MAXPLAYERS + 1] = {false, ...};
bool g_bFrameMod = true;
char g_sDamageEventName[16];
int g_iMaxDamage = 10000000;
bool g_bOptionShowDamage[MAXPLAYERS + 1] = {true, ...};
Cookie g_hCookieShowDamage;

// CVars' handles
ConVar g_cvShowDamage;
ConVar g_cvShowDamageFF;
ConVar g_cvShowDamageOwnDmg;
ConVar g_cvShowDamageTextArea;

// CVars' variables
bool g_bShowDamage = true;
bool g_bShowDamageFF = false;
bool g_bShowDamageOwnDmg = false;
int g_iShowDamageTextArea = 1;

public void OnPluginStart()
{
	char sGameName[80];
	GetGameFolderName(sGameName, sizeof(sGameName));

	if (StrEqual(sGameName, "cstrike") || StrEqual(sGameName, "insurgency"))
	{
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		strcopy(g_sDamageEventName, sizeof(g_sDamageEventName), "dmg_health");
		g_bFrameMod = false;
	}
	else if (StrEqual(sGameName, "left4dead") || StrEqual(sGameName, "left4dead2"))
	{
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
		g_iMaxDamage = 2000;
		strcopy(g_sDamageEventName, sizeof(g_sDamageEventName), "dmg_health");
		g_bFrameMod = false;
	}
	else if (StrEqual(sGameName, "dod") || StrEqual(sGameName, "hidden"))
	{
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		strcopy(g_sDamageEventName, sizeof(g_sDamageEventName), "damage");
		g_bFrameMod = false;
	}
	else
	{
		HookEvent("player_hurt", Event_PlayerHurt_FrameMod, EventHookMode_Pre);
		g_bFrameMod = true;
	}

	CreateConVar("sm_show_damage_version", PLUGIN_VERSION, "Show Damage Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvShowDamage = CreateConVar("sm_show_damage", "1", "Enabled/Disabled show damage functionality, 0 = off/1 = on", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvShowDamageFF = CreateConVar("sm_show_damage_ff", "0", "Show friendly fire damage, 0 = off/1 = on", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvShowDamageOwnDmg = CreateConVar("sm_show_damage_own_dmg", "0", "Show your own damage, 0 = off/1 = on", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvShowDamageTextArea = CreateConVar("sm_show_damage_text_area", "1", "Defines the area for damage text:\n 1 = in the center of the screen\n 2 = in the hint text area \n 3 = in chat area of screen", FCVAR_NONE, true, 1.0, true, 3.0);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	g_cvShowDamage.AddChangeHook(OnCVarChange);
	g_cvShowDamageFF.AddChangeHook(OnCVarChange);
	g_cvShowDamageOwnDmg.AddChangeHook(OnCVarChange);
	g_cvShowDamageTextArea.AddChangeHook(OnCVarChange);

	// Upstream config name, kept so an existing cfg/sourcemod/plugin.showdamage.cfg still applies
	AutoExecConfig(true, "plugin.showdamage");
	LoadTranslations("common.phrases");
	LoadTranslations("ShowDamageText.phrases");

	// Upstream cookie name, kept so the choices players already saved still apply
	g_hCookieShowDamage = new Cookie("Show Damage On/Off", "", CookieAccess_Private);
	SetCookieMenuItem(CookieMenuHandler_ShowDamage, 0, "Show Damage");

	// Late load
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && AreClientCookiesCached(client))
		{
			OnClientCookiesCached(client);
		}
	}
}

public void CookieMenuHandler_ShowDamage(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		char sStatus[32];
		if (g_bOptionShowDamage[client])
		{
			FormatEx(sStatus, sizeof(sStatus), "%T", "On", client);
		}
		else
		{
			FormatEx(sStatus, sizeof(sStatus), "%T", "Off", client);
		}

		FormatEx(buffer, maxlen, "%T: %s", "Cookie Show Damage", client, sStatus);
	}
	// CookieMenuAction_SelectOption
	else
	{
		g_bOptionShowDamage[client] = !g_bOptionShowDamage[client];

		if (g_bOptionShowDamage[client])
		{
			g_hCookieShowDamage.Set(client, "On");
		}
		else
		{
			g_hCookieShowDamage.Set(client, "Off");
		}

		ShowCookieMenu(client);
	}
}

public void OnClientCookiesCached(int client)
{
	g_bOptionShowDamage[client] = GetCookieShowDamage(client);
}

bool GetCookieShowDamage(int client)
{
	char sBuffer[10];
	g_hCookieShowDamage.Get(client, sBuffer, sizeof(sBuffer));

	return !StrEqual(sBuffer, "Off");
}

public void OnConfigsExecuted()
{
	GetCVars();
}

public void OnClientConnected(int client)
{
	g_bBlockTimer[client] = false;
	g_iPlayerDamage[client] = 0;
	// Do not inherit the choice of the previous player in this slot
	g_bOptionShowDamage[client] = true;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bBlockTimer[client] = false;
}

// This is for games that have no damage information in player_hurt event
public void OnGameFrame()
{
	if (g_bFrameMod && g_bShowDamage)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				g_iPlayerOldHealth[client] = GetClientHealth(client);
			}
		}
	}
}

public Action Timer_ShowDamage(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client)
	{
		return Plugin_Stop;
	}

	g_bBlockTimer[client] = false;

	if (g_iPlayerDamage[client] <= 0 || !IsClientInGame(client))
	{
		return Plugin_Stop;
	}

	switch (g_iShowDamageTextArea)
	{
		case 1:
		{
			PrintCenterText(client, "%t", "CenterText Damage Text", g_iPlayerDamage[client]);
		}

		case 2:
		{
			PrintHintText(client, "%t", "HintText Damage Text", g_iPlayerDamage[client]);
		}

		case 3:
		{
			CPrintToChat(client, "%t", "Chat Damage Text", g_iPlayerDamage[client]);
		}
	}

	g_iPlayerDamage[client] = 0;

	return Plugin_Stop;
}

public Action Event_PlayerHurt_FrameMod(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!client)
	{
		return Plugin_Continue;
	}

	int iDamage = g_iPlayerOldHealth[client] - GetClientHealth(client);

	CalcDamage(client, iAttacker, iDamage);

	return Plugin_Continue;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int client = GetClientOfUserId(event.GetInt("userid"));
	int iDamage = event.GetInt(g_sDamageEventName);

	CalcDamage(client, iAttacker, iDamage);
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iDamage = event.GetInt("amount");

	CalcDamage(0, iAttacker, iDamage);
}

void CalcDamage(int client, int iAttacker, int iDamage)
{
	if (iAttacker == 0)
	{
		return;
	}

	if (!g_bShowDamage || !g_bOptionShowDamage[iAttacker])
	{
		return;
	}

	if (!IsClientInGame(iAttacker) || IsFakeClient(iAttacker))
	{
		return;
	}

	// If client == 0 then skip this check. It can be an infected or something else without client index.
	if (client != 0)
	{
		if (client == iAttacker)
		{
			if (!g_bShowDamageOwnDmg)
			{
				return;
			}
		}
		else if (GetClientTeam(client) == GetClientTeam(iAttacker))
		{
			if (!g_bShowDamageFF)
			{
				return;
			}
		}
	}

	// This is a fix for Left 4 Dead. When tank dies the game fires hurt event with 5000 dmg that is a bug.
	if (iDamage > g_iMaxDamage)
	{
		return;
	}

	g_iPlayerDamage[iAttacker] += iDamage;

	if (g_bBlockTimer[iAttacker])
	{
		return;
	}

	CreateTimer(0.01, Timer_ShowDamage, GetClientUserId(iAttacker));
	g_bBlockTimer[iAttacker] = true;
}

public void OnCVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

void GetCVars()
{
	g_bShowDamage = g_cvShowDamage.BoolValue;
	g_bShowDamageFF = g_cvShowDamageFF.BoolValue;
	g_bShowDamageOwnDmg = g_cvShowDamageOwnDmg.BoolValue;
	g_iShowDamageTextArea = g_cvShowDamageTextArea.IntValue;
}
