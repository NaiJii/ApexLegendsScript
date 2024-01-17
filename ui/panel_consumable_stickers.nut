global function InitConsumableStickersPanel
global function ConsumableStickersPanel_SetConsumable
global function ConsumableStickersPanel_GetCurrentConsumable





struct PanelData
{
	var panel
	var stickersOwnedRui
	var stickerListPanel
	var blurbPanel

	int               consumable = -1
	array<ItemFlavor> stickerItemList
}

struct
{
	table<var, PanelData> panelDataMap

	var               activePanel = null
	int               currentConsumable
	ItemFlavor ornull focusedItem = null
	ItemFlavor ornull unappliedPreviewItem = null

	table<LoadoutEntry, ItemFlavorLoadoutSlotDidChangeFuncType> registeredLoadoutChangeCallbacks
	table<var, void functionref( var )> registeredGetFocusCallbacks
	table<var, void functionref( var )> registeredLoseFocusCallbacks





} file

void function InitConsumableStickersPanel( var panel )
{
	Assert( !(panel in file.panelDataMap) )
	PanelData pd
	file.panelDataMap[ panel ] <- pd

	pd.stickersOwnedRui = Hud_GetRui( Hud_GetChild( panel, "StickersOwned" ) )
	pd.stickerListPanel = Hud_GetChild( panel, "StickerListPanel" )

	pd.blurbPanel = Hud_GetChild( panel, "SkinBlurb" )
	Hud_SetVisible( pd.blurbPanel, false )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, ConsumableStickersPanel_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, ConsumableStickersPanel_OnHide )
	AddPanelEventHandler_FocusChanged( panel, ConsumableStickersPanel_OnFocusChanged )

	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )



	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_EQUIP", "#X_BUTTON_EQUIP", null, CustomizeMenus_IsFocusedItemEquippable )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_CLEAR", "#X_BUTTON_CLEAR", null, IsUnequipValid )

	AddPanelFooterOption( panel, LEFT, BUTTON_Y, false, "#Y_BUTTON_VIEW_STICKER", "#Y_BUTTON_VIEW_STICKER", void function ( var button ) : () {
		PreviewUnappliedSticker() 

		if ( IsControllerModeActive() ) 
			EmitUISound( "UI_Menu_Accept" )
	}, IsViewStickerValid )

	string viewObjectLabel = GetViewObjectLabel( panel )
	AddPanelFooterOption( panel, LEFT, BUTTON_Y, false, viewObjectLabel, viewObjectLabel, void function( var button ) : () {
		PreviewAppliedStickers( -1 )

		if ( IsControllerModeActive() ) 
			EmitUISound( "UI_Menu_Accept" )
	}, IsViewObjectValid )

}


string function GetViewObjectLabel( var panel )
{
	string viewObjectLabel

	switch ( Hud_GetHudName( panel ) )
	{
		case "StickersPanel0":
			viewObjectLabel = "#Y_BUTTON_VIEW_HEALTH_INJECTOR"
			break

		case "StickersPanel1":
			viewObjectLabel = "#Y_BUTTON_VIEW_SHIELD_CELL"
			break

		case "StickersPanel2":
			viewObjectLabel = "#Y_BUTTON_VIEW_SHIELD_BATTERY"
			break

		case "StickersPanel3":
			viewObjectLabel = "#Y_BUTTON_VIEW_PHOENIX_KIT"
			break

		default:
			Assert( false, "Unexpected panel:" + Hud_GetHudName( panel ) )
	}

	return viewObjectLabel
}


bool function IsUnequipValid()
{
	return ( CustomizeMenus_IsFocusedItemUnlocked() && !CustomizeMenus_IsFocusedItemEquippable() )
}


bool function IsViewStickerValid()
{
	if ( file.focusedItem != null && file.focusedItem != file.unappliedPreviewItem )
		return true

	return false
}

bool function IsViewObjectValid()
{
	if ( file.unappliedPreviewItem != null && ( file.unappliedPreviewItem == file.focusedItem || ( IsControllerModeActive() && file.focusedItem == null ) ) )
		return true

	return false
}


void function ConsumableStickersPanel_SetConsumable( var panel, int consumable )
{
	PanelData pd = file.panelDataMap[panel]
	pd.consumable = consumable
}

int function ConsumableStickersPanel_GetCurrentConsumable()
{
	return file.currentConsumable
}

