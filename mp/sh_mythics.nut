global function ShMythics_LevelInit

global function RegisterMythicBundlesForCharacter

global function Mythics_CharacterHasMythic
global function Mythics_SkinHasCustomExecution
global function Mythics_IsCustomExecutionUnlocked
global function Mythics_ShouldForceCustomExecution
global function Mythics_GetChallengeForCharacter
global function Mythics_IsItemFlavorMythic
global function Mythics_IsItemFlavorMythicSkin
global function Mythics_GetSkinTierForCharacter
global function Mythics_GetItemTierForSkin
global function Mythics_GetSkinTierIntForSkin
global function Mythics_GetAllSkinsFromBase
global function Mythics_GetChallengeGUIDForSkinGUID
global function Mythics_GetChallengeForSkin
global function Mythics_GetNumTiersUnlockedForSkin
global function Mythics_GetCustomExecutionForCharacterOrSkin
global function Mythics_IsCustomExecutionInMythicBundle
global function Mythics_GetCharacterSkinForCustomExecution
global function Mythics_GetCharacterForSkin
global function Mythics_GetMythicSkinGUIDsForCharacter
global function Mythics_GetStoreImageForCharacter
global function Mythics_GetSkinBaseNameForCharacter
global function Mythics_SkinHasCustomSkydivetrail
global function Mythics_GetCustomSkydivetrailForCharacterOrSkin
global function Mythics_IsExecutionUsableOnTier1AndTier2












struct FileStruct_LifetimeLevel
{
	table< int, int > mythicSkinsGUIDToCustomExecutionGUID
	table< int, int > mythicSkinsGUIDToCustomSkydivetrailGUID
	table< int, int > mythicCharactersGUIDToChallengesGUID
	table< int, bool > mythicCharactersGUIDToExecutionUsableOnTier1And2
	table< int, int > customExecutionGUIDToMythicSkinsGUID

	table< int, array< int > > charactersGUIDToMythicSkinGUIDs
	table< int, array< asset > > charactersGUIDToStoreImages
	table< int, string > charactersGUIDToSkinBaseName
	ItemFlavor ornull currentChallenge
	table< entity, array< ItemFlavor > > mythicBoostedChallenges
}
FileStruct_LifetimeLevel& fileLevel

global struct Mythic_ChallengeProgress
{
	ItemFlavor& challenge
	int challengeProgress
	int statMarker
}

const int CHALLENGE_SORT_ORDINAL = 0 
const int FINAL_TIER = 3

void function ShMythics_LevelInit()
{
	FileStruct_LifetimeLevel newFileLevel
	fileLevel = newFileLevel
}

