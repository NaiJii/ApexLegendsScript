global function Perk_KillBoostUlt_Init




const float ULT_PERCENT_TO_ADD = 0.20
const float BONUS_DEBOUNCE_TIME = 30


struct
{




} file

void function Perk_KillBoostUlt_Init()
{
	if ( GetCurrentPlaylistVarBool( "disable_perk_kill_boost_ult", true ) )
		return

	PerkInfo killBoostUlt
	killBoostUlt.perkId          = ePerkIndex.KILL_BOOST_ULT






	Perks_RegisterClassPerk( killBoostUlt )





}













































































































