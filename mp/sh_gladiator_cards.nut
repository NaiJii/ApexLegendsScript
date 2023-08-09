global function ShGladiatorCards_LevelInit


global function ShGladiatorCards_Init
global function ShGladiatorCards_LevelShutdown


























global function GetBadgeData
global function CreateNestedGladiatorCardBadge



global function SetupMenuGladCard

global function SetupMenuGladCardRTK

global function SendMenuGladCardPreviewCommand
global function SendMenuGladCardPreviewString

























global function Loadout_GladiatorCardFrame
global function Loadout_GladiatorCardStance
global function Loadout_GladiatorCardBadge
global function Loadout_GladiatorCardBadgeTier
global function Loadout_GladiatorCardStatTracker
global function Loadout_GladiatorCardStatTrackerValue
global function GladiatorCardFrame_GetSortOrdinal
global function GladiatorCardFrame_GetCharacterFlavor
global function GladiatorCardFrame_HasStoryBlurb
global function GladiatorCardFrame_GetStoryBlurbBodyText
global function GladiatorCardFrame_ShouldHideIfLocked
global function GladiatorCardFrame_IsSharedBetweenCharacters
global function GladiatorCardStance_GetSortOrdinal
global function GladiatorCardStance_GetCharacterFlavor
global function GladiatorCardBadge_GetSortOrdinal
global function GladiatorCardBadge_GetCharacterFlavor
global function GladiatorCardBadge_GetUnlockStatRef
global function GladiatorCardBadge_IsGeneralStat
global function GladiatorCardBadge_GetStatInt
global function GladiatorCardBadge_IsValidStatRef
global function GladiatorCardStatTracker_GetSortOrdinal
global function GladiatorCardStatTracker_GetCharacterFlavor
global function GladiatorCardStatTracker_GetFormattedValueText
global function GladiatorCardStatTracker_IsSharedBetweenCharacters
global function GladiatorCardBadge_ShouldHideIfLocked
global function GladiatorCardBadge_IsTheEmpty
global function GladiatorCardTracker_IsTheEmpty
global function GladiatorCardBadge_IsCharacterBadge
global function GladiatorCardBadge_GetTierCount
global function GladiatorCardBadge_GetTierData
global function GladiatorCardBadge_GetTierDataList
global function GetPlayerBadgeDataInteger


global function GladiatorCardStatTracker_GetColor0
global function GladiatorCardBadge_DoesStatSatisfyValue









global const int GLADIATOR_CARDS_NUM_BADGES = 3
global const int GLADIATOR_CARDS_NUM_TRACKERS = 3

global const int GLADIATOR_CARDS_NUM_FRAME_KEY_COLORS = 3

const bool GLADCARD_CC_DEBUG_PRINTS_ENABLED = false








global enum eGladCardPresentation
{
	OFF,

	_MARK_FRONT_START,
	FRONT_DETAILS,
	PROTO_FRONT_DETAILS_NO_BADGES,
	FRONT_CLEAN,
	FRONT_STANCE_ONLY,
	FRONT_FRAME_ONLY,

	_MARK_BACK_START,
	FULL_BOX,
	_MARK_FRONT_END,

	BACK,
	_MARK_BACK_END,
}

global enum eGladCardDisplaySituation
{
	
	
	_INVALID, 

	DEATH_BOX_STILL,
	APEX_SCREEN_STILL,
	SPECTATE_ANIMATED,
	GAME_INTRO_CHAMPION_SQUAD_ANIMATED,
	GAME_INTRO_CHAMPION_SQUAD_STILL,
	GAME_INTRO_MY_SQUAD_ANIMATED,
	GAME_INTRO_MY_SQUAD_STILL,
	WEAPON_INSPECT_OVERLAY_ANIMATED,
	DEATH_OVERLAY_ANIMATED,
	SQUAD_MANAGEMENT_PAGE_ANIMATED,
	EOG_SCREEN_LOCAL_SQUAD_ANIMATED,
	EOG_SCREEN_WINNING_SQUAD_ANIMATED,

	
	MENU_CUSTOMIZE_ANIMATED,
	MENU_LOOT_CEREMONY_ANIMATED,

	
	DEV_ANIMATED,

	_COUNT, 
}

table<int, bool> eGladCardDisplaySituation_IS_MOVING = {
	[eGladCardDisplaySituation.DEATH_BOX_STILL] = false,
	[eGladCardDisplaySituation.APEX_SCREEN_STILL] = false,
	[eGladCardDisplaySituation.SPECTATE_ANIMATED] = true,
	[eGladCardDisplaySituation.GAME_INTRO_CHAMPION_SQUAD_ANIMATED] = true,
	[eGladCardDisplaySituation.GAME_INTRO_CHAMPION_SQUAD_STILL] = false,
	[eGladCardDisplaySituation.GAME_INTRO_MY_SQUAD_ANIMATED] = true,
	[eGladCardDisplaySituation.GAME_INTRO_MY_SQUAD_STILL] = false,
	[eGladCardDisplaySituation.DEATH_OVERLAY_ANIMATED] = true,
	[eGladCardDisplaySituation.SQUAD_MANAGEMENT_PAGE_ANIMATED] = true,
	[eGladCardDisplaySituation.EOG_SCREEN_LOCAL_SQUAD_ANIMATED] = true,
	[eGladCardDisplaySituation.EOG_SCREEN_WINNING_SQUAD_ANIMATED] = true,
	[eGladCardDisplaySituation.MENU_CUSTOMIZE_ANIMATED] = true,
	[eGladCardDisplaySituation.MENU_LOOT_CEREMONY_ANIMATED] = true,
	[eGladCardDisplaySituation.DEV_ANIMATED] = true,
}