void function RegisterMythicBundlesForCharacter( ItemFlavor characterClass )
{
	int characterGUID = ItemFlavor_GetGUID( characterClass )

	array<ItemFlavor> mythicBundlesList = RegisterReferencedItemFlavorsFromArray( characterClass, "mythicBundles", "flavor" )

	Assert ( mythicBundlesList.len() <= 1, "Character " + string(ItemFlavor_GetAsset( characterClass )) + " has more than one Mythic bundle registered." )

	if ( mythicBundlesList.len() == 0 )
		return

	ItemFlavor mythicBundleFlav = mythicBundlesList[0]
	asset mythicBundleAsset = ItemFlavor_GetAsset( mythicBundleFlav )
	var settingsBlock = GetSettingsBlockForAsset( mythicBundleAsset )
	asset challengeAsset = GetSettingsBlockAsset( settingsBlock, "challengeAsset" )
	asset executionAsset = GetSettingsBlockAsset( settingsBlock, "executionAsset" )
	asset skydivetrailAsset = GetSettingsBlockAsset( settingsBlock, "skydivetrailAsset" )
	var skinDataArray = GetSettingsBlockArray( settingsBlock, "skinsByTier" )

	array< asset > skinAssets
	array< int > skinGUIDs
	int tierIdx = 1
	int preRegGUID
	foreach ( var skinBlock in IterateSettingsArray( skinDataArray ) )
	{
		asset entryAsset = GetSettingsBlockAsset( skinBlock, "skinAsset" )
		skinAssets.append( entryAsset )
		skinGUIDs.append( GetUniqueIdForSettingsAsset( entryAsset ) )

		if ( tierIdx == 1 )
		{
			preRegGUID = GetUniqueIdForSettingsAsset( entryAsset )
			if ( skydivetrailAsset != $"" )
			{
				SettingsAssetGUID skydiveGUID = GetUniqueIdForSettingsAsset( skydivetrailAsset )
				ItemFlavor ornull skydiveFlavOrNull = RegisterItemFlavorFromSettingsAsset( skydivetrailAsset )
				if ( skydiveFlavOrNull != null && IsValidItemFlavorGUID( skydiveGUID ) )
					fileLevel.mythicSkinsGUIDToCustomSkydivetrailGUID[ preRegGUID ] <- skydiveGUID
			}
		}
		else if ( tierIdx == FINAL_TIER )
		{
			int skinGUID = GetUniqueIdForSettingsAsset( entryAsset )
			int executionGUID = GetUniqueIdForSettingsAsset( executionAsset )
			fileLevel.mythicSkinsGUIDToCustomExecutionGUID[ skinGUID ] <- executionGUID
			fileLevel.customExecutionGUIDToMythicSkinsGUID[ executionGUID ] <- skinGUID
		}

		tierIdx++
	}

	if ( tierIdx > 1 )
	{
		fileLevel.charactersGUIDToMythicSkinGUIDs[ characterGUID ] <- skinGUIDs
	}

	foreach ( var storeImage in IterateSettingsArray( GetSettingsBlockArray( settingsBlock, "storeImagesByTier" ) ) )
	{
		asset entryAsset = GetSettingsBlockAsset( storeImage, "storeImage" )

		if( !( characterGUID in fileLevel.charactersGUIDToStoreImages ) )
			fileLevel.charactersGUIDToStoreImages[ characterGUID ] <- []

		fileLevel.charactersGUIDToStoreImages[ characterGUID ].append( entryAsset )
	}

	ItemFlavor ornull challengeFlavOrNull = RegisterItemFlavorFromSettingsAsset( challengeAsset )
	if ( challengeFlavOrNull != null )
	{
		ItemFlavor challengeFlav = expect ItemFlavor( challengeFlavOrNull )
		RegisterChallengeSource( challengeFlav, mythicBundleFlav, CHALLENGE_SORT_ORDINAL )

		table<string, string> ornull metaData = ItemFlavor_GetMetaData( challengeFlav )
		expect table<string, string>(metaData)

		metaData[ HAS_MYTHIC_PREREQ ] <- string( preRegGUID )

		fileLevel.mythicCharactersGUIDToChallengesGUID[ characterGUID ] <- ItemFlavor_GetGUID( challengeFlav )
	}

	fileLevel.charactersGUIDToSkinBaseName[ characterGUID ] <- GetSettingsBlockString( settingsBlock, "baseSkinName" )

	fileLevel.mythicCharactersGUIDToExecutionUsableOnTier1And2[ characterGUID ] <- GetGlobalSettingsBool( ItemFlavor_GetAsset( mythicBundleFlav ), "isExecutionUsableOnTier1AndTier2" )
}

