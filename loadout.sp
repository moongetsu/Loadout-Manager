#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#include <multicolors>

enum
{
    SLOT_STARTER_PISTOL = 0,
    SLOT_SIDEARM,
    SLOT_HEAVY_PISTOL,
    SLOT_SMG,
    SLOT_RIFLE,
    SLOT_MAX
}

Cookie g_hCookie_Loadout;

int    g_iClientLoadout[MAXPLAYERS + 1][SLOT_MAX];

public Plugin myinfo =
{
    name        = "Loadout Manager",
    author      = "moongetsu",
    description = "Optimized weapon swapper for custom loadouts.",
    version     = "1.2",
    url         = "https://github.com/moongetsu"
};

public void OnPluginStart()
{
    g_hCookie_Loadout = new Cookie("loadout_v1", "Weapon preferences", CookieAccess_Private);

    RegConsoleCmd("sm_loadout", Command_Loadout, "Open loadout manager.");
    RegConsoleCmd("sm_lo", Command_Loadout, "Open loadout manager.");

    LoadTranslations("loadout.phrases");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (AreClientCookiesCached(i)) OnClientCookiesCached(i);
        }
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (classname[0] == 'w' && strncmp(classname, "weapon_", 7) == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnWeaponSpawnPost);
    }
}

public void OnClientCookiesCached(int client)
{
    char sBuffer[32];
    g_hCookie_Loadout.Get(client, sBuffer, sizeof(sBuffer));

    if (sBuffer[0] == '\0')
    {
        for (int i = 0; i < SLOT_MAX; i++)
            g_iClientLoadout[client][i] = 0;
        return;
    }

    char sParts[SLOT_MAX][4];
    int  count = ExplodeString(sBuffer, ";", sParts, SLOT_MAX, 4);

    for (int i = 0; i < count; i++)
    {
        g_iClientLoadout[client][i] = StringToInt(sParts[i]);
    }
}

void SaveLoadout(int client)
{
    char sBuffer[32];
    Format(sBuffer, sizeof(sBuffer), "%d;%d;%d;%d;%d",
           g_iClientLoadout[client][SLOT_STARTER_PISTOL],
           g_iClientLoadout[client][SLOT_SIDEARM],
           g_iClientLoadout[client][SLOT_HEAVY_PISTOL],
           g_iClientLoadout[client][SLOT_SMG],
           g_iClientLoadout[client][SLOT_RIFLE]);

    g_hCookie_Loadout.Set(client, sBuffer);
}

public void OnWeaponSpawnPost(int weapon)
{
    RequestFrame(Frame_CheckWeapon, EntIndexToEntRef(weapon));
}