global enum eGladCardLifestateOverride
{
	NONE = 0, 
	ALIVE = 1,
	DEAD = 2,
}

global enum eGladCardPreviewCommandType
{
	CHARACTER,
	SKIN,
	FRAME,
	STANCE,
	BADGE,
	TRACKER,
	RANKED_SHOULD_SHOW,
	RANKED_DATA,

		ARENAS_RANKED_SHOULD_SHOW,
		ARENAS_RANKED_DATA,

	NAME,
	RANKED_DATA_PREV,
	MELEE_SKIN,
}




















































































































global struct GladCardBadgeTierData
{
	float unlocksAt
	asset ruiAsset = $""
	asset imageAsset = $""
	bool  isUnlocked = true
}



global struct GladCardBadgeDisplayData
{
	asset ruiAsset = $""
	asset imageAsset = $""
	int   dataInteger = -1 
}














struct FileStruct_LifetimeLevel
{
	table<ItemFlavor, LoadoutEntry>             loadoutCharacterFrameSlotMap
	table<ItemFlavor, LoadoutEntry>             loadoutCharacterStanceSlotMap
	table<ItemFlavor, array<LoadoutEntry> >     loadoutCharacterBadgesSlotListMap
	table<ItemFlavor, array<LoadoutEntry> >     loadoutCharacterBadgesTierSlotListMap
	table<ItemFlavor, array<LoadoutEntry> >     loadoutCharacterTrackersSlotListMap
	table<ItemFlavor, array<LoadoutEntry> >     loadoutCharacterTrackersValueSlotListMap

	table<ItemFlavor, int> cosmeticFlavorSortOrdinalMap

	var currentMenuGladCardPanel



		string currentMenuGladCardArgName























}
FileStruct_LifetimeLevel& fileLevel











void function ShGladiatorCards_Init()
{
	AddUICallback_UIShutdown( ShGladiatorCards_UIShutdown )
}


void function ShGladiatorCards_LevelInit()
{
	FileStruct_LifetimeLevel newFileLevel
	fileLevel = newFileLevel




















	AddCallback_OnItemFlavorRegistered( eItemType.character, OnItemFlavorRegistered_Character )





}



void function ShGladiatorCards_LevelShutdown()
{
	if ( fileLevel.currentMenuGladCardPanel != null )
	{

		if ( typeof( fileLevel.currentMenuGladCardPanel ) == "rtk_panel" )
			RuiDestroyNestedIfAlive( RTKPanel_GetPersistentRui( expect rtk_panel( fileLevel.currentMenuGladCardPanel ) ), fileLevel.currentMenuGladCardArgName )
		else

			RuiDestroyNestedIfAlive( Hud_GetRui( fileLevel.currentMenuGladCardPanel ), fileLevel.currentMenuGladCardArgName )
		fileLevel.currentMenuGladCardPanel = null
		fileLevel.currentMenuGladCardArgName = ""
	}
}

































































































































































































































GladCardBadgeDisplayData function GetBadgeData( EHI playerEHI, ItemFlavor ornull character, int badgeIndex, ItemFlavor badge, int ornull overrideDataIntegerOrNull, bool showOneTierHigherThanIsUnlocked = false )
{
	GladCardBadgeDisplayData badgeData

	if ( overrideDataIntegerOrNull != null )
		badgeData.dataInteger = expect int(overrideDataIntegerOrNull)
	else
		badgeData.dataInteger = GetPlayerBadgeDataInteger( playerEHI, badge, badgeIndex, character, showOneTierHigherThanIsUnlocked )

	if ( badgeData.dataInteger == -1 ) 
		badgeData.dataInteger = 0

	int tierIndex = badgeData.dataInteger
	if ( GladiatorCardBadge_GetDynamicTextStatRef( badge ) != "" )
		tierIndex = 0 

	
	if ( string(ItemFlavor_GetAsset( badge )) == ACCOUNT_BADGE_ASSET_PATH_STRING )
	{
		if ( badgeData.dataInteger <= ACCOUNT_LEVEL_RUI_SWITCH_0_BASE || GetCurrentPlaylistVarInt( "account_progression_version", 3 ) == 2 )
			badgeData.ruiAsset = $"ui/gcard_badge_account_t1.rpak"
		else
			badgeData.ruiAsset = $"ui/gcard_badge_account_p1.rpak"

		return badgeData
	}

	
	array<GladCardBadgeTierData> tierDataList = GladiatorCardBadge_GetTierDataList( badge )
	if ( ItemFlavor_GetGRXMode( badge ) == eItemFlavorGRXMode.REGULAR && !tierDataList.isvalidindex( tierIndex ) )
		tierIndex = 0

	if ( tierDataList.isvalidindex( tierIndex ) )
	{
		if ( GladiatorCardBadge_HasOwnRUI( badge ) )
		{
			badgeData.ruiAsset = tierDataList[tierIndex].ruiAsset
		}
		else
		{
			if ( GladiatorCardBadge_IsOversizedImage( badge ) )
				badgeData.ruiAsset = $"ui/gcard_badge_oversized.rpak"
			else
				badgeData.ruiAsset = $"ui/gcard_badge_basic.rpak"

			badgeData.imageAsset = tierDataList[tierIndex].imageAsset
		}
	}

	return badgeData
}




