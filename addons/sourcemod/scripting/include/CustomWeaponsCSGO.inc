#if defined _CustomWeaponsCSGO_included_
  #endinput
#endif
#define _CustomWeaponsCSGO_included_

forward Action CWGO_OnAddAttribute(int client, int weapon, const char[] attrib, const char[] plugin, const char[] value);

native bool CWGO_GiveItemByName(int client, const char[] weaponName);

public SharedPlugin __pl_CustomWeaponsCSGO = {
	name = "CustomWeaponsCSGO",
	file = "CustomWeaponsCSGO.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_customweaponstf_SetNTVOptional()
{
	MarkNativeAsOptional("CWGO_GiveItemByName");
}
#endif
