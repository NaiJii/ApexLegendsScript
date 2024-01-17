global function RTKExternalImage_OnUpdate

global struct RTKExternalImage_Properties
{
	string imageRef = ""
	asset  fallbackImage = $""
	int	   pakType = 1
}

struct PrivateData
{
	bool hasLoaded = false
	rtk_panel ornull spinner = null
}


void function RTKExternalImage_OnUpdate( rtk_behavior self, float deltaTime )
{

	if ( !GetConVarBool( "assetdownloads_enabled" ) )
		return

	PrivateData p
	self.Private( p )

	if ( p.hasLoaded )
		return

	string imageRef = self.PropGetString( "imageRef" )

	if ( imageRef == "" )
		return

	asset image = $""

	if ( IsImagePakLoading( imageRef ) )
	{
		CreateSpinner( self, p )
		return
	}

	if ( DidImagePakLoadFail( imageRef ) )
	{
		DestroySpinner( p )
		p.hasLoaded = true
		self.GetPanel().FindBehaviorByTypeName( "Image" ).PropSetAssetPath( "assetPath" , self.PropGetAssetPath( "fallbackImage" ) )
		return
	}

	DestroySpinner( p )

	image =  GetDownloadedImageAsset( imageRef, imageRef, self.PropGetInt( "pakType" ) )
	p.hasLoaded = true
	self.GetPanel().FindBehaviorByTypeName( "Image" ).PropSetAssetPath( "assetPath" , image  )
}

void function CreateSpinner( rtk_behavior self, PrivateData p )
{
	if ( p.spinner == null  )
	{
		p.spinner = RTKPanel_Instantiate( $"ui_rtk/common/components/spinner.rpak", self.GetPanel(), "spinner" )
		rtk_panel spinner = expect rtk_panel ( p.spinner )
		spinner.SetSize( < 120, 120, 0 > )
		spinner.SetAnchor( RTKANCHOR_CENTER )
	}
}

void function DestroySpinner( PrivateData p )
{
	if ( p.spinner != null )
	{
		rtk_panel spinner = expect rtk_panel ( p.spinner )
		RTKPanel_Destroy( spinner )
		p.spinner = null
	}
}
