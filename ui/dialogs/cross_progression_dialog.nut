global function InitCrossProgressionDialog

global function UI_OpenCrossProgressionDialog
global function UI_CloseCrossProgressionDialog

global function UI_CrossProgressionDialog_UpdateHeader
global function UI_CrossProgressionDialog_SetHeight

const string SFX_MENU_OPENED = "UI_Menu_Focus_Large"

struct {
	var menu
	var dialogContent
	var menuFrame
	var frameBg
} file

void function InitCrossProgressionDialog( var newMenuArg )
{
	var menu = newMenuArg
	file.menu = menu

	SetPopup( menu, true )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, CrossProgressionDialog_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, CrossProgressionDialog_OnNavigateBack )

	file.dialogContent = Hud_GetChild( menu, "DialogContent" )
	file.menuFrame = Hud_GetChild( menu, "MenuFrame" )
	file.frameBg = Hud_GetChild( menu, "DialogFrameBG" )
}

void function CrossProgressionDialog_OnOpen()
{
	EmitUISound( SFX_MENU_OPENED )
}

void function CrossProgressionDialog_OnNavigateBack()
{
	UI_CloseCrossProgressionDialog()
}

void function UI_OpenCrossProgressionDialog()
{
	AdvanceMenu( GetMenu( "CrossProgressionDialog" ) )
}

void function UI_CloseCrossProgressionDialog()
{
	if ( GetActiveMenu() == file.menu )
	{
		CloseActiveMenu()
	}
	else if ( MenuStack_Contains( file.menu ) )
	{
		if( IsDialog( GetActiveMenu() ) )
		{
			
			CloseAllMenus()
		}
		else
		{
			
			MenuStack_Remove( file.menu )
		}
	}
}

void function UI_CrossProgressionDialog_UpdateHeader( string title, string subtitle  )
{
	RuiSetString( Hud_GetRui( file.dialogContent ), "messageText", Localize( title ).toupper() )
	RuiSetString( Hud_GetRui( file.dialogContent ),  "reqsText", Localize( subtitle ).toupper() )
}

void function UI_CrossProgressionDialog_SetHeight( float height  )
{
	
	
	float actualHeight = ( GetScreenSize().height / 1080.0 ) * height

	Hud_SetHeight( file.dialogContent, int ( actualHeight ) )
	Hud_SetHeight( file.menuFrame, int ( actualHeight ) )
	Hud_SetHeight( file.frameBg, int ( actualHeight ) )
}