var function CreateNestedGladiatorCardBadge( var parentRui, string argName, EHI playerEHI, ItemFlavor badge, int badgeIndex, ItemFlavor ornull character = null, int ornull overrideDataIntegerOrNull = null, bool showOneTierHigherThanIsUnlocked = false )
{
	GladCardBadgeDisplayData gcbdd = GetBadgeData( playerEHI, character, badgeIndex, badge, overrideDataIntegerOrNull, showOneTierHigherThanIsUnlocked )

	if ( gcbdd.ruiAsset == $"" )
	{
		gcbdd.ruiAsset = $"ui/gcard_badge_basic.rpak" 
		gcbdd.imageAsset = $"rui/gladiator_cards/badge_empty"
	}

	var nestedRui = RuiCreateNested( parentRui, argName, gcbdd.ruiAsset )

	RuiSetInt( nestedRui, "tier", gcbdd.dataInteger )
	if ( gcbdd.imageAsset != $"" )
		RuiSetImage( nestedRui, "img", gcbdd.imageAsset )

	return nestedRui
}
























































































void function SetupMenuGladCard( var panel, string argName, bool isForLocalPlayer )
{
	fileLevel.currentMenuGladCardPanel = panel
	fileLevel.currentMenuGladCardArgName = argName
	RunClientScript( "UIToClient_SetupMenuGladCard", panel, argName, isForLocalPlayer, false )
}


void function SetupMenuGladCardRTK( rtk_panel panel, string argName, bool isForLocalPlayer )
{
	fileLevel.currentMenuGladCardPanel = panel
	fileLevel.currentMenuGladCardArgName = argName
	if ( CanRunClientScript() )
		RunClientScript( "UIToClient_SetupMenuGladCardRTK", panel, argName, isForLocalPlayer, false )
	else
		printl( "Can't show RTK gladiator card without the client VM!" )
}






void function SendMenuGladCardPreviewCommand( int previewType, int index, ItemFlavor ornull flavOrNull, int dataInteger = -1 )
{
	Assert( CanRunClientScript() )
	Assert( fileLevel.currentMenuGladCardPanel != null )
	Assert( fileLevel.currentMenuGladCardArgName != "" )
	int guid = 0
	if ( flavOrNull != null )
		guid = ItemFlavor_GetGUID( expect ItemFlavor(flavOrNull) )
	RunClientScript( "UIToClient_HandleMenuGladCardPreviewCommand", previewType, index, guid, dataInteger )
}



void function SendMenuGladCardPreviewString( int previewType, int index, string previewName )
{
	Assert( CanRunClientScript() )
	Assert( fileLevel.currentMenuGladCardPanel != null )
	Assert( fileLevel.currentMenuGladCardArgName != "" )
	RunClientScript( "UIToClient_HandleMenuGladCardPreviewString", previewType, index, previewName )
}




void function ShGladiatorCards_UIShutdown()
{
	if ( CanRunClientScript() )
	{
		
		fileLevel.currentMenuGladCardPanel = null
		fileLevel.currentMenuGladCardArgName = ""
		RunClientScript( "UIToClient_SetupMenuGladCard", null, "", true, true )
	}
}



const float LOADING_COVER_FADE_TIME = 0.13
const float LOADING_COVER_HOLD_TIME = 0.48
const float LOADING_COVER_OUT_TIME = LOADING_COVER_FADE_TIME + LOADING_COVER_HOLD_TIME





















































































































































































































































































