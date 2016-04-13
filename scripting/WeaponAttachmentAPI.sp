#include <sdktools>
#pragma semicolon 1

int plyAttachmentEnts[MAXPLAYERS+1] = {-1,...};
int plyLastWeapon[MAXPLAYERS+1] = {-1,...};
char plyLastAttachment[MAXPLAYERS+1][32];
float emptyVector[3];

#define PLUGIN_VERSION              "1.0.0"
public Plugin myinfo = {
	name = "Weapon Attachment API",
	author = "Mitchell",
	description = "Natives for weapon attachments.",
	version = PLUGIN_VERSION,
	url = "http://mtch.tech"
};

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------Plugin Functions
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("WA_GetAttachmentPos", Native_GetAttachmentPos);
	RegPluginLibrary("WeaponAttachmentAPI");
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar("sm_weapon_attachment_api_version", PLUGIN_VERSION, "Weapon Attachment API Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("player_death", Event_Death);
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------OnPluginEnd		(type: Plugin Function)
	Make sure to delete all the attachment point entities.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
public OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			RemoveAttachEnt(i);
		}
	}
}

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------Native_GetAttachmentPos		(type: Native)
	Core function to set the player's skin from another plugin.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
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

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------Event_Death		(type: Event)
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
public Action Event_Death(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client)) {
		RemoveAttachEnt(client);
	}
}

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------Attachment Helper Methods
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
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
		UnparentEntity(aent);
		int wm = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		ParentEntity(aent, wm, attachment);
		TeleportEntity(aent, emptyVector, NULL_VECTOR, NULL_VECTOR);
	}
	plyLastWeapon[client] = weapon;
	strcopy(plyLastAttachment[client], 32, attachment);
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

public SetCvar(char[] scvar, char[] svalue) {
	SetConVarString(FindConVar(scvar), svalue, true);
}

public UnparentEntity(int child) {
	AcceptEntityInput(child, "ClearParent");
}

public ParentEntity(int child, int parent, char[] attachment) {
	SetVariantString("!activator");
	AcceptEntityInput(child, "SetParent", parent, child, 0);
	SetVariantString(attachment);
	AcceptEntityInput(child, "SetParentAttachment", child, child, 0);
}