global function RTKSweepstakesFlowPanel_OnInitialize
global function RTKSweepstakesFlowPanel_OnDestroy
global function RTKMutator_AgreeToRulesText
global function RTKMutator_ConfirmEntryText
global function RTKMutator_NumberTitleText

global struct RTKSweepstakesFlowPanel_Properties
{
	rtk_panel tokenSelectorClose
	rtk_panel tokenSelectorAgreeToRules
	rtk_panel tokenSelectorLinkToRules
	rtk_panel confirmEntryBack
	rtk_panel confirmEntryButton
	rtk_panel doneCloseButton
	rtk_behavior multiItemSelector
}

global struct RTKSweepstakesFlowModel
{
	int flow
	string titleText
	asset image
	int purchaseCount
	int purchaseLimit
	int availablePurchases
	int price
	int tokenCount
	int totalEntries
	asset prizeImage
	bool canPurchaseTokens
}

global enum eSweepstakesFlow
{
	TOKEN_SELECTOR,
	CONFIRM_ENTRY,
	DONE,
	_COUNT,
}

const string SWEEPSTAKES_FLOW_DATA_MODEL_NAME = "sweepstakesFlow"

void function RTKSweepstakesFlowPanel_OnInitialize( rtk_behavior self )
{
	entity player = GetLocalClientPlayer()
	rtk_struct sweepstakesFlow = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, SWEEPSTAKES_FLOW_DATA_MODEL_NAME, "RTKSweepstakesFlowModel" )

	GRXScriptOffer ornull offer = GetSweepstakesOffer()
	if ( offer != null )
	{
		expect GRXScriptOffer( offer )
		RTKSweepstakesFlowModel sweepstakesFlowModel
		sweepstakesFlowModel.flow = eSweepstakesFlow.TOKEN_SELECTOR
		sweepstakesFlowModel.titleText = offer.titleText
		sweepstakesFlowModel.image = ItemFlavor_GetIcon( expect ItemFlavor( EventShop_GetCoreItemFlav( offer ) ) )
		sweepstakesFlowModel.purchaseCount = offer.purchaseCount
		sweepstakesFlowModel.purchaseLimit = offer.purchaseLimit
		sweepstakesFlowModel.availablePurchases = offer.purchaseLimit - offer.purchaseCount
		sweepstakesFlowModel.price = EventShop_GetItemPrice( offer )
		sweepstakesFlowModel.tokenCount = RTKSweepstakesFlow_CanPurchaseTokens( offer, 1 ) ? 1 : 0
		sweepstakesFlowModel.totalEntries = AcidWraith_GetCurrentSweepstakesEntryCount( player )
		sweepstakesFlowModel.prizeImage = EventShop_GetSweepstakesPrizeImage(expect ItemFlavor( EventShop_GetCurrentActiveEventShop() ) )
		sweepstakesFlowModel.canPurchaseTokens = RTKSweepstakesFlow_CanPurchaseTokens( offer, 1 )

		RTKStruct_SetValue( sweepstakesFlow, sweepstakesFlowModel )
	}

	rtk_behavior multiItemSelector = self.PropGetBehavior( "multiItemSelector" )
	RTKMultiItemSelector_AddOnSubtractionListener( multiItemSelector, RTKSweepstakesFlowPanel_OnSubtractTokenCounter )
	RTKMultiItemSelector_AddOnAdditionListener( multiItemSelector, RTKSweepstakesFlowPanel_OnAddTokenCounter )

	
	rtk_panel ornull tokenSelectorClose = self.PropGetPanel( "tokenSelectorClose" )
	if ( tokenSelectorClose != null )
	{
		expect rtk_panel( tokenSelectorClose )
		rtk_behavior ornull button = tokenSelectorClose.FindBehaviorByTypeName( "Button" )
		if ( button != null )
		{
			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
				UI_CloseEventShopSweepstakesFlowDialog()
			} )
		}
	}

	rtk_panel ornull tokenSelectorAgreeToRules = self.PropGetPanel( "tokenSelectorAgreeToRules" )
	if ( tokenSelectorAgreeToRules != null )
	{
		expect rtk_panel( tokenSelectorAgreeToRules )
		rtk_behavior ornull button = tokenSelectorAgreeToRules.FindBehaviorByTypeName( "Button" )
		if ( button != null )
		{
			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, sweepstakesFlow ) {
				RTKStruct_SetInt( sweepstakesFlow, "flow", eSweepstakesFlow.CONFIRM_ENTRY )
			} )
		}
	}

	rtk_panel ornull tokenSelectorLinkToRules = self.PropGetPanel( "tokenSelectorLinkToRules" )
	if ( tokenSelectorLinkToRules != null )
	{
		expect rtk_panel( tokenSelectorLinkToRules )
		rtk_behavior ornull button = tokenSelectorLinkToRules.FindBehaviorByTypeName( "Button" )
		if ( button != null )
		{
			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
				LaunchExternalWebBrowser( Localize(  "#SWEEPSTALES_OFFICIAL_RULES_LINK" ), WEBBROWSER_FLAG_NONE )
			} )
		}
	}


	
	rtk_panel ornull confirmEntryButton = self.PropGetPanel( "confirmEntryButton" )
	if ( confirmEntryButton != null )
	{
		expect rtk_panel( confirmEntryButton )
		rtk_behavior ornull button = confirmEntryButton.FindBehaviorByTypeName( "Button" )
		if ( button != null )
		{
			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, sweepstakesFlow, offer, player ) {
				PurchaseDialogConfig pdc
				pdc.offer = offer
				pdc.isEventShopDialog = true
				pdc.quantity = RTKStruct_GetInt(sweepstakesFlow, "tokenCount")
				pdc.onPurchaseResultCallback = RTKSweepstakesFlowPanel_OnPurchaseSuccessful
				PurchaseDialog( pdc )
			} )
		}
	}

	rtk_panel ornull confirmEntryBack = self.PropGetPanel( "confirmEntryBack" )
	if ( confirmEntryBack != null )
	{
		expect rtk_panel( confirmEntryBack )
		rtk_behavior ornull button = confirmEntryBack.FindBehaviorByTypeName( "Button" )
		if ( button != null )
		{
			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, sweepstakesFlow ) {
				RTKStruct_SetInt( sweepstakesFlow, "flow", eSweepstakesFlow.TOKEN_SELECTOR )
			} )
		}
	}


	
	rtk_panel ornull doneCloseButton = self.PropGetPanel( "doneCloseButton" )
	if ( doneCloseButton != null )
	{
		expect rtk_panel( doneCloseButton )
		rtk_behavior ornull button = doneCloseButton.FindBehaviorByTypeName( "Button" )
		if ( button != null )
		{
			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
				UI_CloseEventShopSweepstakesFlowDialog()
			} )
		}
	}

	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, SWEEPSTAKES_FLOW_DATA_MODEL_NAME ) )
}

