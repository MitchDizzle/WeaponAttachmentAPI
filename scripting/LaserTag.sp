#include <sdktools>
#include <WeaponAttachmentAPI>
#pragma semicolon 1

#define PLUGIN_VERSION              "1.0.0"
public Plugin myinfo = {
	name = "Weapon Attachment API - Test Plugin",
	author = "Mitchell",
	description = "Simple test app for WA-API",
	version = PLUGIN_VERSION,
	url = "http://mtch.tech"
};

Handle hLaserClr;
int sprLaserBeam = -1;
int iLaserColor = 0;

public OnPluginStart() {
	hLaserClr = CreateConVar("sm_walt_color", "0", "Hex color of laserbeam (#RGBA); 0 = Team colored; 1 = Random",  FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(hLaserClr, OnConVarChange);
	AutoExecConfig(true, "LaserTag");
	
	CreateConVar("sm_wa_laser_tag_version", PLUGIN_VERSION, "WA Laser Tag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("bullet_impact", Event_Impact, EventHookMode_Pre);
	
}

public OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue){
	iLaserColor = 0;
	if(strlen(newValue) == 6 || strlen(newValue) == 7 || strlen(newValue) == 1) {
		char tempString[18];
		strcopy(tempString, sizeof(tempString), newValue);
		ReplaceString(tempString, sizeof(tempString), "#", "");
		iLaserColor = StringToInt(tempString, 16);
	}
}


public OnMapStart() {
	sprLaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action Event_Impact(Event event, const char[] name, bool dontBroadcast) {
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	if(client > 0 || IsPlayerAlive(client)) {
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
	TE_SetupBeamPoints(epos, apos, sprLaserBeam, 0, 0, 0, 0.1, 2.0, 2.0, 10, 0.0, color, 0);
	TE_SendToAll();
	return Plugin_Stop;
}

public GetClientColor(int client, int color[4]) {
	if(iLaserColor == 0) {
		int team = GetClientTeam(client);
		if(team == 2) {
			color[0] = 200;
		} else if(team == 3) {
			color[2] = 200;
		} else {
			color[1] = 200;
		}
	} else if(iLaserColor == 1) {
		color[0] = GetRandomInt(12,200);
		color[1] = GetRandomInt(12,200);
		color[2] = GetRandomInt(12,200);
	} else {
		color[0] = ((iLaserColor >> 16) & 0xFF);
		color[1] = ((iLaserColor >> 8)  & 0xFF);
		color[2] = ((iLaserColor >> 0)  & 0xFF);
	}
}