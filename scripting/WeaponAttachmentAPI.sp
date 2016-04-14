#include <sdktools>
#pragma semicolon 1

int plyAttachmentEnts[MAXPLAYERS+1] = {-1,...};
int plyLastWeapon[MAXPLAYERS+1] = {-1,...};
char plyLastAttachment[MAXPLAYERS+1][32];
float emptyVector[3];
EngineVersion EVGame;
#define PLUGIN_VERSION              "1.0.2"
public Plugin myinfo = {
	name = "Weapon Attachment API",
	author = "Mitchell",
	description = "Natives for weapon attachments.",
	version = PLUGIN_VERSION,
	url = "http://mtch.tech"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("WA_GetAttachmentPos", Native_GetAttachmentPos);
	RegPluginLibrary("WeaponAttachmentAPI");
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar("sm_weapon_attachment_api_version", PLUGIN_VERSION, "Weapon Attachment API Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	EVGame = GetEngineVersion();
	HookEvent("player_death", Event_Death);
}

public OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			RemoveAttachEnt(i);
		}
	}
}

public Native_GetAttachmentPos(Handle plugin, args) {
	int client = GetNativeCell(1);
	bool result = false;
	if(NativeCheck_IsClientValid(client) && IsPlayerAlive(client)) {
		char attachment[32];
		GetNativeString(2, attachment, 32);
		float pos[3];
		result = GetAttachmentPosition(client, attachment, pos);
		SetNativeArray(3, pos, 3);
	}
	return result;
}
//Do we even really need to remove the entity on death?
public Action Event_Death(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client)) {
		RemoveAttachEnt(client);
	}
}

public bool GetAttachmentPosition(client, char[] attachment, float epos[3]) {
	if(StrEqual(attachment, "")) {
		return false;
	}
	int aent = GetAttachmentEnt(client);
	if(aent == INVALID_ENT_REFERENCE) {
		aent = EntIndexToEntRef(CreateAttachmentEnt(client));
		if(!IsValidEntity(aent)) {
			return false;
		}
		plyAttachmentEnts[client] = aent;
	}
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(plyLastWeapon[client] != weapon || !StrEqual(attachment, plyLastAttachment[client], false)) {
		//The position is different, need to relocate the entity.
		plyLastWeapon[client] = weapon;
		strcopy(plyLastAttachment[client], 32, attachment);
		AcceptEntityInput(aent, "ClearParent");
		if(EVGame == Engine_CSGO) weapon = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		SetVariantString("!activator");
		AcceptEntityInput(aent, "SetParent", weapon, aent, 0);
		SetVariantString(attachment);
		AcceptEntityInput(aent, "SetParentAttachment", aent, aent, 0);
		TeleportEntity(aent, emptyVector, NULL_VECTOR, NULL_VECTOR);
	}
	GetEntPropVector(aent, Prop_Data, "m_vecAbsOrigin", epos);
	return true;
}

public GetAttachmentEnt(int client) {
	if(IsValidEntity(plyAttachmentEnts[client])) {
		return plyAttachmentEnts[client];
	}
	return INVALID_ENT_REFERENCE;
}

public CreateAttachmentEnt(int client) {
	RemoveAttachEnt(client);
	int aent = CreateEntityByName("info_target");
	DispatchSpawn(aent);
	plyLastWeapon[client] = INVALID_ENT_REFERENCE;
	plyLastAttachment[client] = "";
	return aent;
}

public RemoveAttachEnt(int client) {
	if(IsValidEntity(plyAttachmentEnts[client])) {
		AcceptEntityInput(plyAttachmentEnts[client], "Kill");
	}
	plyAttachmentEnts[client] = INVALID_ENT_REFERENCE;
	plyLastWeapon[client] = INVALID_ENT_REFERENCE;
	plyLastAttachment[client] = "";
}

public NativeCheck_IsClientValid(int client) {
	if (client <= 0 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is invalid", client);
	}
	if (!IsClientInGame(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not in game", client);
	}
	return true;
}