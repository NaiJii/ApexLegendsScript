global function Perk_ExtraFirepower_Init

const float EXTRA_FIREPOWER_GRENADE_SPAWN_CHANCE = 0.2

void function Perk_ExtraFirepower_Init()
{
	if ( GetCurrentPlaylistVarBool( "disable_perk_extra_firepower", false ) )
		return

	PerkInfo extraFirepower
	extraFirepower.perkId          = ePerkIndex.EXTRA_FIREPOWER




	Perks_RegisterClassPerk( extraFirepower )







}



















































































