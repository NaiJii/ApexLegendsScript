global function RTKSweepstakesRulesPanel_OnInitialize
global function RTKSweepstakesRulesPanel_OnDestroy

global struct RTKSweepstakesRulesPanel_Properties
{
	rtk_behavior closeButton
	rtk_behavior linkToRulesButton
}

global struct RTKSweepstakesRulesModel
{
	asset image
	array<string> texts
}

const string SWEEPSTAKES_RULES_DATA_MODEL_NAME = "sweepstakesRules"

void function RTKSweepstakesRulesPanel_OnInitialize( rtk_behavior self )
{
	rtk_struct sweepstakesRules = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, SWEEPSTAKES_RULES_DATA_MODEL_NAME, "RTKSweepstakesRulesModel" )

	RTKSweepstakesRulesModel sweepstakesRulesModel
	sweepstakesRulesModel.image = EventShop_GetSweepstakesPrizeImage(expect ItemFlavor( EventShop_GetCurrentActiveEventShop() ) )

	RTKStruct_SetValue( sweepstakesRules, sweepstakesRulesModel )

	rtk_behavior ornull closeButton = self.PropGetBehavior( "closeButton" )
	if ( closeButton != null )
	{
		expect rtk_behavior( closeButton )
		self.AutoSubscribe( closeButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			UI_CloseEventShopSweepstakesRulesDialog()
		} )
	}

	rtk_behavior ornull linkToRulesButton = self.PropGetBehavior( "linkToRulesButton" )
	if ( linkToRulesButton != null )
	{
		expect rtk_behavior( linkToRulesButton )
		self.AutoSubscribe( linkToRulesButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			LaunchExternalWebBrowser( Localize(  "#SWEEPSTALES_OFFICIAL_RULES_LINK" ), WEBBROWSER_FLAG_NONE )
		} )
	}

	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, SWEEPSTAKES_RULES_DATA_MODEL_NAME ) )
}

void function RTKSweepstakesRulesPanel_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, SWEEPSTAKES_RULES_DATA_MODEL_NAME )
}