void function OnItemFlavorRegistered_Character( ItemFlavor characterClass )
{




	
	

	
	{
		array<ItemFlavor> frameList = RegisterReferencedItemFlavorsFromArray( characterClass, "gcardFrames", "flavor" )
		MakeItemFlavorSet( frameList, fileLevel.cosmeticFlavorSortOrdinalMap )

		LoadoutEntry entry = RegisterLoadoutSlot( eLoadoutEntryType.ITEM_FLAVOR, "gcard_frame_for_" + ItemFlavor_GetGUIDString( characterClass ), eLoadoutEntryClass.CHARACTER )
		entry.category     = eLoadoutCategory.GCARD_FRAMES
#if DEV
			entry.pdefSectionKey = "character " + ItemFlavor_GetGUIDString( characterClass )
			entry.DEV_name       = ItemFlavor_GetCharacterRef( characterClass ) + " GCard Frame"
#endif
		entry.stryderCharDataArrayIndex = ePlayerStryderCharDataArraySlots.BANNER_FRAME
		foreach ( ItemFlavor frame in frameList )
		{
			if ( ItemFlavor_GetGRXMode( frame ) == eItemFlavorGRXMode.NONE )
			{
				entry.defaultItemFlavor = frame
				break
			}
		}
		entry.validItemFlavorList       = frameList
		entry.isSlotLocked              = bool function( EHI playerEHI ) {
			return !IsLobby()
		}
		entry.associatedCharacterOrNull = characterClass
		entry.networkTo                 = eLoadoutNetworking.PLAYER_GLOBAL
		entry.networkVarName            = "GladiatorCardFrame"



		fileLevel.loadoutCharacterFrameSlotMap[characterClass] <- entry
	}

	
	{
		array<ItemFlavor> stanceList = RegisterReferencedItemFlavorsFromArray( characterClass, "gcardStances", "flavor" )
		MakeItemFlavorSet( stanceList, fileLevel.cosmeticFlavorSortOrdinalMap )

		LoadoutEntry entry = RegisterLoadoutSlot( eLoadoutEntryType.ITEM_FLAVOR, "gcard_stance_for_" + ItemFlavor_GetGUIDString( characterClass ), eLoadoutEntryClass.CHARACTER	)
		entry.category     = eLoadoutCategory.GCARD_STANCES
#if DEV
			entry.pdefSectionKey = "character " + ItemFlavor_GetGUIDString( characterClass )
			entry.DEV_name       = ItemFlavor_GetCharacterRef( characterClass ) + " GCard Stance"
#endif
		entry.stryderCharDataArrayIndex = ePlayerStryderCharDataArraySlots.BANNER_STANCE
		entry.defaultItemFlavor         = stanceList[0]
		entry.validItemFlavorList       = stanceList
		entry.isSlotLocked              = bool function( EHI playerEHI ) {
			return !IsLobby()
		}
		entry.associatedCharacterOrNull = characterClass
		entry.networkTo                 = eLoadoutNetworking.PLAYER_GLOBAL
		entry.networkVarName            = "GladiatorCardStance"



		fileLevel.loadoutCharacterStanceSlotMap[characterClass] <- entry
	}

	array<ItemFlavor> badgeList = RegisterReferencedItemFlavorsFromArray( characterClass, "gcardBadges", "flavor" )


































	MakeItemFlavorSet( badgeList, fileLevel.cosmeticFlavorSortOrdinalMap )
	fileLevel.loadoutCharacterBadgesSlotListMap[characterClass] <- []
	fileLevel.loadoutCharacterBadgesTierSlotListMap[characterClass] <- []

	for ( int badgeIndex = 0; badgeIndex < GLADIATOR_CARDS_NUM_BADGES; badgeIndex++ )
	{
		LoadoutEntry entry = RegisterLoadoutSlot( eLoadoutEntryType.ITEM_FLAVOR, "gcard_badge_" + badgeIndex + "_for_" + ItemFlavor_GetGUIDString( characterClass ), eLoadoutEntryClass.CHARACTER )
		entry.category     = eLoadoutCategory.GCARD_BADGES
#if DEV
			entry.pdefSectionKey = "character " + ItemFlavor_GetGUIDString( characterClass )
			entry.DEV_name       = ItemFlavor_GetCharacterRef( characterClass ) + " GCard Badge " + badgeIndex
#endif
		entry.stryderCharDataArrayIndex = ePlayerStryderCharDataArraySlots.BANNER_BADGE1 + 2 * badgeIndex
		entry.validItemFlavorList       = badgeList
		if ( badgeIndex == 0 && badgeList.len() > 1 )
		{
			entry.defaultItemFlavor = entry.validItemFlavorList[ 1 ]
		}
		else
		{
			entry.defaultItemFlavor = entry.validItemFlavorList[ 0 ]
		}
		entry.isItemFlavorUnlocked      = (bool function( EHI playerEHI, ItemFlavor badge, bool shouldIgnoreGRX = false, bool shouldIgnoreOtherSlots = false ) : ( characterClass, badgeIndex ) {
			if( !Loadout_GetPlayerBadgeIsUnlocked( playerEHI, badge, characterClass ) )
				return false

			return IsItemFlavorGRXUnlockedForLoadoutSlot( playerEHI, badge, shouldIgnoreGRX, shouldIgnoreOtherSlots )
		})
		entry.isSlotLocked              = bool function( EHI playerEHI ) {
			return !IsLobby()
		}
		entry.associatedCharacterOrNull = characterClass
		entry.networkTo                 = eLoadoutNetworking.PLAYER_GLOBAL
		entry.networkVarName            = "GladiatorCardBadge" + badgeIndex
































		fileLevel.loadoutCharacterBadgesSlotListMap[characterClass].append( entry )

		LoadoutEntry tierEntry = RegisterLoadoutSlot( eLoadoutEntryType.INTEGER, "gcard_badge_" + badgeIndex + "_tier_for_" + ItemFlavor_GetGUIDString( characterClass ), eLoadoutEntryClass.CHARACTER )
		tierEntry.category     = eLoadoutCategory.GCARD_BADGE_TIER
#if DEV
			tierEntry.pdefSectionKey = "character " + ItemFlavor_GetGUIDString( characterClass )
			tierEntry.DEV_name       = ItemFlavor_GetCharacterRef( characterClass ) + " GCard Badge" + badgeIndex + " Tier"
#endif
		tierEntry.stryderCharDataArrayIndex = ePlayerStryderCharDataArraySlots.BANNER_BADGE1_TIER + 2 * badgeIndex
		
		tierEntry.associatedCharacterOrNull = characterClass
		tierEntry.networkTo                 = eLoadoutNetworking.PLAYER_GLOBAL
		tierEntry.networkVarName            = "GladiatorCardBadge" + badgeIndex + "Tier"







		fileLevel.loadoutCharacterBadgesTierSlotListMap[characterClass].append( tierEntry )
	}

	array<ItemFlavor> trackerList = RegisterReferencedItemFlavorsFromArray( characterClass, "gcardStatTrackers", "flavor" )























	MakeItemFlavorSet( trackerList, fileLevel.cosmeticFlavorSortOrdinalMap )
	fileLevel.loadoutCharacterTrackersSlotListMap[characterClass] <- []
	fileLevel.loadoutCharacterTrackersValueSlotListMap[characterClass] <- []

	for ( int trackerIndex = 0; trackerIndex < GLADIATOR_CARDS_NUM_TRACKERS; trackerIndex++ )
	{
		LoadoutEntry entry = RegisterLoadoutSlot( eLoadoutEntryType.ITEM_FLAVOR, "gcard_tracker_" + trackerIndex + "_for_" + ItemFlavor_GetGUIDString( characterClass ), eLoadoutEntryClass.CHARACTER )
		entry.category     = eLoadoutCategory.GCARD_TRACKERS
#if DEV
			entry.pdefSectionKey = "character " + ItemFlavor_GetGUIDString( characterClass )
			entry.DEV_name       = ItemFlavor_GetCharacterRef( characterClass ) + " GCard Tracker " + trackerIndex
#endif
		entry.stryderCharDataArrayIndex = ePlayerStryderCharDataArraySlots.BANNER_TRACKER1 + 2 * trackerIndex
		entry.validItemFlavorList       = trackerList
		entry.defaultItemFlavor         = entry.validItemFlavorList[ 0 ]
		entry.isSlotLocked              = bool function( EHI playerEHI ) {
			return !IsLobby()
		}
		entry.associatedCharacterOrNull = characterClass
		entry.networkTo                 = eLoadoutNetworking.PLAYER_GLOBAL
		entry.networkVarName            = "GladiatorCardTracker" + trackerIndex



		fileLevel.loadoutCharacterTrackersSlotListMap[characterClass].append( entry )

		LoadoutEntry valueEntry = RegisterLoadoutSlot( eLoadoutEntryType.INTEGER, "gcard_tracker_" + trackerIndex + "_value_for_" + ItemFlavor_GetGUIDString( characterClass ), eLoadoutEntryClass.CHARACTER )
		valueEntry.category     = eLoadoutCategory.GCARD_TRACKER_TIER
#if DEV
			valueEntry.pdefSectionKey = "character " + ItemFlavor_GetGUIDString( characterClass )
			valueEntry.DEV_name       = ItemFlavor_GetCharacterRef( characterClass ) + " GCard Tracker" + trackerIndex + " Value"
#endif
		valueEntry.stryderCharDataArrayIndex = ePlayerStryderCharDataArraySlots.BANNER_TRACKER1_VALUE + 2 * trackerIndex
		
		valueEntry.associatedCharacterOrNull = characterClass
		valueEntry.networkTo                 = eLoadoutNetworking.PLAYER_GLOBAL
		valueEntry.networkVarName            = "GladiatorCardTracker" + trackerIndex + "Value"









		fileLevel.loadoutCharacterTrackersValueSlotListMap[characterClass].append( valueEntry )







	}
}
























































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































