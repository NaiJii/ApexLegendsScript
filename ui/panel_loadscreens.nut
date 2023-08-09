





global function InitLoadscreenPanel


struct
{

		var               panel
		
		var               listPanel
		var               scrollPanel
		var               descriptionElem
		array<ItemFlavor> loadscreenList
		var               loadscreenElem





} file









void function InitLoadscreenPanel( var panel )
{
	file.panel = panel
	file.listPanel = Hud_GetChild( panel, "LoadscreenList" )
	
	file.loadscreenElem = Hud_GetChild( panel, "LoadscreenImage" )
	file.descriptionElem = Hud_GetChild( panel, "DescriptionText" )

	SetPanelTabTitle( panel, "#TAB_CUSTOMIZE_LOADSCREEN" )
	

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, LoadscreenPanel_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, LoadscreenPanel_OnHide )
	AddPanelEventHandler_FocusChanged( panel, LoadscreenPanel_OnFocusChanged )

	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
	AddPanelFooterOption( panel, LEFT, BUTTON_A, false, "#A_BUTTON_SELECT", "", null, CustomizeMenus_IsFocusedItem )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_EQUIP", "#X_BUTTON_EQUIP", null, CustomizeMenus_IsFocusedItemEquippable )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_UNLOCK", "#X_BUTTON_UNLOCK", null, CustomizeMenus_IsFocusedItemLocked )


	var listPanel = file.listPanel
	void functionref( var ) func = (
	void function( var button ) : ( listPanel )
	{
		SetOrClearFavoriteFromFocus( listPanel )
	}
	)
#if PC_PROG_NX_UI
		AddPanelFooterOption( panel, LEFT, BUTTON_Y, false, "#Y_BUTTON_SET_FAVORITE", "#Y_BUTTON_SET_FAVORITE", func, CustomizeMenus_IsFocusedItemFavoriteable )
		AddPanelFooterOption( panel, LEFT, BUTTON_Y, false, "#Y_BUTTON_CLEAR_FAVORITE", "#Y_BUTTON_CLEAR_FAVORITE", func, CustomizeMenus_IsFocusedItemFavorite )
#else
		AddPanelFooterOption( panel, RIGHT, BUTTON_Y, false, "#Y_BUTTON_SET_FAVORITE", "#Y_BUTTON_SET_FAVORITE", func, CustomizeMenus_IsFocusedItemFavoriteable )
		AddPanelFooterOption( panel, RIGHT, BUTTON_Y, false, "#Y_BUTTON_CLEAR_FAVORITE", "#Y_BUTTON_CLEAR_FAVORITE", func, CustomizeMenus_IsFocusedItemFavorite )
#endif
}

void function LoadscreenPanel_OnShow( var panel )
{
	AddCallback_OnTopLevelCustomizeContextChanged( panel, LoadscreenPanel_Update )
	LoadscreenPanel_Update( panel )
	AddCallback_ItemFlavorLoadoutSlotDidChange_SpecificPlayer( LocalClientEHI(), Loadout_Loadscreen(), OnLoadscreenEquipChanged )
	RegisterStickMovedCallback( ANALOG_RIGHT_Y, FocusDescriptionForScrolling )
}


void function LoadscreenPanel_OnHide( var panel )
{
	RemoveCallback_OnTopLevelCustomizeContextChanged( panel, LoadscreenPanel_Update )
	LoadscreenPanel_Update( panel )
	RemoveCallback_ItemFlavorLoadoutSlotDidChange_SpecificPlayer( LocalClientEHI(), Loadout_Loadscreen(), OnLoadscreenEquipChanged )
	DeregisterStickMovedCallback( ANALOG_RIGHT_Y, FocusDescriptionForScrolling )
}

void function FocusDescriptionForScrolling(  ... )
{





	if( !Hud_IsFocused( file.descriptionElem ) )
		Hud_SetFocused( file.descriptionElem )
}

void function OnLoadscreenEquipChanged( EHI playerEHI, ItemFlavor flavor )
{
	if ( GetPlaylistVarBool( Lobby_GetSelectedPlaylist(), "force_level_loadscreen", false ) )
		Lobby_UpdateLoadscreenFromPlaylist()
	else
		thread Loadscreen_SetCustomLoadscreen( flavor )
}


void function LoadscreenPanel_Update( var panel )
{
	var scrollPanel = Hud_GetChild( file.listPanel, "ScrollPanel" )

	
	foreach ( int flavIdx, ItemFlavor unused in file.loadscreenList )
	{
		var button = Hud_GetChild( scrollPanel, "GridButton" + flavIdx )
		CustomizeButton_UnmarkForUpdating( button )
	}
	file.loadscreenList.clear()

	RunClientScript( "UpdateLoadscreenPreviewMaterial", file.loadscreenElem, file.descriptionElem, 0 )

	
	if ( IsPanelActive( file.panel ) )
	{
		LoadoutEntry entry = Loadout_Loadscreen()
		file.loadscreenList = GetLoadoutItemsSortedForMenu( [entry], Loadscreen_GetSortOrdinal )

		Hud_InitGridButtons( file.listPanel, file.loadscreenList.len() )
		foreach ( int flavIdx, ItemFlavor flav in file.loadscreenList )
		{
			var button = Hud_GetChild( scrollPanel, "GridButton" + flavIdx )
			CustomizeButton_UpdateAndMarkForUpdating( button, [entry], flav, PreviewLoadscreen, null )
		}

		
	}
}


void function LoadscreenPanel_OnFocusChanged( var panel, var oldFocus, var newFocus )
{
	if ( !IsValid( panel ) ) 
		return
	if ( GetParentMenu( panel ) != GetActiveMenu() )
		return

	UpdateFooterOptions()
}


void function PreviewLoadscreen( ItemFlavor flav )
{
	RunClientScript( "UpdateLoadscreenPreviewMaterial", file.loadscreenElem, file.descriptionElem, ItemFlavor_GetGUID( flav ) )
}



















































































