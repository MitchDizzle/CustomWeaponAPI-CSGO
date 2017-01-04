#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0-ALPHA"

public Plugin myinfo = {
    name = "Custom Weapons API",
    author = "Mitchell",
    description = "",
    version = PLUGIN_VERSION,
    url = "mtch.tech"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    //CreateNative("ST_ClearTimer", Native_ClearTimer);
    RegPluginLibrary("CustomWeaponsCSGO");
    return APLRes_Success;
}

public void OnPluginStart() {
    CreateConVar("sm_customweaponsapi_version", PLUGIN_VERSION, "Simple Timer Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
    
    CacheWeapons();
    
    RegAdminCmd("sm_recacheweapons", Command_Recache, ADMFLAG_CONFIG);
}

public Action Command_Recache(int client, int args) {
    CacheWeapons();
    ReplyToCommand(client, "Reloaded Custom Weapons Cache");
    return Plugin_Handled;
}

/* Variable storage of the custom weapons */
#define MAXWEAPONS 50
StringMap wpnLookup;
int wpnCount;

//Weapon Characteristics
char wpnClass[MAXWEAPONS][64];
char wpnName[MAXWEAPONS][64];
int wpnBaseIndex[MAXWEAPONS];
int wpnType[MAXWEAPONS]; // 0- Weapon, 1- Item

//Weapon Attributes
#define MAXATTRIB 10
int wpnAttributes[MAXWEAPONS];
char wpnAttrName[MAXWEAPONS][MAXATTRIB][64];
char wpnAttrPlugin[MAXWEAPONS][MAXATTRIB][64];
char wpnAttrValue[MAXWEAPONS][MAXATTRIB][64];

//Temp Variables for parsing weapons
char smcFilePath[PLATFORM_MAX_PATH];
char smcSection[64];

public void CacheWeapons() {
    PrintToServer("Caching Custom Weapons");
    
    if(wpnLookup == null) {
        wpnLookup = new StringMap();
    } else {
        wpnLookup.Clear();
    }
    
    //Search the custom weapons directory to find any configured weapons
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath),"configs/customweapons/");
    DirectoryListing directoryListing = OpenDirectory(sPath, false, NULL_STRING);

    SMCParser smc = new SMCParser();
    smc.OnStart = WeaponSMC_Start;
    smc.OnEnd = WeaponSMC_End;
    smc.OnEnterSection = WeaponSMC_EnterSection;
    smc.OnKeyValue = WeaponSMC_KeyValue;
    SMCError smcError;
    
    char errorState[PLATFORM_MAX_PATH];
    FileType fileType;
    while(directoryListing.GetNext(smcFilePath, sizeof(smcFilePath), fileType)) {
        if(fileType != FileType_File) {
            continue;
        }
        BuildPath(Path_SM, sPath, sizeof(sPath),"configs/customweapons/%s", smcFilePath);
        PrintToServer("Parsing Weapon File: %s", smcFilePath);
        smcError = smc.ParseFile(sPath, _, _);
        if(smcError != SMCError_Okay) {
            smc.GetErrorString(smcError, errorState, sizeof(errorState));
            SetFailState(errorState);
        }
    }
}

public void WeaponSMC_Start(SMCParser smc) {
    strcopy(smcSection, sizeof(smcSection), "");
}

public void WeaponSMC_End(SMCParser smc, bool halted, bool failed) {
    int i = wpnCount;
    PrintToServer("%i : Classname: %s", i, wpnClass[i]);
    PrintToServer("%i : Name: %s", i, wpnName[i]);
    PrintToServer("%i : Base Index: %i", i, wpnBaseIndex[i]);
    PrintToServer("%i : Type: %i", i, wpnType[i]);
    PrintToServer("%i : Attributes: %i", i, wpnAttributes[i]);
    for(int a = 0; a < wpnAttributes[i]; a++) {
        PrintToServer("%i : %i : %s / %s / %s", i, a, wpnAttrName[i][a], wpnAttrPlugin[i][a], wpnAttrValue[i][a]);
    }
    wpnCount++;
}

public SMCResult WeaponSMC_EnterSection(SMCParser smc, const char[] name, bool opt_quotes) {
    if(StrEqual(smcSection, "", false)) {
        strcopy(smcSection, sizeof(smcSection), "main");
        //The first section will be the custom weapon's classname
        strcopy(wpnClass[wpnCount], sizeof(wpnClass[]), name);
        wpnLookup.SetValue(name, wpnCount);
    } else if(StrEqual(smcSection, "attributes", false)) {
        //Entered a sub section of the attributes
        int attribs = wpnAttributes[wpnCount];
        strcopy(wpnAttrName[wpnCount][attribs], sizeof(wpnAttrName[][]), name);
        wpnAttributes[wpnCount]++;
    }

    if(StrEqual(name, "attributes", false) || 
       StrEqual(name, "viewmodelprops", false) || 
       StrEqual(name, "worldmodelprops", false)) {
        strcopy(smcSection, sizeof(smcSection), name);
    }
}

public SMCResult WeaponSMC_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes) {
    if(StrEqual(smcSection, "main", false)) {
        //Normal Properties
        if(StrEqual(key, "name", false)) {
            strcopy(wpnName[wpnCount], sizeof(wpnName[]), value);
        } else if(StrEqual(key, "baseindex", false)) {
            wpnBaseIndex[wpnCount] = StringToInt(value);
        } else if(StrEqual(key, "type", false)) {
            if(StrEqual(key, "item", false)) {
                wpnType[wpnCount] = 1;
            } else {
                wpnType[wpnCount] = 0;
            }
        }
    } else if(StrEqual(smcSection, "attributes", false)) {
        //Attribute Properties
        int attribs = wpnAttributes[wpnCount]-1; //Since we add one when we enter the section, we should subtract one now.
        if(StrEqual(key, "plugin", false)) {
            strcopy(wpnAttrPlugin[wpnCount][attribs], sizeof(wpnAttrPlugin[][]), value);
        } else if(StrEqual(key, "value", false)) {
            strcopy(wpnAttrValue[wpnCount][attribs], sizeof(wpnAttrPlugin[][]), value);
        }
    }
}



