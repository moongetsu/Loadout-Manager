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

int    g_iClientLoadout[MAXPLAYERS + 1][2][SLOT_MAX];

#define TEAM_T_IDX  0
#define TEAM_CT_IDX 1

public Plugin myinfo =
{
    name        = "Loadout Manager",
    author      = "moongetsu",
    description = "Optimized weapon swapper for custom loadouts.",
    version     = "1.3",
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
    char sBuffer[64];
    g_hCookie_Loadout.Get(client, sBuffer, sizeof(sBuffer));

    if (sBuffer[0] == '\0')
    {
        for (int i = 0; i < SLOT_MAX; i++)
        {
            g_iClientLoadout[client][TEAM_T_IDX][i]  = 0;
            g_iClientLoadout[client][TEAM_CT_IDX][i] = 0;
        }
        return;
    }

    char sParts[SLOT_MAX * 2][4];
    int  count = ExplodeString(sBuffer, ";", sParts, SLOT_MAX * 2, 4);

    if (count == SLOT_MAX)
    {
        for (int i = 0; i < SLOT_MAX; i++)
        {
            int val                                  = StringToInt(sParts[i]);
            g_iClientLoadout[client][TEAM_T_IDX][i]  = val;
            g_iClientLoadout[client][TEAM_CT_IDX][i] = val;
        }
    }
    else
    {
        for (int i = 0; i < count; i++)
        {
            int teamIdx = i / SLOT_MAX;
            int slotIdx = i % SLOT_MAX;
            if (teamIdx < 2)
                g_iClientLoadout[client][teamIdx][slotIdx] = StringToInt(sParts[i]);
        }
    }
}

void SaveLoadout(int client)
{
    char sBuffer[64];
    Format(sBuffer, sizeof(sBuffer), "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d",
           g_iClientLoadout[client][TEAM_T_IDX][SLOT_STARTER_PISTOL],
           g_iClientLoadout[client][TEAM_T_IDX][SLOT_SIDEARM],
           g_iClientLoadout[client][TEAM_T_IDX][SLOT_HEAVY_PISTOL],
           g_iClientLoadout[client][TEAM_T_IDX][SLOT_SMG],
           g_iClientLoadout[client][TEAM_T_IDX][SLOT_RIFLE],
           g_iClientLoadout[client][TEAM_CT_IDX][SLOT_STARTER_PISTOL],
           g_iClientLoadout[client][TEAM_CT_IDX][SLOT_SIDEARM],
           g_iClientLoadout[client][TEAM_CT_IDX][SLOT_HEAVY_PISTOL],
           g_iClientLoadout[client][TEAM_CT_IDX][SLOT_SMG],
           g_iClientLoadout[client][TEAM_CT_IDX][SLOT_RIFLE]);

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
    int team    = GetClientTeam(owner);
    int teamIdx = (team == CS_TEAM_CT) ? TEAM_CT_IDX : TEAM_T_IDX;

    if (team == CS_TEAM_CT)
    {
        if (StrEqual(classname, "weapon_hkp2000") && g_iClientLoadout[owner][TEAM_CT_IDX][SLOT_STARTER_PISTOL] == 1)
            PerformSwap(owner, weapon, "weapon_usp_silencer");
        else if (StrEqual(classname, "weapon_usp_silencer") && g_iClientLoadout[owner][TEAM_CT_IDX][SLOT_STARTER_PISTOL] == 0)
            PerformSwap(owner, weapon, "weapon_hkp2000");

        if (StrEqual(classname, "weapon_fiveseven") && g_iClientLoadout[owner][TEAM_CT_IDX][SLOT_SIDEARM] == 1)
            PerformSwap(owner, weapon, "weapon_cz75a");
        else if (StrEqual(classname, "weapon_cz75a") && g_iClientLoadout[owner][TEAM_CT_IDX][SLOT_SIDEARM] == 0)
        {
            PerformSwap(owner, weapon, "weapon_fiveseven");
        }

        if (StrEqual(classname, "weapon_m4a1") && g_iClientLoadout[owner][TEAM_CT_IDX][SLOT_RIFLE] == 1)
            PerformSwap(owner, weapon, "weapon_m4a1_silencer");
        else if (StrEqual(classname, "weapon_m4a1_silencer") && g_iClientLoadout[owner][TEAM_CT_IDX][SLOT_RIFLE] == 0)
            PerformSwap(owner, weapon, "weapon_m4a1");
    }
    else if (team == CS_TEAM_T)
    {
        if (StrEqual(classname, "weapon_tec9") && g_iClientLoadout[owner][TEAM_T_IDX][SLOT_SIDEARM] == 1)
            PerformSwap(owner, weapon, "weapon_cz75a");
        else if (StrEqual(classname, "weapon_cz75a") && g_iClientLoadout[owner][TEAM_T_IDX][SLOT_SIDEARM] == 0)
            PerformSwap(owner, weapon, "weapon_tec9");
    }

    if (StrEqual(classname, "weapon_deagle") && g_iClientLoadout[owner][teamIdx][SLOT_HEAVY_PISTOL] == 1)
        PerformSwap(owner, weapon, "weapon_revolver");
    else if (StrEqual(classname, "weapon_revolver") && g_iClientLoadout[owner][teamIdx][SLOT_HEAVY_PISTOL] == 0)
        PerformSwap(owner, weapon, "weapon_deagle");

    if (StrEqual(classname, "weapon_mp7") && g_iClientLoadout[owner][teamIdx][SLOT_SMG] == 1)
        PerformSwap(owner, weapon, "weapon_mp5sd");
    else if (StrEqual(classname, "weapon_mp5sd") && g_iClientLoadout[owner][teamIdx][SLOT_SMG] == 0)
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

    int team = GetClientTeam(client);
    if (team < CS_TEAM_T)
    {
        CPrintToChat(client, "%t", "Only_Team");
        return Plugin_Handled;
    }

    OpenLoadoutMenu(client);
    return Plugin_Handled;
}