bool function Mythics_CharacterHasMythic( ItemFlavor character )
{
	Assert( IsItemFlavorStructValid( character.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )
	Assert( ItemFlavor_GetType( character ) == eItemType.character )

	int characterGUID = ItemFlavor_GetGUID( character )

	return ( characterGUID in fileLevel.mythicCharactersGUIDToChallengesGUID )
}


bool function Mythics_SkinHasCustomExecution( ItemFlavor skin )
{
	Assert( IsItemFlavorStructValid( skin.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )

	int skinGUID = GetUniqueIdForSettingsAsset( ItemFlavor_GetAsset( skin ) )

	return ( skinGUID in fileLevel.mythicSkinsGUIDToCustomExecutionGUID )
}


bool function Mythics_CharacterHasCustomExecution( ItemFlavor character )
{
	Assert( IsItemFlavorStructValid( character.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )

	array<int> skinGUIDs = Mythics_GetMythicSkinGUIDsForCharacter( character )

	foreach ( int skinGUID in skinGUIDs )
	{
		if ( skinGUID in fileLevel.mythicSkinsGUIDToCustomExecutionGUID )
			return true
	}
	return false
}

bool function Mythics_IsExecutionUsableOnTier1AndTier2( ItemFlavor skinOrCharacter )
{
	ItemFlavor character = ItemFlavor_GetType( skinOrCharacter ) == eItemType.character_skin ? Mythics_GetCharacterForSkin( skinOrCharacter ) : skinOrCharacter
	Assert( ItemFlavor_GetType( character ) == eItemType.character, eValidation.ASSERT )

	int characterGUID = ItemFlavor_GetGUID( character )
	if ( characterGUID in fileLevel.mythicCharactersGUIDToExecutionUsableOnTier1And2 )
		return fileLevel.mythicCharactersGUIDToExecutionUsableOnTier1And2[ characterGUID ]
	return false
}

bool function Mythics_IsCustomExecutionUnlocked( entity player, ItemFlavor skin )
{
	if ( Mythics_IsExecutionUsableOnTier1AndTier2( skin ) )
		return Mythics_GetNumTiersUnlockedForSkin( player, skin ) == FINAL_TIER

	return Mythics_SkinHasCustomExecution( skin )
}

bool function Mythics_ShouldForceCustomExecution( entity player, ItemFlavor skin )
{
	if ( Mythics_IsExecutionUsableOnTier1AndTier2( skin ) )
		return false

	return Mythics_SkinHasCustomExecution( skin )
}

ItemFlavor function Mythics_GetCustomExecutionForCharacterOrSkin( ItemFlavor characterOrSkin )
{
	Assert( IsItemFlavorStructValid( characterOrSkin.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )

	if ( ItemFlavor_GetType( characterOrSkin ) == eItemType.character_skin && Mythics_IsExecutionUsableOnTier1AndTier2( characterOrSkin ) )
		characterOrSkin = Mythics_GetCharacterForSkin( characterOrSkin )

	int skinGUID = Mythics_GetSkinGUIDFromItem( characterOrSkin )
	int executionGUID = fileLevel.mythicSkinsGUIDToCustomExecutionGUID[ skinGUID ]

	Assert( IsValidItemFlavorGUID( executionGUID ) )
	Assert( ItemFlavor_GetType( GetItemFlavorByGUID( executionGUID ) ) == eItemType.character_execution )

	return GetItemFlavorByGUID( executionGUID )
}

bool function Mythics_IsCustomExecutionInMythicBundle( ItemFlavor execution )
{
	Assert( IsItemFlavorStructValid( execution.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )
	Assert( ItemFlavor_GetType( execution ) == eItemType.character_execution )

	return ( execution.guid in fileLevel.customExecutionGUIDToMythicSkinsGUID )
}

ItemFlavor function Mythics_GetCharacterSkinForCustomExecution( ItemFlavor execution )
{
	Assert( IsItemFlavorStructValid( execution.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )
	Assert( ItemFlavor_GetType( execution ) == eItemType.character_execution )
	Assert( Mythics_IsCustomExecutionInMythicBundle( execution ) )

	int characterSkinGUID = fileLevel.customExecutionGUIDToMythicSkinsGUID[ execution.guid ]

	return GetItemFlavorByGUID( characterSkinGUID )
}

bool function Mythics_SkinHasCustomSkydivetrail( ItemFlavor skin )
{
	Assert( IsItemFlavorStructValid( skin.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )

	int skinGUID = GetUniqueIdForSettingsAsset( ItemFlavor_GetAsset( skin ) )

	return ( skinGUID in fileLevel.mythicSkinsGUIDToCustomSkydivetrailGUID )
}


ItemFlavor function Mythics_GetCustomSkydivetrailForCharacterOrSkin( ItemFlavor item )
{
	if ( ItemFlavor_GetType( item ) == eItemType.character )
		item = expect ItemFlavor( Mythics_GetSkinTierForCharacter( item, 0 ) )

	int skinGUID = Mythics_GetSkinGUIDFromItem( item )
	int skydivetrailGUID = fileLevel.mythicSkinsGUIDToCustomSkydivetrailGUID[ skinGUID ]

	Assert( IsValidItemFlavorGUID( skydivetrailGUID ) )
	Assert( ItemFlavor_GetType( GetItemFlavorByGUID( skydivetrailGUID ) ) == eItemType.skydive_trail )

	return GetItemFlavorByGUID( skydivetrailGUID )
}

int function Mythics_GetSkinGUIDFromItem( ItemFlavor item )
{
	Assert( IsItemFlavorStructValid( item.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )
	Assert( ItemFlavor_GetType( item ) == eItemType.character || ItemFlavor_GetType( item ) == eItemType.character_skin )

	int skinGUID

	if ( ItemFlavor_GetType( item ) == eItemType.character )
	{
		int characterGUID = ItemFlavor_GetGUID( item )
		skinGUID = fileLevel.charactersGUIDToMythicSkinGUIDs[ characterGUID ][ FINAL_TIER - 1 ]
	}
	else 
	{
		skinGUID = ItemFlavor_GetGUID( item )
	}

	return skinGUID
}

ItemFlavor function Mythics_GetChallengeForCharacter( ItemFlavor character )
{
	Assert( IsItemFlavorStructValid( character.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )

	int characterGUID = ItemFlavor_GetGUID( character )
	int challengeGUID = fileLevel.mythicCharactersGUIDToChallengesGUID[ characterGUID ]

	Assert( IsValidItemFlavorGUID( challengeGUID ) )
	Assert( ItemFlavor_GetType( GetItemFlavorByGUID( challengeGUID ) ) == eItemType.challenge )

	return GetItemFlavorByGUID( challengeGUID )
}

bool function Mythics_IsItemFlavorMythic( ItemFlavor item )
{
	return ItemFlavor_GetQuality( item ) == eRarityTier.MYTHIC
}

bool function Mythics_IsItemFlavorMythicSkin( ItemFlavor item )
{
	return ItemFlavor_GetType( item ) == eItemType.character_skin && ItemFlavor_GetQuality( item ) == eRarityTier.MYTHIC
}





































int function Mythics_GetSkinTierIntForSkin( ItemFlavor skin )
{
	Assert( IsItemFlavorStructValid( skin.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )

	int skinGUID =  ItemFlavor_GetGUID( skin )
	int characterGUID = ItemFlavor_GetGUID( expect ItemFlavor( GetItemFlavorAssociatedCharacterOrWeapon( skin ) ) )

	for ( int tier = 1;  tier <= FINAL_TIER; tier++ )
	{
		if ( fileLevel.charactersGUIDToMythicSkinGUIDs[ characterGUID ][tier-1] == skinGUID)
			return tier
	}
	return -1
}

array<ItemFlavor> function Mythics_GetAllSkinsFromBase( ItemFlavor baseSkin )
{
	Assert( ItemFlavor_GetType( baseSkin ) == eItemType.character_skin )

	array<ItemFlavor> mythicSkins

	ItemFlavor character = expect ItemFlavor( GetItemFlavorAssociatedCharacterOrWeapon( baseSkin ) )
	int characterGUID = ItemFlavor_GetGUID( character )

	if ( !( characterGUID in fileLevel.charactersGUIDToMythicSkinGUIDs ) )
		return mythicSkins

	foreach ( int skinGUID in fileLevel.charactersGUIDToMythicSkinGUIDs[ characterGUID ] )
	{
		mythicSkins.append( GetItemFlavorByGUID( skinGUID ) )
	}

	return mythicSkins
}

ItemFlavor ornull function Mythics_GetItemTierForSkin( ItemFlavor skin, int tier )
{
	Assert( ItemFlavor_GetType( skin ) == eItemType.character_skin )

	ItemFlavor character = Mythics_GetCharacterForSkin( skin )

	if ( tier == FINAL_TIER )
		return Mythics_GetCustomExecutionForCharacterOrSkin( character )

	return Mythics_GetSkinTierForCharacter ( character , tier )
}

ItemFlavor ornull function Mythics_GetSkinTierForCharacter( ItemFlavor character, int tier )
{
	Assert( IsItemFlavorStructValid( character.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )

	int characterGUID = ItemFlavor_GetGUID( character )
	int skinGUID

	if( characterGUID in fileLevel.charactersGUIDToMythicSkinGUIDs && fileLevel.charactersGUIDToMythicSkinGUIDs[ characterGUID ].len() > tier )
		skinGUID = fileLevel.charactersGUIDToMythicSkinGUIDs[ characterGUID ][tier]
	else
		return null

	Assert( IsValidItemFlavorGUID( skinGUID ) )
	Assert( ItemFlavor_GetType( GetItemFlavorByGUID( skinGUID ) ) == eItemType.character_skin )

	return GetItemFlavorByGUID( skinGUID )
}

ItemFlavor function Mythics_GetCharacterForSkin( ItemFlavor skin )
{
	Assert( IsItemFlavorStructValid( skin.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )

	int skinGUID =  ItemFlavor_GetGUID( skin )
	ItemFlavor character = expect ItemFlavor( GetItemFlavorAssociatedCharacterOrWeapon( skin ) )
	return character
}

array<int> function Mythics_GetMythicSkinGUIDsForCharacter( ItemFlavor character )
{
	int characterGUID =  ItemFlavor_GetGUID( character )
	if( characterGUID in fileLevel.charactersGUIDToMythicSkinGUIDs )
	{
		return fileLevel.charactersGUIDToMythicSkinGUIDs[ characterGUID ]
	}
	return []
}

SettingsAssetGUID function Mythics_GetChallengeGUIDForSkinGUID( SettingsAssetGUID skinGUID )
{
	ItemFlavor skin             = GetItemFlavorByGUID( skinGUID )
	ItemFlavor character = Mythics_GetCharacterForSkin( skin )
	ItemFlavor challenge = Mythics_GetChallengeForCharacter( character )
	SettingsAssetGUID challengeGUID = ItemFlavor_GetGUID( challenge )
	return challengeGUID

}

ItemFlavor function Mythics_GetChallengeForSkin( ItemFlavor skin )
{
	Assert( ItemFlavor_GetType( skin ) == eItemType.character_skin )

	return Mythics_GetChallengeForCharacter( Mythics_GetCharacterForSkin ( skin ) )
}

int function Mythics_GetNumTiersUnlockedForSkin( entity player, ItemFlavor skin )
{
	if ( !IsValid( player ) )
		return 0

	ItemFlavor character = Mythics_GetCharacterForSkin( skin )
	array< int > allSkinGUIDs = fileLevel.charactersGUIDToMythicSkinGUIDs[ ItemFlavor_GetGUID( character ) ]
	int ownedCount = 0
	foreach ( int skinGUID in allSkinGUIDs )
	{
		if ( GRX_IsItemOwnedByPlayer_AllowOutOfDateData( GetItemFlavorByGUID( skinGUID ), player ) )
			ownedCount++
	}

	return ownedCount
}

asset function Mythics_GetStoreImageForCharacter( ItemFlavor character, int tier )
{
	Assert( IsItemFlavorStructValid( character.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )
	return fileLevel.charactersGUIDToStoreImages[ ItemFlavor_GetGUID( character ) ][ tier ]
}

string function Mythics_GetSkinBaseNameForCharacter( ItemFlavor character )
{
	Assert( IsItemFlavorStructValid( character.guid, eValidation.DONT_ASSERT ), eValidation.ASSERT )
	return fileLevel.charactersGUIDToSkinBaseName[ ItemFlavor_GetGUID( character ) ]
}







































































































