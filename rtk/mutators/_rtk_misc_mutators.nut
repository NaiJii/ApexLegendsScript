globalize_all_functions

string function RTKMutator_PanelName( rtk_panel input )
{
	return input.GetDisplayName()
}

vector function RTKMutator_QualityColor( int input, bool exception )
{
	if (exception)
		return GetKeyColor( COLORID_LOOT_TIER0, 1 ) / 255.0

	return GetKeyColor( COLORID_LOOT_TIER0, input ) / 255.0
}

string function RTKMutator_QualityName( int input )
{
	return Localize( ItemQuality_GetQualityName( input ) )
}

vector function RTKMutator_QualityTextColor( int input )
{
	return GetKeyColor( COLORID_MENU_TEXT_LOOT_TIER0, input + 1 ) / 255.0
}