void Frame_CheckWeapon(any data)
{
    int weapon = EntRefToEntIndex(data);
    if (weapon == INVALID_ENT_REFERENCE || !IsValidEntity(weapon))
        return;

    int owner = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
    if (owner < 1 || owner > MaxClients || !IsClientInGame(owner))
    {
        owner = GetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner");
        if (owner < 1 || owner > MaxClients || !IsClientInGame(owner))
            return;
    }

    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));
    int team = GetClientTeam(owner);

    if (team == CS_TEAM_CT)
    {
        if (StrEqual(classname, "weapon_hkp2000") && g_iClientLoadout[owner][SLOT_STARTER_PISTOL] == 1)
            PerformSwap(owner, weapon, "weapon_usp_silencer");
        else if (StrEqual(classname, "weapon_usp_silencer") && g_iClientLoadout[owner][SLOT_STARTER_PISTOL] == 0)
            PerformSwap(owner, weapon, "weapon_hkp2000");

        if (StrEqual(classname, "weapon_fiveseven") && g_iClientLoadout[owner][SLOT_SIDEARM] == 1)
            PerformSwap(owner, weapon, "weapon_cz75a");
        else if (StrEqual(classname, "weapon_cz75a") && g_iClientLoadout[owner][SLOT_SIDEARM] == 0)
        {
            PerformSwap(owner, weapon, "weapon_fiveseven");
        }

        if (StrEqual(classname, "weapon_m4a1") && g_iClientLoadout[owner][SLOT_RIFLE] == 1)
            PerformSwap(owner, weapon, "weapon_m4a1_silencer");
        else if (StrEqual(classname, "weapon_m4a1_silencer") && g_iClientLoadout[owner][SLOT_RIFLE] == 0)
            PerformSwap(owner, weapon, "weapon_m4a1");
    }
    else if (team == CS_TEAM_T)
    {
        if (StrEqual(classname, "weapon_tec9") && g_iClientLoadout[owner][SLOT_SIDEARM] == 1)
            PerformSwap(owner, weapon, "weapon_cz75a");
        else if (StrEqual(classname, "weapon_cz75a") && g_iClientLoadout[owner][SLOT_SIDEARM] == 0)
            PerformSwap(owner, weapon, "weapon_tec9");
    }

    if (StrEqual(classname, "weapon_deagle") && g_iClientLoadout[owner][SLOT_HEAVY_PISTOL] == 1)
        PerformSwap(owner, weapon, "weapon_revolver");
    else if (StrEqual(classname, "weapon_revolver") && g_iClientLoadout[owner][SLOT_HEAVY_PISTOL] == 0)
        PerformSwap(owner, weapon, "weapon_deagle");

    if (StrEqual(classname, "weapon_mp7") && g_iClientLoadout[owner][SLOT_SMG] == 1)
        PerformSwap(owner, weapon, "weapon_mp5sd");
    else if (StrEqual(classname, "weapon_mp5sd") && g_iClientLoadout[owner][SLOT_SMG] == 0)
        PerformSwap(owner, weapon, "weapon_mp7");
}

void PerformSwap(int client, int oldWeapon, const char[] newClassname)
{
    if (GetEntProp(oldWeapon, Prop_Data, "m_iHammerID") == 716)
        return;

    RemoveEntity(oldWeapon);

    int newWeapon = GivePlayerItem(client, newClassname);
    if (newWeapon != -1)
    {
        SetEntProp(newWeapon, Prop_Data, "m_iHammerID", 716);
    }
}

public Action Command_Loadout(int client, int args)
{
    if (client == 0)
        return Plugin_Handled;
    OpenLoadoutMenu(client);
    return Plugin_Handled;
}

void OpenLoadoutMenu(int client)
{
    Menu menu = new Menu(Handler_Loadout);

    char sTitle[256];
    Format(sTitle, sizeof(sTitle), "%T\n \n%T\n ", "Loadout_Title", client, "Loadout_Desc", client);
    menu.SetTitle(sTitle);

    int  team = GetClientTeam(client);

    char sBuffer[128];
    if (team == CS_TEAM_CT)
    {
        Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][SLOT_STARTER_PISTOL] == 0 ? "Item_Starter_P2000" : "Item_Starter_USP", client);
        menu.AddItem("0", sBuffer);

        Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][SLOT_SIDEARM] == 0 ? "Item_Sidearm_FiveSeven" : "Item_Sidearm_CZ", client);
        menu.AddItem("1", sBuffer);

        Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][SLOT_RIFLE] == 0 ? "Item_Rifle_M4A4" : "Item_Rifle_M4A1", client);
        menu.AddItem("4", sBuffer);
    }
    else if (team == CS_TEAM_T)
    {
        Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][SLOT_SIDEARM] == 0 ? "Item_Sidearm_Tec9" : "Item_Sidearm_CZ", client);
        menu.AddItem("1", sBuffer);
    }

    Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][SLOT_HEAVY_PISTOL] == 0 ? "Item_Heavy_Deagle" : "Item_Heavy_Revolver", client);
    menu.AddItem("2", sBuffer);

    Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][SLOT_SMG] == 0 ? "Item_SMG_MP7" : "Item_SMG_MP5", client);
    menu.AddItem("3", sBuffer);

    menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_Loadout(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[16];
        menu.GetItem(param2, info, sizeof(info));
        int slot                       = StringToInt(info);

        g_iClientLoadout[param1][slot] = !g_iClientLoadout[param1][slot];

        SaveLoadout(param1);

        CPrintToChat(param1, "%T", "Loadout_Updated", param1);

        OpenLoadoutMenu(param1);
    }
    else if (action == MenuAction_End)
        delete menu;
    return 0;
}
