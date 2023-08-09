









global function GetDownloadedImageAsset
global function IsImagePakLoading
global function DidImagePakLoadFail
global function UISetRpakLoadStatus
global function ImagePakLoad_OnLevelShutdown
global function ImagePakLoad_UIScriptResetComplete



global enum ePakType
{
	DEFAULT,
	
	DL_PROMO,
	DL_MINI_PROMO,
	DL_STORE_TALL,
	DL_STORE_SHORT,
	DL_STORE_SALE,
	DL_STORE_EVENT_WIDE_SHORT,
	DL_STORE_EVENT_WIDE_MEDIUM,
	DL_STORE_EVENT_TALL,
	DL_STORE_EVENT_SHORT
}



enum eImagePakLoadStatus
{
	LOAD_REQUESTED,
	LOAD_DEFERRED,
	LOAD_COMPLETED,
	LOAD_FAILED,
}



global struct sDownloadedImageAsset
{
	asset image
	bool isFallback
}












struct
{








	table<string, int> pakLoadStatuses

} file











void function ImagePakLoad_OnLevelShutdown()
{
	file.pakLoadStatuses.clear()
}



sDownloadedImageAsset function GetDownloadedImageAssetFromString( string rpakName, string imageName, int dlType )
{
	sDownloadedImageAsset dlAsset
	string fullImageName = ""

	if ( imageName == "" )
	{
		return dlAsset
	}
	else if ( dlType == ePakType.DL_PROMO || dlType == ePakType.DL_MINI_PROMO )
	{
		fullImageName = "rui/download_promo/" + imageName
	}
	if( dlType == ePakType.DL_STORE_SHORT || dlType == ePakType.DL_STORE_TALL || dlType == ePakType.DL_STORE_SALE || dlType == ePakType.DL_STORE_EVENT_WIDE_SHORT
			|| dlType == ePakType.DL_STORE_EVENT_WIDE_MEDIUM || dlType == ePakType.DL_STORE_EVENT_TALL || dlType == ePakType.DL_STORE_EVENT_SHORT )
	{
		fullImageName = "rui/download_store/" + imageName
	}

	if ( RuiImageExists( fullImageName ) )
	{
		dlAsset.image = GetAssetFromString( fullImageName )
		dlAsset.isFallback = false
	}
	else
	{
		printt( "Couldn't find image", fullImageName, "in rpak:", rpakName, "- Will use fallback image." )
		dlAsset.image = GetFallbackImage( dlType )
		dlAsset.isFallback = true
	}

	return dlAsset
}



asset function GetFallbackImage( int dlType )
{
	asset image = $""
	if( dlType == ePakType.DL_STORE_TALL )
		image = $"rui/menu/image_download/image_load_failed_store_tall"
	else if ( dlType == ePakType.DL_STORE_SHORT )
		image = $"rui/menu/image_download/image_load_failed_store_short"
	else if ( dlType == ePakType.DL_STORE_SALE )
		image = $"rui/menu/image_download/image_load_failed_store_sale"
	else if ( dlType == ePakType.DL_STORE_EVENT_WIDE_SHORT )
		image = $"rui/menu/image_download/image_load_failed_event_wide_short"
	else if ( dlType == ePakType.DL_STORE_EVENT_WIDE_MEDIUM )
		image = $"rui/menu/image_download/image_load_failed_event_wide_medium"
	else if ( dlType == ePakType.DL_STORE_EVENT_TALL )
		image = $"rui/menu/image_download/image_load_failed_event_tall"
	else if ( dlType == ePakType.DL_STORE_EVENT_SHORT )
		image = $"rui/menu/image_download/image_load_failed_event_short"
	else if ( dlType == ePakType.DL_PROMO || dlType == ePakType.DL_MINI_PROMO )
		image = $"rui/menu/image_download/image_load_failed_promo"

	return image
}



asset function GetDownloadedImageAsset( string rpakName, string imageName, int dlType, var imageElem = null )
{
	asset image = $""

	if ( rpakName in file.pakLoadStatuses )
	{
		int status = file.pakLoadStatuses[rpakName]
		bool isLoading = status < eImagePakLoadStatus.LOAD_COMPLETED

		if ( status == eImagePakLoadStatus.LOAD_FAILED )
		{
			image = GetFallbackImage( dlType )
			SetLoadingStateOnImage( rpakName, dlType, imageElem, isLoading )
			return image
		}

		if ( isLoading )
		{
			if ( dlType == ePakType.DL_PROMO || dlType == ePakType.DL_MINI_PROMO )
				image = GetFallbackImage( dlType )
			else
				image = $""
		}
		else
		{
			sDownloadedImageAsset dlAsset = GetDownloadedImageAssetFromString( rpakName, imageName, dlType )
			image = dlAsset.image
		}
	}
	else
	{
		if ( dlType == ePakType.DL_PROMO || dlType == ePakType.DL_MINI_PROMO )
			image = GetFallbackImage( dlType )
	}


		if( CanRunClientScript() )
			RunClientScript( "RequestDownloadedImagePakLoad", rpakName, dlType, imageElem, imageName )


	return image
}



bool function IsImagePakLoading( string rpakName )
{
	if( rpakName in file.pakLoadStatuses )
		return file.pakLoadStatuses[rpakName] == eImagePakLoadStatus.LOAD_REQUESTED || file.pakLoadStatuses[rpakName] == eImagePakLoadStatus.LOAD_DEFERRED

	return false
}



bool function DidImagePakLoadFail( string rpakName )
{
	if( rpakName in file.pakLoadStatuses )
		return file.pakLoadStatuses[rpakName] == eImagePakLoadStatus.LOAD_FAILED

	return false
}



void function UISetRpakLoadStatus( string rpakName, int status )
{
	file.pakLoadStatuses[rpakName] <- status
}

















void function ImagePakLoad_UIScriptResetComplete()
{
	if ( CanRunClientScript() )
		RunClientScript( "UIScriptResetCallback_ImagePakLoad" )
}





















































































void function SetLoadingStateOnImage( string rpakName, int pakType, var imageElem, bool isLoading )
{
	if ( imageElem )
	{
		RuiSetBool( Hud_GetRui( imageElem ), "isImageLoading", isLoading )
		if ( isLoading )
		{
			if ( pakType == ePakType.DL_PROMO || pakType == ePakType.DL_MINI_PROMO )
				RuiSetImage( Hud_GetRui( imageElem ), "imageAsset", GetFallbackImage( pakType ) )
			else
				RuiSetImage( Hud_GetRui( imageElem ), "imageAsset", $"" )
		}
		else
		{
			sDownloadedImageAsset dlAsset
			if ( EADP_IsUMEnabled() && ( pakType == ePakType.DL_PROMO || pakType == ePakType.DL_MINI_PROMO ) )
			{
				dlAsset = GetDownloadedImageAssetFromString( rpakName, rpakName, pakType )
				RuiSetBool( Hud_GetRui( imageElem ), "isFallbackImage", dlAsset.isFallback )
			}
			else
			{
				dlAsset = GetDownloadedImageAssetFromString( rpakName, "", pakType )
			}
			RuiSetImage( Hud_GetRui( imageElem ), "imageAsset", dlAsset.image )
		}
	}
}















































































































