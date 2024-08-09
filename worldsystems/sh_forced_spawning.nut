
global function ForcedSpawn_UseForcedSpawning
global function ForcedSpawn_GetEnemyPingDisplayTime




















struct
{




} file























































































































































































































































































































































bool function ForcedSpawn_UseForcedSpawning()
{
	return GetCurrentPlaylistVarBool( "forced_spawn_enabled", false )
}


bool function ForcedSpawn_DoDropshipFlyInSequence()
{
	return GetCurrentPlaylistVarBool( "forced_spawn_do_dropship_fly_in_sequence", true )
}


float function ForcedSpawn_SkydiveStartHeight()
{
	return GetCurrentPlaylistVarFloat( "forced_spawn_height", 5000 )
}


bool function ForcedSpawn_UseJumpmaster()
{
	return GetCurrentPlaylistVarBool( "forced_spawn_use_jumpmaster", false )
}


bool function SurvivalSelectedDrop_ShowEnemyStartPings()
{
	return GetCurrentPlaylistVarBool( "forced_spawn_show_enemy_start_pings", true )
}


float function ForcedSpawn_GetRingWaitTimeAfterSpawn()
{
	return GetCurrentPlaylistVarFloat( "forced_spawn_ring_wait_time_after_spawn", 20.0 )
}


float function ForcedSpawn_GetContestedSpawnRadius()
{
	return GetCurrentPlaylistVarFloat( "forced_spawn_contested_spawn_radius", 500.0 )
}


float function ForcedSpawn_GetEnemyPingDisplayTime()
{
	return GetCurrentPlaylistVarFloat( "forced_spawn_enemy_ping_display_time", 20.0 )
}


      
