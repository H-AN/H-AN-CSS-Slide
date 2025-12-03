#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <HanAnimeAPI>
#include <HanSlideAPI>

public Plugin myinfo =
{
    name = "CS起源滑铲",
    author = "H-AN",
    description = "CS起源的滑铲插件,带API",
    version = "2.2",
    url = "https://github.com/H-AN"
};

bool IgnoreNextDuck[MAXPLAYERS+1];
bool ForcedDuck[MAXPLAYERS+1];
bool IsSliding[MAXPLAYERS+1];

int SavedAddonBits[MAXPLAYERS+1];
int SavedPrimaryAddon[MAXPLAYERS+1];
int SavedSecondaryAddon[MAXPLAYERS+1];
bool HasSavedAddon[MAXPLAYERS+1];

//bool IsPredict[MAXPLAYERS+1];

GlobalForward g_ForwardSlideOnStart;
GlobalForward g_ForwardSlideOnEnd;

bool IsInThirdPerson[MAXPLAYERS+1];

enum struct Config
{
    ConVar enable;
    ConVar SlideForce;
    ConVar SpeedScale;
    ConVar MaxSpeed;
    ConVar AirSlide;
    ConVar SlideJump;
    ConVar SlideJumpForce;
    ConVar SlideMixSpeed;
    ConVar FirstPersonHideWeapon;
}
Config g_SlideConfig;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("Han_SetPlayerSlide", Native_SetPlayerSlide);
    CreateNative("Han_IsSliding", Native_IsSliding);
    g_ForwardSlideOnStart = new GlobalForward("Han_SlideOnStart", ET_Ignore, Param_Cell);
    g_ForwardSlideOnEnd = new GlobalForward("Han_SlideOnEnd", ET_Ignore, Param_Cell);
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_SlideConfig.enable = CreateConVar("sliding_enable", "1", "是否开启插件独立使用滑铲 默认开启");
    g_SlideConfig.SlideForce = CreateConVar("sliding_slideforce", "500.0", "滑铲基础力");
    g_SlideConfig.SpeedScale = CreateConVar("sliding_speedscale", "1.0", "玩家移动速度倍率");
    g_SlideConfig.MaxSpeed = CreateConVar("sliding_maxspeed", "0.0", "最大力度限制 0为不限制");
    g_SlideConfig.AirSlide = CreateConVar("sliding_airslide", "0", "是否允许在空中的时候滑铲");
    g_SlideConfig.SlideJump = CreateConVar("sliding_slidejump", "1", "是否开启滑铲跳");
    g_SlideConfig.SlideJumpForce = CreateConVar("sliding_slidejumpforce", "500.0", "滑铲跳增加力");
    g_SlideConfig.SlideMixSpeed = CreateConVar("sliding_slidemixspeed", "100.0", "触发滑铲的最小速度");
    g_SlideConfig.FirstPersonHideWeapon = CreateConVar("sliding_firstpersonhideweapon", "1", "第人称是否隐藏模型武器");

    RegConsoleCmd("thirdperson", ThirdPerson, "第三人称");
    RegConsoleCmd("firstperson", FirstPerson, "第一人称");
}

public Action ThirdPerson(int client, int args)
{
    if(client <= 0)
       client = 1;
    IsInThirdPerson[client] = true;

    return Plugin_Continue;
}
public Action FirstPerson(int client, int args)
{
    if(client <= 0)
       client = 1;
    IsInThirdPerson[client] = false;

    return Plugin_Continue;
}




public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}


public void OnPostThinkPost(int client)
{
    ForceEndSlide(client);
	if(IsSliding[client])
    {
        OnSlideStart(client);
    }
    else
    {
        OnSlideEnd(client);
    }
    /*
    if(GetConVarBool(g_SlideConfig.FirstPersonHideWeapon))
    {
        QueryClientConVar(client, "sv_client_predict", ConVarQueryFinished:ClientConVar, client);
    }
    */

}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if(!IsValidClient(client) && !IsPlayerAlive(client))
        return Plugin_Continue;

    if (IsSliding[client])
    {
        vel[0] = 0.0;
        vel[1] = 0.0;
        if(buttons & IN_JUMP)
        {
            if(GetConVarBool(g_SlideConfig.SlideJump))
            {
                SlideJump(client);
            }
            else
            {
                buttons &= ~IN_JUMP;
            }
        }
        return Plugin_Continue;
    }

    if (IgnoreNextDuck[client])
    {
        if (!(buttons & IN_DUCK))
        {
            IgnoreNextDuck[client] = false;
        }

        return Plugin_Continue;
    }

    if (buttons & IN_DUCK)
    {
        if(!GetConVarBool(g_SlideConfig.enable))
            return Plugin_Continue;

        if(!(GetEntityFlags(client) & FL_ONGROUND) && !GetConVarBool(g_SlideConfig.AirSlide))
            return Plugin_Continue;

        float vSpeed[3];
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", vSpeed);
        float horizontal = SquareRoot(vSpeed[0]*vSpeed[0] + vSpeed[1]*vSpeed[1]);
        float MixSpeed  = GetConVarFloat(g_SlideConfig.SlideMixSpeed);
        if(horizontal < MixSpeed)
            return Plugin_Continue;

        Slide(client);
    }

    return Plugin_Continue;
}

