global function RTKSizeToScreen_OnInitialize

global struct RTKSizeToScreen_Properties
{
	bool setHeight = false
	bool setWidth = false

	float heightOffset = 0.0
	float widthOffset = 0.0
}
void function RTKSizeToScreen_OnInitialize( rtk_behavior self )
{
	UISize screenSize = GetScreenSize()
	rtk_panel ornull panel = self.GetPanel()

	if( panel == null )
		return

	expect rtk_panel( panel )

	float heightOffset = self.PropGetFloat( "heightOffset" )
	float widthOffset = self.PropGetFloat( "widthOffset" )

	if( self.PropGetBool( "setHeight" ) )
		panel.SetHeight( screenSize.height + heightOffset )

	if( self.PropGetBool( "setWidth" ) )
		panel.SetWidth( screenSize.width + widthOffset )
}
