global function RTKMapModeInfo_OnInitialize

global struct RTKMapModeInfo_Properties
{
	rtk_behavior title
	rtk_behavior subtitle
}

void function RTKMapModeInfo_OnInitialize( rtk_behavior self )
{
	rtk_behavior title = self.PropGetBehavior( "title" )
	rtk_behavior subtitle = self.PropGetBehavior( "subtitle" )

	title.PropSetString( "text", GetCurrentPlaylistVarString( "name", "#PLAYLIST_UNAVAILABLE") )
	subtitle.PropSetString( "text", GetCurrentPlaylistVarString( "map_name", "#PLAYLIST_UNAVAILABLE") )
}
