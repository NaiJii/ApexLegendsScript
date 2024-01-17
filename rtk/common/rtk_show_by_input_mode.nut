global function RTKShowByInputMode_OnInitialize
global function RTKShowByInputMode_OnDestroy

global struct RTKShowByInputMode_Properties
{
	bool showIfController
	bool showIfMKB
}

struct PrivateData
{
	void functionref( bool input ) callbackFunc
}

void function RTKShowByInputMode_OnInitialize( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	RTKShowByInputMode_OnInputModeUpdated( self )

	p.callbackFunc = void function( bool input ) : ( self ) { RTKShowByInputMode_OnInputModeUpdated( self ) }
	AddUICallback_InputModeChanged( p.callbackFunc )
}

void function RTKShowByInputMode_OnDestroy( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	RemoveUICallback_InputModeChanged( p.callbackFunc )
}
void function RTKShowByInputMode_OnInputModeUpdated( rtk_behavior self )
{
	bool isController = IsControllerModeActive()
	bool visible      = ( isController && self.PropGetBool( "showIfController" ) ) || ( !isController && self.PropGetBool( "showIfMKB" ) )
	self.GetPanel().SetVisible( visible )
}
