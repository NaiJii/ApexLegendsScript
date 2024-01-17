global function RTKProgressionModifiersBoost_OnInitialize
global function RTKProgressionModifiersBoost_OnDestroy
global function InitRTKProgressionModifiersMenu
global function OpenProgressionModifiersMenu
global function InitRTKProgressionModifiersInfoPanel
global function InitRTKProgressionModifiersBoostPanel
struct
{
	var menu = null
} file

global struct RTKProgressionModifiersBoostModel
{
	string title
	vector color
	string desc
	string requisiteDesc
	string tooltip
	string modifierQuantity
	asset icon
	int endTime
}

void function RTKProgressionModifiersBoost_OnInitialize( rtk_behavior self )
{
	rtk_struct xpModifiersModel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "progression_modifiers" )
	BuildProgressionModifiersBoostDataModel( self, xpModifiersModel )
	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "progression_modifiers", true ) )
	Boost_UI_MarkAllBoostsAsSeen()
}

void function RTKProgressionModifiersBoost_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "progression_modifiers" )
}

void function BuildProgressionModifiersBoostDataModel( rtk_behavior self, rtk_struct xpModifiersModel )
{
	array<RTKProgressionModifiersBoostModel> boostModel = []
	BoostTable boosts = Boost_GetActiveBoosts( GetLocalClientPlayer() )
	foreach( Boost boost in boosts )
	{
		RTKProgressionModifiersBoostModel boostData
		boostData.title = boost.boostNameLong
		boostData.desc = boost.boostDescriptionLong
		boostData.modifierQuantity = boost.uiModifierSummary
		boostData.requisiteDesc = boost.boostReqDescription
		boostData.endTime = boost.endDate
		boostData.color = Boost_GetBoostEventCategoryColor( boost )
		boostData.icon = Boost_GetBoostEventCategoryIcon( boost )
		boostModel.append( boostData )
	}
	AppendLegacyBoostsToModel( boostModel )

	rtk_array xpBoostsModel = RTKStruct_GetOrCreateScriptArrayOfStructs( xpModifiersModel, "boosts", "RTKProgressionModifiersBoostModel" )
	RTKArray_SetValue( xpBoostsModel, boostModel )
}


void function InitRTKProgressionModifiersMenu( var menu )
{
	file.menu = menu
	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )

	AddTab( menu, Hud_GetChild( menu, "ProgressionModifiersBoostPanel" ), Localize( "#PROGRESSION_MODIFIERS_BOOST_TAB_TITLE" ) )
	AddTab( menu, Hud_GetChild( menu, "ProgressionModifiersInfoPanel" ), Localize( "#ABOUT_GAMEMODE" ) )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, RTKProgressionModifiersMenuScreen_Open )
}

void function InitRTKProgressionModifiersInfoPanel( var panel )
{
	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}
void function InitRTKProgressionModifiersBoostPanel( var panel )
{
	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}

void function RTKProgressionModifiersMenuScreen_Open()
{
	Lobby_AdjustScreenFrameToMaxSize( Hud_GetChild( file.menu, "ProgressionModifiersInfoPanel" ), true )

	TabData tabData = GetTabDataForPanel( file.menu )
	tabData.centerTabs = true
	tabData.forcePrimaryNav = true
	tabData.activeTabIdx = 0
	SetTabDefsToSeasonal( tabData )
	SetTabBackground( tabData, Hud_GetChild( file.menu, "TabsBackground" ), eTabBackground.STANDARD )
	ActivateTab( tabData, tabData.activeTabIdx )
}

void function OpenProgressionModifiersMenu()
{
	if ( GetActiveMenu() == file.menu )
		return

	AdvanceMenu( file.menu )
}

RTKProgressionModifiersBoostModel function GenerateLegacyPartyUpBoostModel()
{
	
	
	int friendsQuantity = GetPartySize() - 1
	RTKProgressionModifiersBoostModel boostData
	boostData.title = "#PROGRESSION_MODIFIERS_LEGACY_PARTY_UP"
	boostData.desc = "#PROGRESSION_MODIFIERS_LEGACY_PARTY_UP_DESC"
	boostData.requisiteDesc = friendsQuantity > 0 ? "" : Localize( "#PROGRESSION_MODIFIERS_LEGACY_PARTY_UP_NOT_APPLIED" )
	boostData.modifierQuantity = friendsQuantity > 0 ? Localize("#PROGRESSION_MODIFIERS_PERCENTAGE_ADD", friendsQuantity * 5) : Localize("#PROGRESSION_MODIFIERS_PERCENTAGE_ADD_MAX", 10)
	boostData.endTime = -1 
	boostData.color = Boost_GetBoostEventCategoryColorFromCategory( eBoostCategory.ACCOUNT_XP )
	boostData.icon = Boost_GetBoostEventCategoryIconFromCategory( eBoostCategory.ACCOUNT_XP )
	return boostData
}

RTKProgressionModifiersBoostModel function GenerateLegacyXPBoostModel( int boostPercentage )
{
	
	RTKProgressionModifiersBoostModel boostData
	boostData.title = "#PROGRESSION_MODIFIERS_LEGACY_XP_UP"
	boostData.desc =  "#PROGRESSION_MODIFIERS_LEGACY_XP_UP_DESC"
	boostData.requisiteDesc = boostPercentage > 0 ? "" : Localize( "#PROGRESSION_MODIFIERS_LEGACY_XP_UP_NOT_APPLIED" )
	boostData.modifierQuantity = boostPercentage > 0 ? Localize("#PROGRESSION_MODIFIERS_PERCENTAGE_ADD", boostPercentage ) : Localize("#PROGRESSION_MODIFIERS_PERCENTAGE_ADD_MAX", 300)

	ItemFlavor currentSeason = GetLatestSeason( GetUnixTimestamp() )
	int seasonEndUnixTime    = CalEvent_GetFinishUnixTime( currentSeason )
	boostData.endTime = seasonEndUnixTime

	boostData.color = Boost_GetBoostEventCategoryColorFromCategory( eBoostCategory.ACCOUNT_XP )
	boostData.icon = Boost_GetBoostEventCategoryIconFromCategory( eBoostCategory.ACCOUNT_XP )
	return boostData
}

void function AppendLegacyBoostsToModel( array<RTKProgressionModifiersBoostModel> model )
{
	model.append( GenerateLegacyPartyUpBoostModel() )
	model.append( GenerateLegacyXPBoostModel( GetLegacyXPBoostPercentage() ) )
}