void function ConsumableStickersPanel_OnShow( var panel )
{
	file.activePanel = panel
	if ( CanRunClientScript() )
		RunClientScript( "EnableModelTurn" )

	thread TrackIsOverScrollBar( file.panelDataMap[panel].stickerListPanel )

	ConsumableStickersPanel_Update( panel )
}

void function ConsumableStickersPanel_OnHide( var panel )
{
	Signal( uiGlobal.signalDummy, "TrackIsOverScrollBar" )
	if ( CanRunClientScript() )
		RunClientScript( "EnableModelTurn" )
	ConsumableStickersPanel_Update( panel )
}

void function ConsumableStickersPanel_Update( var panel )
{
	PanelData pd    = file.panelDataMap[panel]
	var scrollPanel = Hud_GetChild( pd.stickerListPanel, "ScrollPanel" )

	

	UnregisterAllGetFocusCallbacks()
	UnregisterAllLoseFocusCallbacks()
	UnregisterAllLoadoutChangeCallbacks()


	foreach ( int stickerItemIdx, ItemFlavor unused in pd.stickerItemList )
	{
		var button = Hud_GetChild( scrollPanel, "GridButton" + stickerItemIdx )
		CustomizeButton_UnmarkForUpdating( button )
	}
	pd.stickerItemList.clear()

	
	if ( IsPanelActive( panel ) && pd.consumable != -1 )
	{
		file.currentConsumable = pd.consumable
		array<LoadoutEntry> entries
		for ( int stickerSlot = 0; stickerSlot < GetMaxStickersForObjectType( file.currentConsumable ); stickerSlot++ )
		{
			LoadoutEntry entry = Loadout_Sticker( file.currentConsumable, stickerSlot )
			if ( stickerSlot == 1 )
				entries.insert( 0, entry ) 
			else
				entries.append( entry )


			ItemFlavorLoadoutSlotDidChangeFuncType loadoutChangeCallback = void function( EHI playerEHI, ItemFlavor stickerItem ) : ( stickerSlot ) {
				PreviewAppliedStickers( stickerSlot )
			}
			AddCallback_ItemFlavorLoadoutSlotDidChange_SpecificPlayer( LocalClientEHI(), entry, loadoutChangeCallback )
			file.registeredLoadoutChangeCallbacks[entry] <- loadoutChangeCallback

		}

		pd.stickerItemList = GetLoadoutItemsSortedForMenu( entries, Sticker_GetSortOrdinal )

		for ( int i = pd.stickerItemList.len() - 1; i >= 0; i-- )
		{
			if ( Sticker_IsTheEmpty( pd.stickerItemList[i] ) )
				pd.stickerItemList.remove( i )
		}

		bool ignoreDefaultItemForCount = true
		bool shouldIgnoreOtherSlots = true
		int ownedCount = CustomizeMenus_GetOwnedCount( entries[0], pd.stickerItemList, ignoreDefaultItemForCount, shouldIgnoreOtherSlots )
		RuiSetInt( pd.stickersOwnedRui, "ownedCount", ownedCount )

		Hud_InitGridButtons( pd.stickerListPanel, pd.stickerItemList.len() )

		foreach ( int stickerItemIdx, ItemFlavor stickerItem in pd.stickerItemList )
		{
			var button = Hud_GetChild( scrollPanel, "GridButton" + stickerItemIdx )



			CustomizeButton_UpdateAndMarkForUpdating( button, entries, stickerItem, null, null, false, null, null, [], void function( var button ) : () { UpdatePreview() } )
			RegisterGetFocusCallback( button, stickerItem )
			RegisterLoseFocusCallback( button )


			Hud_ClearToolTipData( button )

			var rui = Hud_GetRui( button )
			RuiDestroyNestedIfAlive( rui, "badge" )
			RuiSetBool( rui, "displayQuality", true )
			RuiSetBool( rui, "displayShimmer", true )

			var nestedRui = CreateNestedRuiForSticker( rui, "badge", stickerItem )

			ToolTipData toolTipData
			toolTipData.titleText = Localize( ItemFlavor_GetLongName( stickerItem ) )
			toolTipData.descText = Localize( ItemFlavor_GetTypeName( stickerItem ) )
			toolTipData.tooltipFlags = toolTipData.tooltipFlags | eToolTipFlag.INSTANT_FADE_IN
			Hud_SetToolTipData( button, toolTipData )
		}







		PreviewAppliedStickers()


		Hud_ScrollToTop( pd.stickerListPanel )
	}
}


