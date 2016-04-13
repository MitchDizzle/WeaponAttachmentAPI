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

public OnPluginStart() {
	RegConsoleCmd("sm_watest", Command_Test);
}

public Action Command_Test(int client, int args) {
	float apos[3];
	//Should add check to see if the client is holding a knife..
	if(WA_GetAttachmentPos(client, "muzzle_flash", apos)) {
		PrintToServer("%N (%.1f %.1f %.1f)", client, apos[0], apos[1], apos[2]);
		PrintToChat(client, "%N (%.1f %.1f %.1f)", client, apos[0], apos[1], apos[2]);
		TE_SetupSparks(apos, NULL_VECTOR, 5, 5);
	} else {
		PrintToChat(client, "[WA] Unable to get weapon attachment position");
	}
	return Plugin_Handled;
}