void function RTKSweepstakesFlowPanel_OnPurchaseSuccessful( bool wasSuccessful )
{
	if ( wasSuccessful )
	{
		thread function() : ()
		{
			wait 1.6

			string sweepstakesFlowPath = RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, SWEEPSTAKES_FLOW_DATA_MODEL_NAME )

			if ( RTKDataModel_HasDataModel( sweepstakesFlowPath ) )
			{
				rtk_struct sweepstakesFlow = RTKDataModel_GetStruct( sweepstakesFlowPath )
				RTKStruct_SetInt( sweepstakesFlow, "flow", eSweepstakesFlow.DONE )
				RTKStruct_SetInt( sweepstakesFlow, "totalEntries", AcidWraith_GetCurrentSweepstakesEntryCount( GetLocalClientPlayer() ) )
			}
		}()
	}
}

void function RTKSweepstakesFlowPanel_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, SWEEPSTAKES_FLOW_DATA_MODEL_NAME )
}

void function RTKSweepstakesFlowPanel_OnSubtractTokenCounter()
{
	RTKSweepstakesFlowPanel_TokenCounter( false )
}

void function RTKSweepstakesFlowPanel_OnAddTokenCounter()
{
	RTKSweepstakesFlowPanel_TokenCounter( true )
}

void function RTKSweepstakesFlowPanel_TokenCounter( bool isAddition )
{
	rtk_struct sweepstakesFlow = RTKDataModel_GetStruct( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, SWEEPSTAKES_FLOW_DATA_MODEL_NAME ) )
	int counter = RTKStruct_GetInt( sweepstakesFlow, "tokenCount")
	bool canPurchaseTokens = RTKStruct_GetBool( sweepstakesFlow, "canPurchaseTokens")

	GRXScriptOffer ornull offer = GetSweepstakesOffer()
	if ( offer != null )
	{
		expect GRXScriptOffer( offer )

		if ( isAddition )
		{
			if ( ( counter < offer.purchaseLimit - offer.purchaseCount ) && RTKSweepstakesFlow_CanPurchaseTokens( offer, counter + 1 ) )
				counter++
		}
		else
		{
			if ( counter > 0 )
				counter--
		}

		RTKStruct_SetBool( sweepstakesFlow, "canPurchaseTokens", counter != 0 && RTKSweepstakesFlow_CanPurchaseTokens( offer, counter ) )
		RTKStruct_SetInt( sweepstakesFlow, "tokenCount", counter )
	}
}

bool function RTKSweepstakesFlow_CanPurchaseTokens( GRXScriptOffer offer, int num )
{
	return GRX_CanAfford( offer.prices[0], num ) && ( offer.purchaseLimit - offer.purchaseCount > 0 )
}

string function RTKMutator_AgreeToRulesText( int tokenCount, int price )
{
	ItemFlavor ornull event = EventShop_GetCurrentActiveEventShop()
	expect ItemFlavor( event )

	return Localize( "#SWEEPSTAKES_AGREE_TO_RULES", GetFormattedValueForCurrency( tokenCount * price, GRX_CURRENCY_EVENT ) )
}

string function RTKMutator_ConfirmEntryText( int tokenCount )
{
	rtk_struct sweepstakesFlow = RTKDataModel_GetStruct( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, SWEEPSTAKES_FLOW_DATA_MODEL_NAME ) )
	string titleText = RTKStruct_GetString( sweepstakesFlow, "titleText" )

	return Localize( "#SWEEPSTAKES_CONFIRM_ENTRY_BUTTON", tokenCount, Localize( titleText ) )
}

string function RTKMutator_NumberTitleText( string titleText, int tokenCount )
{
	return Localize( "#SWEEPSTAKES_NUM_TITLE", tokenCount, Localize( titleText ) )
}
