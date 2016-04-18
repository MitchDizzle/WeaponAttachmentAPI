#include <sdktools>
#include <WeaponAttachmentAPI>
#pragma semicolon 1

#define PLUGIN_VERSION              "1.1.0"
public Plugin myinfo = {
	name = "WA Weapon Lasers",
	author = "Mitchell",
	description = "A Simple plugin that shows lasers out of player's guns.",
	version = PLUGIN_VERSION,
	url = "http://mtch.tech"
};

int sprLaserBeam = -1;

ConVar hLaserClr;
ConVar hLaserClrT;
ConVar hLaserClrCT;
ConVar hLaserWidth;
ConVar hLaserEndWidth;
ConVar hLaserRndrAmt;
ConVar hLaserView;
int iLaserColorType = 0;
int iLaserColor[4] = {12, 255, 12, 255};
int iLaserColorT[4] = {255, 12, 12, 255};
int iLaserColorCT[4] = {12, 12, 255, 255};
float fLaserWidth = 2.0;
float fLaserEndWidth = 2.0;
int iLaserRndrAmt = 200;
int iLaserView = 0;

int plyArray[2][MAXPLAYERS+1];
int plyArrayCnt[2];

public OnPluginStart() {
	hLaserClr = CreateConVar("sm_walt_color", "0", "Hex color of laserbeam (#RGBA); 0 = Team colored; 1 = Random",  FCVAR_PLUGIN);
	hLaserClrT = CreateConVar("sm_walt_color_t", "FF0C0C", "Hex color of t laserbeam (#RGBA)",  FCVAR_PLUGIN);
	hLaserClrCT = CreateConVar("sm_walt_color_ct", "0C0CFF", "Hex color of ct laserbeam (#RGBA)",  FCVAR_PLUGIN);
	hLaserWidth = CreateConVar("sm_walt_width", "2.0", "Width of the laser beam",  FCVAR_PLUGIN);
	hLaserEndWidth = CreateConVar("sm_walt_endwidth", "2.0", "End Width of the laser beam",  FCVAR_PLUGIN);
	hLaserRndrAmt = CreateConVar("sm_walt_renderamt", "200", "Render amount of the laser beam",  FCVAR_PLUGIN);
	hLaserView = CreateConVar("sm_walt_view", "0", "Who can see the beam; 0 = All, 1 = User-only, 2 = Enemies, 3 = Teammates",  FCVAR_PLUGIN);
	HookConVarChange(hLaserClr, OnConVarChange);
	HookConVarChange(hLaserClrT, OnConVarChange);
	HookConVarChange(hLaserClrCT, OnConVarChange);
	HookConVarChange(hLaserWidth, OnConVarChange);
	HookConVarChange(hLaserEndWidth, OnConVarChange);
	HookConVarChange(hLaserRndrAmt, OnConVarChange);
	HookConVarChange(hLaserView, OnConVarChange);
	AutoExecConfig(true, "WeaponLasers");

	CreateConVar("sm_wa_weapon_lasers_version", PLUGIN_VERSION, "WA Laser Tag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("bullet_impact", Event_Impact, EventHookMode_Pre);
	HookEvent("player_team", Event_Recalc);
	//HookEvent("round_start", Event_Recalc);
	HookEvent("round_freeze_end", Event_Recalc);

	calcPlayerArrays();
}

public OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue){
	if(convar == hLaserClr || convar == hLaserClrT || convar == hLaserClrCT) {
		if(strlen(newValue) == 6 || strlen(newValue) == 7 || strlen(newValue) == 1) {
			char tempString[18];
			strcopy(tempString, sizeof(tempString), newValue);
			ReplaceString(tempString, sizeof(tempString), "#", "");
			int tempInt = StringToInt(tempString, 16);
			int color[4] = {12,255,12,255};
			color[0] = ((tempInt >> 16) & 0xFF);
			color[1] = ((tempInt >> 8)  & 0xFF);
			color[2] = ((tempInt >> 0)  & 0xFF);
			if(convar == hLaserClr) {
				iLaserColor = color;
			} else if(convar == hLaserClrT) {
				iLaserColorT = color;
			} else if(convar == hLaserClrCT) {
				iLaserColorCT = color;
			}
		}
	} else if(convar == hLaserWidth) {
		fLaserWidth = StringToFloat(newValue);
	} else if(convar == hLaserEndWidth) {
		fLaserEndWidth = StringToFloat(newValue);
	} else if(convar == hLaserRndrAmt) {
		iLaserRndrAmt = StringToInt(newValue);
	} else if(convar == hLaserView) {
		iLaserView = StringToInt(newValue);
		calcPlayerArrays();
	}
}

