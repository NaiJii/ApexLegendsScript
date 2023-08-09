






















global function GetTeamFromSquadID
global function GetSquadIDFromTeam


#if DEV
global function PopulateFreelanceDevMenu
global function ClearFreelanceDevMenu
#endif



global enum eTeamCanRespawn
{
	YES,
	NO,
	NO_BECAUSE_IN_COMBAT,
	NO_BECAUSE_ENEMIES_NEARBY,
	NO_BECAUSE_BLEEDOUT_OUT,

	_count
}

const string WAYPOINTTYPE_SQUADHUDTRACKER = "SquadHudTrackerWP"

global const int MAX_SQUADS = 4

































































































































int function GetTeamFromSquadID( int squad )
{
	Assert( (squad >= 0) && (squad < MAX_SQUADS) )
	int teamNum = (TEAM_MULTITEAM_FIRST + squad)
	return teamNum
}

int function GetSquadIDFromTeam( int team )
{
	int squad = (team - TEAM_MULTITEAM_FIRST)
	Assert( (squad >= 0) && (squad < MAX_SQUADS) )
	return squad
}

















































































#if DEV

const string MENUPATH_MAIN = "Freelance"

void function PopulateFreelanceDevMenu()
{
	
	{
		const string MENUPATH_NPC = (MENUPATH_MAIN + "/NPC")

		DevMenu_Alias_DEV( (MENUPATH_NPC + "/Toggle Overlay"), "scriptCmd DEV_NPC_ToggleOverlay()" )
		DevMenu_Alias_DEV( (MENUPATH_NPC + "/Kill All AI"), "scriptCmd DEV_Freelance_KillAllAI()" )

		
		{
			const string MENUPATH_SPAWN = (MENUPATH_NPC + "/Spawn NPC")
			const string FORMAT_SPAWNCMD = "scriptCmd DEV_CrosshairSpawn( %s, %d )"

			const int MAX_TIERS = 1

			foreach( string name, int val in eNPC )
			{
				if ( val >= eNPC._count )
					continue

				for ( int tierIdx = 0; tierIdx < MAX_TIERS; ++tierIdx )
				{
					string tierLabel = ((tierIdx == 0) ? "" : format( " (tier %d)", tierIdx ))
					string label = format( "%s/%s%s", MENUPATH_SPAWN, name, tierLabel )
					string cmd = format( FORMAT_SPAWNCMD, ("eNPC." + name), tierIdx )
					DevMenu_Alias_DEV( label, cmd )
				}
			}
		}
	}

	const string MENUPATH_SKITS = (MENUPATH_MAIN + "/Skits")
	DevMenu_Alias_DEV( (MENUPATH_SKITS + "/Toggle Overlay"), "scriptCmd DEV_Skits_ToggleOverlay()" )
	DevMenu_Alias_DEV( (MENUPATH_SKITS + "/Kill All Skits"), "scriptCmd Sk_KillAllSkits()" )
	DevMenu_Alias_DEV( (MENUPATH_SKITS + "/Dump Report to Console"), "scriptCmd DEV_PrintAllSkits()" )

	const string MENUPATH_SKITEXAMPLES = (MENUPATH_SKITS + "/Examples")
	DevMenu_Alias_DEV( (MENUPATH_SKITEXAMPLES + "/101/Simple"), "scriptCmd LaunchTestSkit_Simple()" )
	DevMenu_Alias_DEV( (MENUPATH_SKITEXAMPLES + "/101/Threads"), "scriptCmd LaunchTestSkit_Threads()" )
	DevMenu_Alias_DEV( (MENUPATH_SKITEXAMPLES + "/101/Flags"), "scriptCmd LaunchTestSkit_Flags()" )
	DevMenu_Alias_DEV( (MENUPATH_SKITEXAMPLES + "/101/LocalData"), "scriptCmd LaunchTestSkit_LocalData()" )
	DevMenu_Alias_DEV( (MENUPATH_SKITEXAMPLES + "/101/NPCs"), "scriptCmd LaunchTestSkit_NPCs()" )
	DevMenu_Alias_DEV( (MENUPATH_SKITEXAMPLES + "/101/Resources"), "scriptCmd LaunchTestSkit_Resources()" )

	const string MENUPATH_RESOURCES = (MENUPATH_MAIN + "/Resources")
	DevMenu_Alias_DEV( (MENUPATH_RESOURCES + "/Dump Report To Console"), "scriptCmd DEV_PrintObjectiveEntsReport( true )" )
	DevMenu_Alias_DEV( (MENUPATH_RESOURCES + "/Toggle Draw Groups"), "scriptCmd DEV_ResourceToggleDrawGroups()" )
	DevMenu_Alias_DEV( (MENUPATH_RESOURCES + "/Toggle Draw Infantry Spawns"), "scriptCmd DEV_ResourceToggleDrawSpawns()" )
	DevMenu_Alias_DEV( (MENUPATH_RESOURCES + "/Toggle Draw Prowler Spawns"), "scriptCmd DEV_ResourceToggleDrawProwlerSpawns()" )
	DevMenu_Alias_DEV( (MENUPATH_RESOURCES + "/Toggle Draw POIs"), "scriptCmd DEV_ResourceToggleDrawPOIs()" )
	DevMenu_Alias_DEV( (MENUPATH_RESOURCES + "/Toggle Draw Text Details"), "scriptCmd DEV_ResourceToggleDrawTextDetails()" )

	const string MENUPATH_ZONES = (MENUPATH_MAIN + "/Map Zones")
	DevMenu_Alias_DEV( (MENUPATH_ZONES + "/Toggle Overlay"), "scriptCmd DEV_MapZone_ToggleOverlay()" )
















	const string[2] OB_NAMES =
	[
		"breachandclear",
		"mistdefend"
	]


	const string MENUPATH_OBJECTIVES = (MENUPATH_MAIN + "/Objectives")
	foreach ( string name in OB_NAMES )
		DevMenu_Alias_DEV( format( MENUPATH_OBJECTIVES + "/Create Near/%s", name ), format( "scriptCmd DEV_LaunchObjective( \"%s\" )", name ) )
	foreach ( string name in OB_NAMES )
		DevMenu_Alias_DEV( format( MENUPATH_OBJECTIVES + "/Create Far/%s", name ), format( "scriptCmd DEV_LaunchObjectiveFarAway( \"%s\" )", name ) )
	DevMenu_Alias_DEV( (MENUPATH_OBJECTIVES + "/Clear All (dev)"), "scriptCmd DEV_ClearAllObjectives()" )

	const string[1] ENC_NAMES =
	[
		"spectrehitsquad",
		
	]
	const string MENUPATH_ENCOUNTERS = (MENUPATH_MAIN + "/Encounters")
	foreach ( string name in ENC_NAMES )
		DevMenu_Alias_DEV( format( MENUPATH_ENCOUNTERS + "/%s", name ), format( "scriptCmd Encounters_LaunchEncounter( \"%s\", [GetPlayerArray()[0]] )", name ) )

}
void function ClearFreelanceDevMenu()
{
	DevMenu_Rm_DEV( MENUPATH_MAIN )
}

#endif