void function UnregisterAllLoadoutChangeCallbacks()
{
	foreach ( entry, loadoutChangeCallback in file.registeredLoadoutChangeCallbacks )
		RemoveCallback_ItemFlavorLoadoutSlotDidChange_SpecificPlayer( LocalClientEHI(), entry, loadoutChangeCallback )
	file.registeredLoadoutChangeCallbacks.clear()
}

void function RegisterGetFocusCallback( var button, ItemFlavor stickerItem )
{
	void functionref( var button ) func = void function( var button ) : ( stickerItem ) {
		file.focusedItem = stickerItem

#if DEV
			if ( InputIsButtonDown( KEY_LSHIFT ) )
				printt( "\"" + Localize( ItemFlavor_GetLongName( stickerItem ) ) + "\" grx ref is: " + GetGlobalSettingsString( ItemFlavor_GetAsset( stickerItem ), "grxRef" ) )
#endif
	}

	Hud_AddEventHandler( button, UIE_GET_FOCUS, func )
	file.registeredGetFocusCallbacks[button] <- func
}

void function RegisterLoseFocusCallback( var button )
{
	void functionref( var button ) func = void function( var button ) : () { file.focusedItem = null }
	Hud_AddEventHandler( button, UIE_LOSE_FOCUS, func )
	file.registeredLoseFocusCallbacks[button] <- func
}

void function UnregisterAllGetFocusCallbacks()
{
	foreach ( button, func in file.registeredGetFocusCallbacks )
		Hud_RemoveEventHandler( button, UIE_GET_FOCUS, func )

	file.registeredGetFocusCallbacks.clear()
}

void function UnregisterAllLoseFocusCallbacks()
{
	foreach ( button, func in file.registeredLoseFocusCallbacks )
		Hud_RemoveEventHandler( button, UIE_LOSE_FOCUS, func )

	file.registeredLoseFocusCallbacks.clear()
}


void function ConsumableStickersPanel_OnFocusChanged( var panel, var oldFocus, var newFocus )
{
	if ( !IsValid( panel ) ) 
		return

	if ( GetParentMenu( panel ) != GetActiveMenu() )
		return

	UpdateFooterOptions()
}



















void function UpdatePreview()
{
	Assert( file.focusedItem != null )

	if ( file.focusedItem != file.unappliedPreviewItem )
		PreviewUnappliedSticker()
	else
		PreviewAppliedStickers()
}

void function PreviewAppliedStickers( int stickerSlot = -1 )
{
	file.unappliedPreviewItem = null

	UI_SetPresentationType( GetStickerPresentationType( file.currentConsumable ) )
	if ( CanRunClientScript() )
		RunClientScript( "UIToClient_PreviewAppliedStickers", file.currentConsumable, stickerSlot )
	UpdateFooterOptions()
	UpdateStoryBlurb()
}

void function PreviewUnappliedSticker()
{
	Assert( file.focusedItem != null )

	file.unappliedPreviewItem = file.focusedItem

	UI_SetPresentationType( ePresentationType.UNAPPLIED_STICKER )
	if ( CanRunClientScript() )
		RunClientScript( "UIToClient_PreviewUnappliedSticker", ItemFlavor_GetGUID( expect ItemFlavor( file.focusedItem ) ) )
	UpdateFooterOptions()
	UpdateStoryBlurb()
}

void function UpdateStoryBlurb()
{
	if ( file.activePanel == null )
		return

	var blurbPanel = file.panelDataMap[ file.activePanel ].blurbPanel
	ItemFlavor ornull stickerItem = file.unappliedPreviewItem

	if ( stickerItem != null && Sticker_HasStoryBlurb( expect ItemFlavor( stickerItem ) ) )
	{
		expect ItemFlavor( stickerItem )

		Hud_SetVisible( blurbPanel, true )
		int quality = 0
		if ( ItemFlavor_HasQuality( stickerItem ) )
			quality = ItemFlavor_GetQuality( stickerItem )

		var rui = Hud_GetRui( blurbPanel )
		RuiSetString( rui, "characterName", ItemFlavor_GetShortName( stickerItem ) )
		RuiSetString( rui, "skinNameText", ItemFlavor_GetLongName( stickerItem ) )
		RuiSetString( rui, "bodyText", Sticker_GetStoryBlurbBodyText( stickerItem ) )
		RuiSetFloat3( rui, "characterColor", SrgbToLinear( GetKeyColor( COLORID_TEXT_LOOT_TIER0, quality + 1 ) / 255.0 ) )
		RuiSetGameTime( rui, "startTime", ClientTime() )
	}
	else
	{
		Hud_SetVisible( blurbPanel, false )
	}
}













































                            