public OnMapStart() {
	sprLaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
public Action Event_Impact(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && iLaserRndrAmt >= 0) {
		DataPack dp = new DataPack(); 
		CreateDataTimer(0.0, Timer_ShowBeam, dp, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		dp.WriteCell(GetClientUserId(client));
		dp.WriteFloat(GetEventFloat(event, "x"));
		dp.WriteFloat(GetEventFloat(event, "y"));
		dp.WriteFloat(GetEventFloat(event, "z"));
	}
}
	
public Action Timer_ShowBeam(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = GetClientOfUserId(ReadPackCell(dp));
	float epos[3];
	epos[0] = ReadPackFloat(dp);
	epos[1] = ReadPackFloat(dp);
	epos[2] = ReadPackFloat(dp);
	float apos[3];
	int knife = GetPlayerWeaponSlot(client, 2);
	int activeWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if( client <= 0 || 
		!IsPlayerAlive(client) || 
		knife == activeWeapon ||
		!WA_GetAttachmentPos(client, "muzzle_flash", apos)) {
		return Plugin_Stop;
	}
	int color[4] = {12,12,12,255};
	GetClientColor(client, color);
	TE_SetupBeamPoints(epos, apos, sprLaserBeam, 0, 0, 0, 0.1, fLaserEndWidth, fLaserWidth, 10, 0.0, color, 0);
	if(iLaserView == 0) {
		//Putting this one first because it's the default value, and commonly used.
		TE_SendToAll();
	} else if(iLaserView == 3) {
		int t = GetClientTeam(client)-2;
		if(t >= 0) {
			TE_Send(plyArray[t], plyArrayCnt[t]);
		}
	} else if(iLaserView == 2) {
		int t = GetClientTeam(client)-2;
		if(t == 0) {
			TE_Send(plyArray[1], plyArrayCnt[1]);
		} else {
			TE_Send(plyArray[0], plyArrayCnt[0]);
		}
	} else if(iLaserView == 1) {
		TE_SendToClient(client);
	}
	return Plugin_Stop;
}

public GetClientColor(int client, int color[4]) {
	if(iLaserColorType == 0) {
		int team = GetClientTeam(client);
		if(team == 2) {
			color = iLaserColorT;
		} else if(team == 3) {
			color = iLaserColorCT;
		} else {
			color[1] = 200;
		}
	} else if(iLaserColorType == 1) {
		color[0] = GetRandomInt(12,200);
		color[1] = GetRandomInt(12,200);
		color[2] = GetRandomInt(12,200);
	} else {
		color = iLaserColor;
	}
	color[3] = iLaserRndrAmt;
}

public Action Event_Recalc(Event event, const char[] name, bool dontBroadcast) {
	calcPlayerArrays();
}

public calcPlayerArrays() {
	if(iLaserView < 2) return;
	plyArrayCnt[0] = 0;
	plyArrayCnt[1] = 0;
	int t = -1;
	for(int i=1; i < MAXPLAYERS; i++) {
		if(IsClientInGame(i)) {
			t = GetClientTeam(i)-2;
			if(t >= 0) {
				plyArray[t][plyArrayCnt[t]++] = i;
			}
		}
	}
}