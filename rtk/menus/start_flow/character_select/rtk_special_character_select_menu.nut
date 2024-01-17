global function InitSpecialCharacterSelectMenu

void function InitSpecialCharacterSelectMenu( var menu )
{
	UI_SetSpecialCharacterMenu( menu )

	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, UI_OnSpecialCharacterSelectMenu_NavBack )
	AddMenuFooterOption( menu, RIGHT, BUTTON_Y, true, "", "", UI_OnToggleMuteButtonClick, UI_ShouldShowToggleMuteFooter ) 
	AddMenuFooterOption( menu, RIGHT, KEY_F, true, "", "", UI_OnToggleMuteButtonClick, UI_ShouldShowToggleMuteFooter ) 

	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, void function() {
		RunClientScript( "OnCharacterSelectMenuClosed_RemoveCallbacks" )
	} )
}

void function UI_OnSpecialCharacterSelectMenu_NavBack()
{
	
	
}

void function UI_OnToggleMuteButtonClick( var button )
{
	if ( CanRunClientScript() )
		RunClientScript( "UIToClient_ToggleMute" )
}

bool function UI_ShouldShowToggleMuteFooter()
{
	return IsFullyConnected() ? GetCurrentPlaylistVarBool( "squad_mute_legend_select_enable", true ) : false
}

