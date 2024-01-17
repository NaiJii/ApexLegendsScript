global function RTKStore_CreateOfferButtonModel
global function RTKOfferButton_OnInitialize
global function RTKOfferButton_OnDestroy
global function RTKOfferButton_RemoveEventListener
global function RTKOfferButton_FailedButton

global struct RTKOfferButton_Properties
{
	int offerIndex
	rtk_behavior buttonBehavior
}

global struct RTKOfferButtonModel
{
	int offerIndex

	asset offerImage
	bool newPriceShow

	int rarity

	string newPrice
	string offerName
	string offerType
	string price
	string discount
	string imageRef
	int	   pakType

	vector priceColor
	vector newPriceColor

	bool 	hasMultiplePrices
	string 	multiplePrices
}

struct PrivateData
{
	int eventListener
}

RTKOfferButtonModel function RTKStore_CreateOfferButtonModel( GRXScriptOffer offer )
{
	RTKOfferButtonModel offerButtonModel





	if( offer.titleText == "Offer Title" || offer.prices.len() == 0 )
	{
		return RTKOfferButton_FailedButton()
	}

	ItemFlavor itemFlav = offer.output.flavors[0]
	int rarity = 0

	offerButtonModel.hasMultiplePrices = false

	ItemFlavorBag ornull OriginalPrice = null

	if ( offer.originalPrice != null )
		OriginalPrice = expect ItemFlavorBag( offer.originalPrice )

	foreach ( ItemFlavor flav in offer.output.flavors )
	{
		if ( ItemFlavor_HasQuality( flav ) && ItemFlavor_GetQuality( flav ) >= rarity )
		{
			rarity = ItemFlavor_GetQuality( flav )
		}
	}

	offerButtonModel.rarity = rarity + 1
	offerButtonModel.imageRef = offer.imageRef
	offerButtonModel.offerName = offer.titleText

	if ( offer.output.flavors.len() > 1 )
		offerButtonModel.offerType = Localize( "#BUNDLE" )
	else
	{
		switch ( ItemFlavor_GetType( itemFlav ) )
		{
			case eItemType.character_skin:
				offerButtonModel.offerType = Localize( "#STORE_OFFER_TYPE_2", Localize( ItemFlavor_GetLongName( CharacterSkin_GetCharacterFlavor( itemFlav ) ) ), Localize( "#itemtype_character_skin_NAME" ) )
				break

			case eItemType.weapon_skin:
				offerButtonModel.offerType = Localize( "#STORE_OFFER_TYPE_2",Localize(  ItemFlavor_GetShortName( WeaponSkin_GetWeaponFlavor( itemFlav ) ) ), Localize( "#itemtype_character_skin_NAME" ) )
				break

			default:
				break
		}
	}

	if ( GRXOffer_IsFullyClaimed( offer ) )
	{
		offerButtonModel.price        = Localize( "#OWNED" )
		offerButtonModel.priceColor   = < 1, 1, 1 >
		offerButtonModel.newPriceShow = false
	}
	else if ( offer.prices.len() > 1 )
	{
		offerButtonModel.hasMultiplePrices = true
		offerButtonModel.multiplePrices    = Localize( "#STORE_PRICE_N_N", GRX_GetFormattedPrice( offer.prices[1], 1 ), GRX_GetFormattedPrice( offer.prices[0], 1 ) )
	}
	else
	{
		if ( OriginalPrice != null  )
		{
			offerButtonModel.price      = Localize( GRX_GetFormattedPrice( expect ItemFlavorBag( OriginalPrice ), 1  ) )
			offerButtonModel.priceColor = < 0.3, 0.3, 0.3 >

			offerButtonModel.newPriceShow = true

			offerButtonModel.newPrice      = GRX_GetFormattedPrice( offer.prices[0], 1  )
			offerButtonModel.newPriceColor = < 1, 1, 1 >

			ItemFlavorBag origPrice = expect ItemFlavorBag( OriginalPrice )

			if ( origPrice == offer.prices[0] )
				offerButtonModel.newPriceShow = false

			float originalPrice = origPrice.quantities[0].tofloat()
			float newPrice = offer.prices[0].quantities[0].tofloat()
			float discount = ( ( originalPrice - newPrice )  / originalPrice ) * 100

			offerButtonModel.discount = Localize("#STORE_BUTTON_DISCOUNT", int( discount ) )
		}
		else
		{
			offerButtonModel.newPriceShow = false
			offerButtonModel.price        = Localize( GRX_GetFormattedPrice( offer.prices[0], 1 ) )
			offerButtonModel.priceColor   = < 1, 1, 1 >
		}
	}

	return offerButtonModel
}

void function RTKOfferButton_OnInitialize( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	rtk_behavior ornull button = self.PropGetBehavior( "buttonBehavior" )

	if ( button )
	{
		expect rtk_behavior ( button )
		p.eventListener = button.AddEventListener( "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) { RTKOfferButton_OnActivate( self ) } )
	}
}

void function RTKOfferButton_OnDestroy( rtk_behavior self )
{
	RTKOfferButton_RemoveEventListener( self )
}

void function RTKOfferButton_RemoveEventListener( rtk_behavior self )
{
	rtk_behavior ornull button = self.PropGetBehavior( "buttonBehavior" )

	int listenerID = GetOnPressedEventListener( self )

	if ( button && listenerID != RTKEVENT_INVALID )
	{
		expect rtk_behavior ( button )
		button.RemoveEventListener( "OnPressed", listenerID )
	}
}

void function RTKOfferButton_OnActivate( rtk_behavior self )
{









}

int function GetOnPressedEventListener( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	return p.eventListener
}



RTKOfferButtonModel function RTKOfferButton_FailedButton()
{
	RTKOfferButtonModel offerButtonModel

	int rarity = 0
	ItemFlavorBag ornull OriginalPrice = null
	rarity                        = 1
	offerButtonModel.rarity       = rarity + 1
	offerButtonModel.offerImage   = $"ui_image/rui/menu/image_download/image_load_failed_store_vertical.rpak"
	offerButtonModel.offerName    = Localize( "" )
	offerButtonModel.newPriceShow = false
	offerButtonModel.price        = Localize( "" )
	offerButtonModel.priceColor   = < 1, 1, 1 >

	return offerButtonModel
}

