#if PC_PROG_NX_UI


global function UICodeCallback_OperationModeChanged






global function IsNxSwitchingMode

bool isNxSwitchingMode = false


void function UICodeCallback_OperationModeChanged()
{
	if ( IsNxHandheldMode() )
		printt( "UIScript: Switching to Handheld" )
	else
		printt( "UIScript: Switching to Dock" )

	var activeMenu = GetActiveMenu()

	if ( activeMenu && GetActiveMenuName() == "CharacterSelectMenuNew" )
		RunClientScript( "CharacterSelect_UpdateMenuButtons" )

	if ( activeMenu && GetActiveMenuName() == "CustomizeCharacterMenu" )
		RunClientScript( "ClearBattlePassItem" )

	isNxSwitchingMode = true

	if ( activeMenu != null )
	{
		if ( uiGlobal.menuData[ activeMenu ].hideFunc != null )
			uiGlobal.menuData[ activeMenu ].hideFunc()

		if ( uiGlobal.menuData[ activeMenu ].showFunc != null )
			uiGlobal.menuData[ activeMenu ].showFunc()

		UpdateMenuTabs()
	}

	if ( uiGlobal.activePanels.len() != 0 )
	{
		var activePanel = uiGlobal.activePanels.top()
		HidePanelInternal( activePanel )
		ShowPanelInternal( activePanel )
	}

	isNxSwitchingMode = false

	
	
	
	
		
		
		
			
		
		
		
			
		
		
		
			
		
		
		
			
		
		
	

	
	
		

		
		
		
			
		
		
		
			
		
		
	

	
	if( activeMenu != null && ( uiGlobal.menuData[ activeMenu ].isPopup || uiGlobal.menuData[ activeMenu ].isDialog ) )
	{
		array<var> menuStack = MenuStack_GetCopy()
		foreach ( index, currMenu in menuStack )
		{
			if (Hud_IsVisible( currMenu ))
			{
				if ( uiGlobal.menuData[ currMenu ].hideFunc != null )
					uiGlobal.menuData[ currMenu ].hideFunc()

				if ( uiGlobal.menuData[ currMenu ].showFunc != null )
					uiGlobal.menuData[ currMenu ].showFunc()
			}
		}

		foreach ( var panel in uiGlobal.activePanels )
		{
			if ( uiGlobal.panelData[ panel ].isCurrentlyShown )
			{
				HidePanelInternal( panel )
				ShowPanelInternal( panel )
			}
		}
	}

	printt( "UIScript: Switch Completed" )
}














bool function IsNxSwitchingMode()
{
	return isNxSwitchingMode
}
#endif