int function GetPlayerBadgeDataInteger( EHI playerEHI, ItemFlavor badge, int badgeIndex, ItemFlavor ornull character, bool showOneTierHigherThanIsUnlocked = false )
{

		if ( playerEHI != LocalClientEHI() )
		{
			LoadoutEntry tierSlot = Loadout_GladiatorCardBadgeTier( expect ItemFlavor(character), badgeIndex )
			return LoadoutSlot_GetInteger( playerEHI, tierSlot )
		}


	if ( ItemFlavor_GetGRXMode( badge ) == eItemFlavorGRXMode.REGULAR )
	{






			if ( GRX_IsItemOwnedByPlayer_AllowOutOfDateData( badge , FromEHI( LocalClientEHI() ) ) )
				return GRX_GetItemTier( ItemFlavor_GetGRXIndex( badge ) )
			else
				return -1

	}

	
	if ( ItemFlavor_GetGRXMode( badge ) != eItemFlavorGRXMode.NONE )
		return 0

	string dynamicTextStatRef = GladiatorCardBadge_GetDynamicTextStatRef( badge )
	string unlockStatRef      = GladiatorCardBadge_GetUnlockStatRef( badge, character )
	bool unlocksByDynamicStat = ( unlockStatRef == dynamicTextStatRef )
	int dynamicStatVal        = -1

	if ( dynamicTextStatRef != "" )
	{
		if ( !GladiatorCardBadge_IsValidStatRef( dynamicTextStatRef ) )
			return 0

		dynamicStatVal = GladiatorCardBadge_GetStatInt( FromEHI( playerEHI ), dynamicTextStatRef, IsLobby() ? eStatGetWhen.CURRENT : eStatGetWhen.START_OF_CURRENT_MATCH )
	}

	if ( !unlocksByDynamicStat && dynamicStatVal != -1 )
		return dynamicStatVal

	if ( !GladiatorCardBadge_IsValidStatRef( unlockStatRef ) )
		return 0

	int dataInteger = -1
	entity player   = FromEHI( playerEHI )
	int tierCount   = GladiatorCardBadge_GetTierCount( badge )
	for ( int tierIdx = 0; tierIdx < tierCount; tierIdx++ )
	{
		GladCardBadgeTierData tierData = GladiatorCardBadge_GetTierData( badge, tierIdx )
		if ( !GladiatorCardBadge_DoesStatRefSatisfyValue( player, unlockStatRef, tierData.unlocksAt, IsLobby() ? eStatGetWhen.CURRENT : eStatGetWhen.START_OF_CURRENT_MATCH ) )
			break

		dataInteger = tierIdx
	}

	if ( dataInteger == -1 )
		return dataInteger

	if ( dynamicStatVal != -1 )
		return dynamicStatVal

	if ( showOneTierHigherThanIsUnlocked && ( dataInteger < ( tierCount - 1 ) ) )
		dataInteger += 1

	return dataInteger
}








