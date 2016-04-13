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

int sprLaserBeam = -1;

public OnPluginStart() {
	RegConsoleCmd("sm_watest", Command_Test);
	HookEvent("weapon_fire", Event_Fire, EventHookMode_Pre);
}

public OnMapStart() {
	sprLaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action Event_Fire(Event event, const char[] name, bool dontBroadcast) {
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	if(client > 0 || IsPlayerAlive(client)) {
		CreateTimer(0.0, Timer_ShowBeam, GetClientUserId(client));
	}
}
	
public Action Timer_ShowBeam(Handle timer, any userid) {
	int client = GetClientOfUserId(userid);
	float apos[3];
	int knife = GetPlayerWeaponSlot(client, 2);
	int activeWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if( client <= 0 || 
		!IsPlayerAlive(client) || 
		knife == activeWeapon ||
		!WA_GetAttachmentPos(client, "muzzle_flash", apos)) {
		return Plugin_Stop;
	}
	float epos[3];
	TraceEye(client, epos);
	PrintToChat(client, "WeaponPosition: %.1f %.1f %.1f", apos[0], apos[1], apos[2]);
	TE_SetupBeamPoints(epos, apos, sprLaserBeam, 0, 0, 0, 1.0, 2.0, 2.0, 10, 0.0, {255,0,0,255}, 0);
	TE_SendToAll();
	return Plugin_Stop;
}

public Action Command_Test(int client, int args) {
	float apos[3];
	float epos[3];
	//Should add check to see if the client is holding a knife..
	if(WA_GetAttachmentPos(client, "muzzle_flash", apos)) {
		PrintToChat(client, "WeaponPosition: %.1f %.1f %.1f", apos[0], apos[1], apos[2]);
		//GetClientEyePosition(client, epos);
		TraceEye(client, epos);
		TE_SetupBeamPoints(epos, apos, sprLaserBeam, 0, 0, 0, 1.0, 2.0, 2.0, 10, 0.0, {255,0,0,255}, 0);
		TE_SendToAll();
	} else {
		PrintToChat(client, "[WA] Unable to get weapon attachment position");
	}
	return Plugin_Handled;
}


public bool TraceEye(int client, float pos[3]) {
	float vAngles[3];
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(INVALID_HANDLE))
	{
		TR_GetEndPosition(pos, INVALID_HANDLE);
		return true;
	}
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask) {
	return (entity > GetMaxClients() || !entity);
}