void OpenLoadoutMenu(int client)
{
    Menu menu = new Menu(Handler_Loadout);

    char sTitle[256];
    Format(sTitle, sizeof(sTitle), "%T\n \n%T\n ", "Loadout_Title", client, "Loadout_Desc", client);
    menu.SetTitle(sTitle);

    int  team    = GetClientTeam(client);
    int  teamIdx = (team == CS_TEAM_CT) ? TEAM_CT_IDX : TEAM_T_IDX;

    char sBuffer[128];
    char sInfo[16];

    if (team == CS_TEAM_CT)
    {
        Format(sInfo, sizeof(sInfo), "%d|%d", TEAM_CT_IDX, SLOT_STARTER_PISTOL);
        Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][TEAM_CT_IDX][SLOT_STARTER_PISTOL] == 0 ? "Item_Starter_P2000" : "Item_Starter_USP", client);
        menu.AddItem(sInfo, sBuffer);

        Format(sInfo, sizeof(sInfo), "%d|%d", TEAM_CT_IDX, SLOT_SIDEARM);
        Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][TEAM_CT_IDX][SLOT_SIDEARM] == 0 ? "Item_Sidearm_FiveSeven" : "Item_Sidearm_CZ", client);
        menu.AddItem(sInfo, sBuffer);

        Format(sInfo, sizeof(sInfo), "%d|%d", TEAM_CT_IDX, SLOT_RIFLE);
        Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][TEAM_CT_IDX][SLOT_RIFLE] == 0 ? "Item_Rifle_M4A4" : "Item_Rifle_M4A1", client);
        menu.AddItem(sInfo, sBuffer);
    }
    else if (team == CS_TEAM_T)
    {
        Format(sInfo, sizeof(sInfo), "%d|%d", TEAM_T_IDX, SLOT_SIDEARM);
        Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][TEAM_T_IDX][SLOT_SIDEARM] == 0 ? "Item_Sidearm_Tec9" : "Item_Sidearm_CZ", client);
        menu.AddItem(sInfo, sBuffer);
    }

    Format(sInfo, sizeof(sInfo), "%d|%d", teamIdx, SLOT_HEAVY_PISTOL);
    Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][teamIdx][SLOT_HEAVY_PISTOL] == 0 ? "Item_Heavy_Deagle" : "Item_Heavy_Revolver", client);
    menu.AddItem(sInfo, sBuffer);

    Format(sInfo, sizeof(sInfo), "%d|%d", teamIdx, SLOT_SMG);
    Format(sBuffer, sizeof(sBuffer), "%T", g_iClientLoadout[client][teamIdx][SLOT_SMG] == 0 ? "Item_SMG_MP7" : "Item_SMG_MP5", client);
    menu.AddItem(sInfo, sBuffer);

    menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_Loadout(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[16];
        menu.GetItem(param2, info, sizeof(info));

        char sParts[2][8];
        ExplodeString(info, "|", sParts, 2, 8);

        int teamIdx                             = StringToInt(sParts[0]);
        int slot                                = StringToInt(sParts[1]);

        g_iClientLoadout[param1][teamIdx][slot] = !g_iClientLoadout[param1][teamIdx][slot];

        SaveLoadout(param1);

        CPrintToChat(param1, "%t", "Loadout_Updated");

        OpenLoadoutMenu(param1);
    }
    else if (action == MenuAction_End)
        delete menu;
    return 0;
}