bool function Loadout_GetPlayerBadgeIsUnlocked( EHI playerEHI, ItemFlavor badge, ItemFlavor ornull character )
{
	if ( IsEverythingUnlocked() )
		return true

	if ( ItemFlavor_GetGRXMode( badge ) != eItemFlavorGRXMode.NONE )
		return true 

	string unlockStatRef = GladiatorCardBadge_GetUnlockStatRef( badge, character )

	if ( unlockStatRef == "" ) 
		return true

	if ( !GladiatorCardBadge_IsValidStatRef( unlockStatRef ) )
		return false

	entity player = FromEHI( playerEHI )
	int tierCount   = GladiatorCardBadge_GetTierCount( badge )
	for ( int tierIdx = 0; tierIdx < tierCount; tierIdx++ )
	{
		GladCardBadgeTierData tierData = GladiatorCardBadge_GetTierData( badge, tierIdx )
		if ( !GladiatorCardBadge_DoesStatRefSatisfyValue( player, unlockStatRef, tierData.unlocksAt, IsLobby() ? eStatGetWhen.CURRENT : eStatGetWhen.START_OF_CURRENT_MATCH ) )
			break

		return true
	}

	return false
}




LoadoutEntry function Loadout_GladiatorCardFrame( ItemFlavor characterClass )
{
	return fileLevel.loadoutCharacterFrameSlotMap[characterClass]
}




LoadoutEntry function Loadout_GladiatorCardStance( ItemFlavor characterClass )
{
	return fileLevel.loadoutCharacterStanceSlotMap[characterClass]
}




LoadoutEntry function Loadout_GladiatorCardBadge( ItemFlavor characterClass, int badgeIndex )
{
	return fileLevel.loadoutCharacterBadgesSlotListMap[characterClass][badgeIndex]
}




LoadoutEntry function Loadout_GladiatorCardBadgeTier( ItemFlavor characterClass, int badgeIndex )
{
	return fileLevel.loadoutCharacterBadgesTierSlotListMap[characterClass][badgeIndex]
}




LoadoutEntry function Loadout_GladiatorCardStatTracker( ItemFlavor characterClass, int trackerIndex )
{
	return fileLevel.loadoutCharacterTrackersSlotListMap[characterClass][trackerIndex]
}




LoadoutEntry function Loadout_GladiatorCardStatTrackerValue( ItemFlavor characterClass, int trackerIndex )
{
	return fileLevel.loadoutCharacterTrackersValueSlotListMap[characterClass][trackerIndex]
}




int function GladiatorCardFrame_GetSortOrdinal( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	return fileLevel.cosmeticFlavorSortOrdinalMap[flavor]
}




ItemFlavor ornull function GladiatorCardFrame_GetCharacterFlavor( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	if ( GladiatorCardFrame_IsSharedBetweenCharacters( flavor ) )
		return null

	Assert( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) != "" )

	return GetItemFlavorByAsset( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) )
}



bool function GladiatorCardFrame_HasStoryBlurb( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	return ( GladiatorCardFrame_GetStoryBlurbBodyText( flavor ) != "" )
}



string function GladiatorCardFrame_GetStoryBlurbBodyText( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "customSkinMenuBlurb" )
}



bool function GladiatorCardFrame_ShouldHideIfLocked( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "shouldHideIfLocked" )
}



bool function GladiatorCardFrame_IsSharedBetweenCharacters( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "isSharedBetweenCharacters" )
}