void Slide(int client)
{
    IsSliding[client] = true;
        
    float vangles[3] = {0.0, 90.0, 0.0};
    
    if(GetConVarBool(g_SlideConfig.FirstPersonHideWeapon))
    {
        /*
        if(!IsPredict[client]) //检查到非预测 第三人称已开启
        {
            Han_SetPlayerAnime(client, "huachanunhide", 1.5, vangles, true, true, false);
        }
        else //检查到预测 回到第一人称
        {
            Han_SetPlayerAnime(client, "huachanunhide", 1.5, vangles, true, false, false);
        }
        */
        if(IsInThirdPerson[client]) //第三人称已开启
        {
            Han_SetPlayerAnime(client, "huachanunhide", 1.5, vangles, true, true, false);
        }
        else
        {
            Han_SetPlayerAnime(client, "huachanunhide", 1.5, vangles, true, false, false);
        }
    }
    else
    {
        Han_SetPlayerAnime(client, "huachanunhide", 1.5, vangles, true, true, false);
    }
    PushSelf(client);

    Call_StartForward(g_ForwardSlideOnStart);
    Call_PushCell(client);
    Call_Finish();

    ForcedDuck[client] = true;
    ClientCommand(client, "+duck");
    CreateTimer(1.5, ResSlideTimer, client);

}

/*
public ClientConVar(QueryCookie cookie, client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if(StrEqual(cvarValue, "0"))
    {
        IsPredict[client] = false;
    }
    else if(StrEqual(cvarValue, "1") ||StrEqual(cvarValue, "-1") )
    {
        IsPredict[client] = true;
    }
    else
    {
        IsPredict[client] = true;
    }
} 
*/
void SlideJump(int client)
{
    if(!(GetEntityFlags(client) & FL_ONGROUND))
        return;

    ResSlide(client);
    Han_KillAnime(client);

    float SlideJumpForce = GetConVarFloat(g_SlideConfig.SlideJumpForce);

    float ang[3], forwards[3];
    GetClientEyeAngles(client, ang);
    GetAngleVectors(ang, forwards, NULL_VECTOR, NULL_VECTOR);

    forwards[2] = 0.0;
    NormalizeVector(forwards, forwards);

    ScaleVector(forwards, SlideJumpForce);

    forwards[2] = SlideJumpForce;

    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, forwards);
}

void ForceEndSlide(int client)
{
    float vSpeed[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vSpeed);
    float horizontal = SquareRoot(vSpeed[0]*vSpeed[0] + vSpeed[1]*vSpeed[1]);
    if(IsSliding[client] && horizontal == 0.0)
    {
        ResSlide(client);
        Han_KillAnime(client);
    }
}

void ResSlide(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    IsSliding[client] = false;

    if (ForcedDuck[client])
    {
        ForcedDuck[client] = false;
        ClientCommand(client, "-duck");
    }
    IgnoreNextDuck[client] = true;

    Call_StartForward(g_ForwardSlideOnEnd);
    Call_PushCell(client);
    Call_Finish();
}


public Action ResSlideTimer(Handle timer, any client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) 
        return Plugin_Stop;

    if (!IsSliding[client]) 
        return Plugin_Stop;

    ResSlide(client);

    return Plugin_Stop;
}


void PushSelf(int client)
{
    float vAng[3], vDir[3], vVel[3], curVel[3];

    GetClientEyeAngles(client, vAng);
    GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);

    vDir[2] = 0.0;               // 保持贴地
    NormalizeVector(vDir, vDir);

    float vSpeed[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vSpeed);

    // 只取水平速度
    float horizontal = SquareRoot(vSpeed[0]*vSpeed[0] + vSpeed[1]*vSpeed[1]);

    float baseForce = GetConVarFloat(g_SlideConfig.SlideForce);
    float scale = GetConVarFloat(g_SlideConfig.SpeedScale);

    float slideForce = baseForce + (horizontal * scale);  

    // 限制最大滑铲力度
    float maxSlide = GetConVarFloat(g_SlideConfig.MaxSpeed);
    if (maxSlide > 0.0 && slideForce > maxSlide)
    {
        slideForce = maxSlide;
    }
    
    ScaleVector(vDir, slideForce);

    GetEntPropVector(client, Prop_Data, "m_vecVelocity", curVel);
    AddVectors(curVel, vDir, vVel);

    vVel[2] = curVel[2]; // 保持垂直速度
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
}


void OnSlideStart(int client)
{
    if (!HasSavedAddon[client])
    {
        SavedAddonBits[client] = GetEntProp(client, Prop_Send, "m_iAddonBits");
        SavedPrimaryAddon[client] = GetEntProp(client, Prop_Send, "m_iPrimaryAddon");
        SavedSecondaryAddon[client] = GetEntProp(client, Prop_Send, "m_iSecondaryAddon");

        HasSavedAddon[client] = true;
    }

    SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
    SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 0);
    SetEntProp(client, Prop_Send, "m_iSecondaryAddon", 0);
}

void OnSlideEnd(int client)
{
    if (HasSavedAddon[client])
    {
        SetEntProp(client, Prop_Send, "m_iAddonBits", SavedAddonBits[client]);
        SetEntProp(client, Prop_Send, "m_iPrimaryAddon", SavedPrimaryAddon[client]);
        SetEntProp(client, Prop_Send, "m_iSecondaryAddon", SavedSecondaryAddon[client]);

        HasSavedAddon[client] = false;
    }
}

public int Native_SetPlayerSlide(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    Slide(client);
    return 1;
}


public int Native_IsSliding(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (!IsValidClient(client))
        return 0;

    return IsSliding[client] ? 1 : 0;
}

stock bool IsValidClient(client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

public OnClientDisconnect(int client) 
{
    IgnoreNextDuck[client] = false;
    ForcedDuck[client] = false;
    IsSliding[client] = false;

    SavedAddonBits[client] = 0;
    SavedPrimaryAddon[client] = 0;
    SavedSecondaryAddon[client] = 0;
    HasSavedAddon[client] = false;
    //IsPredict[client] = false;
    IsInThirdPerson[client] = false;
}