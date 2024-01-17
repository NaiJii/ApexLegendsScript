globalize_all_functions

asset function RTKMutator_PickAssetFromTwo( int input, asset option0, asset option1 )
{
	return input == 1 ? option1 : option0
}
asset function RTKMutator_PlatformIcon( int input )
{
	if ( IsUserOnSamePlatformID( input ) )
	{
		switch ( input )
		{
			case HARDWARE_PC:

			case HARDWARE_PC_STEAM:

				return $"ui_image/rui/menu/crossplatform/pc.rpak"

			case HARDWARE_PS4:
			case HARDWARE_PS5:
				return $"ui_image/rui/menu/crossplatform/psn.rpak"

			case HARDWARE_XBOXONE:
			case HARDWARE_XB5:
				return $"ui_image/rui/menu/crossplatform/xbox.rpak"

			case HARDWARE_SWITCH:
				return $"ui_image/rui/menu/crossplatform/switch.rpak"

			default:
				return $""
		}
	}
	else
	{
		switch ( input )
		{
			case HARDWARE_PC:

			case HARDWARE_PC_STEAM:

				return $"ui_image/rui/menu/crossplatform/pc.rpak"

			case HARDWARE_PS4:
			case HARDWARE_PS5:
			case HARDWARE_XBOXONE:
			case HARDWARE_XB5:
			case HARDWARE_SWITCH:
				return $"ui_image/rui/menu/crossplatform/controller.rpak"
			default:
				return $""
		}
	}

	Assert( false, "Unhandled platformID " + input )
	unreachable
}

asset function RTKMutator_BadgeRuiAsset( int input )
{
	return GetAccountBadgeRuiAssetAsAsset( input )
}