vector[GLADIATOR_CARDS_NUM_FRAME_KEY_COLORS] function GladiatorCardFrame_GetKeyColors( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	vector[GLADIATOR_CARDS_NUM_FRAME_KEY_COLORS] out
	for ( int idx = 0; idx < GLADIATOR_CARDS_NUM_FRAME_KEY_COLORS; idx++ )
		out[idx] = GetGlobalSettingsVector( ItemFlavor_GetAsset( flavor ), "keyCol_" + idx )
	return out
}




bool function GladiatorCardFrame_HasOwnRUI( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "hasOwnRui" )
}




bool function GladiatorCardFrame_IsArtFullFrame( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )
	Assert( !GladiatorCardFrame_HasOwnRUI( flavor ) )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "isArtFullFrame" )
}




asset function GladiatorCardFrame_GetFGImageAsset( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )
	Assert( !GladiatorCardFrame_HasOwnRUI( flavor ) )

	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "fgImageAsset" )
}




float function GladiatorCardFrame_GetFGImageBlend( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )
	Assert( !GladiatorCardFrame_HasOwnRUI( flavor ) )

	return GetGlobalSettingsFloat( ItemFlavor_GetAsset( flavor ), "fgImageBlend" )
}




float function GladiatorCardFrame_GetFGImagePremul( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )
	Assert( !GladiatorCardFrame_HasOwnRUI( flavor ) )

	return GetGlobalSettingsFloat( ItemFlavor_GetAsset( flavor ), "fgImagePremul" )
}




asset function GladiatorCardFrame_GetBGImageAsset( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )
	Assert( !GladiatorCardFrame_HasOwnRUI( flavor ) )

	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "bgImageAsset" )
}




asset function GladiatorCardFrame_GetFGRuiAsset( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )
	Assert( GladiatorCardFrame_HasOwnRUI( flavor ) )

	return GetGlobalSettingsStringAsAsset( ItemFlavor_GetAsset( flavor ), "fgRuiAsset" )
}




asset function GladiatorCardFrame_GetBGRuiAsset( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )
	Assert( GladiatorCardFrame_HasOwnRUI( flavor ) )

	return GetGlobalSettingsStringAsAsset( ItemFlavor_GetAsset( flavor ), "bgRuiAsset" )
}




string function GladiatorCardFrame_GetColorCorrectionRawPath( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "colorCorrectionRawPath" )
}




float function GladiatorCardFrame_GetExposure( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_frame )

	return GetGlobalSettingsFloat( ItemFlavor_GetAsset( flavor ), "exposure" )
}



















int function GladiatorCardStance_GetSortOrdinal( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stance )

	return fileLevel.cosmeticFlavorSortOrdinalMap[flavor]
}




ItemFlavor function GladiatorCardStance_GetCharacterFlavor( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stance )

	Assert( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) != "" )

	return GetItemFlavorByAsset( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) )
}

































































































bool function GladiatorCardBadge_IsTheEmpty( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "isTheEmpty" )
}



bool function GladiatorCardBadge_ShouldHideIfLocked( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "shouldHideIfLocked" )
}




bool function GladiatorCardBadge_IsCharacterBadge( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "isCharacterBadge" )
}



int function GladiatorCardBadge_GetSortOrdinal( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	return fileLevel.cosmeticFlavorSortOrdinalMap[flavor]
}




ItemFlavor ornull function GladiatorCardBadge_GetCharacterFlavor( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )
	if ( GladiatorCardBadge_IsCharacterBadge( flavor ) == false )
		return null

	if ( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) != "" )
		return GetItemFlavorByAsset( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) )

	Assert( !GladiatorCardBadge_IsCharacterBadge( flavor ), "" + string(ItemFlavor_GetAsset( flavor )) + " is a CHARACTER badge but it doesn't have a parentItemFlavor" )
	return null
}




string function GladiatorCardBadge_GetUnlockStatRef( ItemFlavor flavor, ItemFlavor ornull character )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )


	string statRef = GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "unlockStatRef" )
	if ( character != null )
		statRef = replace( statRef, "%char%", ItemFlavor_GetGUIDString( expect ItemFlavor(character) ) )
	else
		Assert( replace( statRef, "%char%", "" ) == statRef )
	return statRef
}




string function GladiatorCardBadge_GetDynamicTextStatRef( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "dynamicTextStatRef" )
}




int function GladiatorCardBadge_GetTierCount( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	var flavorBlock = ItemFlavor_GetSettingsBlock( flavor )
	return GetSettingsArraySize( GetSettingsBlockArray( flavorBlock, "tiers" ) )
}




GladCardBadgeTierData function GladiatorCardBadge_GetTierData( ItemFlavor flavor, int tierIdx )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	var flavorBlock        = ItemFlavor_GetSettingsBlock( flavor )
	var tierDataBlockArray = GetSettingsBlockArray( flavorBlock, "tiers" )
	Assert( tierIdx >= 0 && tierIdx < GetSettingsArraySize( tierDataBlockArray ) )
	var tierDataBlock = GetSettingsArrayElem( tierDataBlockArray, tierIdx )

	GladCardBadgeTierData data
	data.unlocksAt = GetSettingsBlockFloat( tierDataBlock, "unlocksAt" )
	data.ruiAsset = GetSettingsBlockStringAsAsset( tierDataBlock, "ruiAsset" )
	data.imageAsset = GetSettingsBlockAsset( tierDataBlock, "imageAsset" )
	return data
}




array<GladCardBadgeTierData> function GladiatorCardBadge_GetTierDataList( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	array<GladCardBadgeTierData> tierDataList = []
	for ( int tierIdx = 0; tierIdx < GladiatorCardBadge_GetTierCount( flavor ); tierIdx++ )
		tierDataList.append( GladiatorCardBadge_GetTierData( flavor, tierIdx ) )

	return tierDataList
}



int function GladiatorCardBadge_GetStatInt( entity player, string statRef, int when = eStatGetWhen.CURRENT )
{

	bool isGeneralStat = GladiatorCardBadge_IsGeneralStat( statRef )
	if ( !isGeneralStat )
	{
		return Mastery_GetStatValue( player, statRef )
	}
	else

	{
		StatEntry statEntry = GetStatEntryByRef( statRef )
		return GetStat_Int( player, statEntry, when )
	}
	unreachable
}



bool function GladiatorCardBadge_DoesStatRefSatisfyValue( entity player, string statRef, float checkValue, int when = eStatGetWhen.CURRENT )
{

	bool isGeneralStat = GladiatorCardBadge_IsGeneralStat( statRef )
	if ( !isGeneralStat )
	{
		return Mastery_DoesStatSatisfyValue( player, statRef, checkValue )
	}
	else

	{
		StatEntry statEntry = GetStatEntryByRef( statRef )
		return DoesStatSatisfyValue( player, statEntry, checkValue, when )
	}
	unreachable
}



bool function GladiatorCardBadge_IsValidStatRef( string statRef )
{

	bool isGeneralStat = GladiatorCardBadge_IsGeneralStat( statRef )
	if ( !isGeneralStat )
	{
		return Mastery_IsValidStatRef( statRef )
	}
	else

	{
		return IsValidStatEntryRef( statRef )
	}
	unreachable
}



bool function GladiatorCardBadge_IsGeneralStat( string statRef )
{

		const string MASTERY_TAG = "mastery_"
		return !(statRef.len() > MASTERY_TAG.len() && statRef.slice( 0, MASTERY_TAG.len() ) == MASTERY_TAG)



}



bool function GladiatorCardBadge_HasOwnRUI( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "hasOwnRui" )
}



bool function GladiatorCardBadge_IsOversizedImage( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_badge )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "isOversizedImage" )
}



bool function GladiatorCardTracker_IsTheEmpty( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stat_tracker )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "isTheEmpty" )
}




bool function GladiatorCardStatTracker_IsSharedBetweenCharacters( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stat_tracker )

	return ( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) == "" )
}



int function GladiatorCardStatTracker_GetSortOrdinal( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stat_tracker )

	return fileLevel.cosmeticFlavorSortOrdinalMap[flavor]
}




ItemFlavor ornull function GladiatorCardStatTracker_GetCharacterFlavor( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stat_tracker )

	if ( GladiatorCardStatTracker_IsSharedBetweenCharacters(flavor) )
		return null

	Assert( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) != "" )

	return GetItemFlavorByAsset( GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "parentItemFlavor" ) )
}




string function GladiatorCardStatTracker_GetStatRef( ItemFlavor flavor, ItemFlavor character )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stat_tracker )

	string statRef = GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "statRef" )
	statRef = replace( statRef, "%char%", ItemFlavor_GetGUIDString( character ) )
	return statRef
}





string function GladiatorCardStatTracker_GetValueSuffix( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stat_tracker )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "valueSuffix" )
}




asset function GladiatorCardStatTracker_GetBackgroundImage( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stat_tracker )

	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "backgroundImage" )
}




vector function GladiatorCardStatTracker_GetColor0( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.gladiator_card_stat_tracker )

	return GetGlobalSettingsVector( ItemFlavor_GetAsset( flavor ), "color0" )
}




string function GladiatorCardStatTracker_GetFormattedValueText( entity player, ItemFlavor character, ItemFlavor flavor )
{
	if ( GladiatorCardTracker_IsTheEmpty( flavor ) )
		return ""

	string statRef  = GladiatorCardStatTracker_GetStatRef( flavor, character )

	StatEntry statEntry = GetStatEntryByRef( statRef )

	int statVal = GetStat_Int( player, statEntry )

	string valueText

	valueText = format( "%i", statVal )

	return valueText
}
















bool function GladiatorCardBadge_DoesStatSatisfyValue( ItemFlavor badge, float val )
{
	Assert( ItemFlavor_GetType( badge ) == eItemType.gladiator_card_badge )

	string unlockStatRef = GladiatorCardBadge_GetUnlockStatRef( badge, GladiatorCardBadge_GetCharacterFlavor( badge ) )
	Assert( GladiatorCardBadge_IsValidStatRef( unlockStatRef ) )

	return GladiatorCardBadge_DoesStatRefSatisfyValue( GetLocalClientPlayer(), unlockStatRef, val, eStatGetWhen.CURRENT )
}


