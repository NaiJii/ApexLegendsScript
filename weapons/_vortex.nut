untyped

global function Vortex_Init
global function CreateVortexSphere
global function DestroyVortexSphereFromVortexWeapon
global function EnableVortexSphere
global function VortexDrainedByImpact
global function VortexPrimaryAttack
global function GetVortexSphereCurrentColor
global function GetShieldTriLerpColor
global function GetTriLerpColor
global function Vortex_SetTagName
global function Vortex_SetBulletCollectionOffset
global function CodeCallback_OnVortexHitBullet
global function CodeCallback_OnVortexHitProjectile
global function IsIgnoredByVortex
global function SetCallback_VortexSphereTriggerOnBulletHit
global function SetCallback_VortexSphereTriggerOnProjectileHit















const AMPED_WALL_IMPACT_FX = $"P_impact_xo_shield_cp"

global const PROTO_AMPED_WALL = "proto_amped_wall"
global const GUN_SHIELD_WALL = "gun_shield_wall"




global const VORTEX_TRIGGER_AREA = "vortex_trigger_area"
const PROX_MINE_MODEL = $"mdl/weapons/caber_shot/caber_shot_thrown.rmdl"

const VORTEX_SPHERE_COLOR_CHARGE_FULL		= <115,247,255>	
const VORTEX_SPHERE_COLOR_CHARGE_MED		= <200,128,80>	
const VORTEX_SPHERE_COLOR_CHARGE_EMPTY		= <200,80,80>	
const VORTEX_SPHERE_COLOR_PAS_ION_VORTEX	= <115,174,255>	
const AMPED_DAMAGE_SCALAR = 1.5

const VORTEX_SPHERE_COLOR_CROSSOVERFRAC_FULL2MED	= 0.75  
const VORTEX_SPHERE_COLOR_CROSSOVERFRAC_MED2EMPTY	= 0.95  

const VORTEX_BULLET_ABSORB_COUNT_MAX = 32
const VORTEX_PROJECTILE_ABSORB_COUNT_MAX = 32

const VORTEX_TIMED_EXPLOSIVE_FUSETIME				= 2.75	
const VORTEX_TIMED_EXPLOSIVE_FUSETIME_WARNINGFRAC	= 0.75	

const VORTEX_EXP_ROUNDS_RETURN_SPREAD_XY = 0.15
const VORTEX_EXP_ROUNDS_RETURN_SPREAD_Z = 0.075

const VORTEX_ELECTRIC_DAMAGE_CHARGE_DRAIN_MIN = 0.1  
const VORTEX_ELECTRIC_DAMAGE_CHARGE_DRAIN_MAX = 0.3


const VORTEX_SHOTGUN_DAMAGE_RATIO = 0.25


const SHIELD_WALL_BULLET_FX = $"P_impact_xo_shield_cp"
const SHIELD_WALL_EXPMED_FX = $"P_impact_exp_med_xo_shield_CP"

const SIGNAL_ID_BULLET_HIT_THINK = "signal_id_bullet_hit_think"

const VORTEX_EXPLOSIVE_WARNING_SFX_LOOP = "Weapon_Vortex_Gun.ExplosiveWarningBeep"

const VORTEX_PILOT_WEAPON_WEAKNESS_DAMAGESCALE = 6.0


global const VORTEX_REFIRE_NONE					= ""
global const VORTEX_REFIRE_ABSORB				= "absorb"
global const VORTEX_REFIRE_BULLET				= "bullet"
global const VORTEX_REFIRE_EXPLOSIVE_ROUND		= "explosive_round"
global const VORTEX_REFIRE_ROCKET				= "rocket"
global const VORTEX_REFIRE_GRENADE				= "grenade"
global const VORTEX_REFIRE_GRENADE_LONG_FUSE	= "grenade_long_fuse"

const VortexIgnoreClassnames = {
	["mp_titancore_flame_wave"] = true,
	["mp_ability_grapple"] = true,
	["mp_ability_shifter"] = true,
}

struct VortexImpactWeaponInfo
{
	asset absorbFX
	asset absorbFX_3p
	string refireBehavior
	string absorbSound
	string absorbSound_1p_vs_3p
	float explosionradius
	int explosion_damage_heavy_armor
	int explosion_damage
	string impact_effect_table
	float grenade_ignition_time
	float grenade_fuse_time
}

struct
{
	table<string, VortexImpactWeaponInfo> vortexImpactWeaponInfoTable
} file

const DEG_COS_60 = cos( 60 * DEG_TO_RAD )

void function Vortex_Init()
{
	PrecacheParticleSystem( SHIELD_WALL_BULLET_FX )
	GetParticleSystemIndex( SHIELD_WALL_BULLET_FX )
	PrecacheParticleSystem( SHIELD_WALL_EXPMED_FX )
	GetParticleSystemIndex( SHIELD_WALL_EXPMED_FX )
	PrecacheParticleSystem( AMPED_WALL_IMPACT_FX )
	GetParticleSystemIndex( AMPED_WALL_IMPACT_FX )

	RegisterSignal( SIGNAL_ID_BULLET_HIT_THINK )
	RegisterSignal( "VortexStopping" )

	RegisterSignal( "VortexAbsorbed" )
	RegisterSignal( "VortexFired" )
	RegisterSignal( "Script_OnDamaged" )
}






























void function SetCallback_VortexSphereTriggerOnBulletHit( entity vortexSphere, void functionref( entity, entity, var ) callback )
{
	vortexSphere.e.Callback_VortexTriggerBulletHit = callback
}

void function SetCallback_VortexSphereTriggerOnProjectileHit( entity vortexSphere, void functionref( entity, entity, entity, entity, vector ) callback )
{
	vortexSphere.e.Callback_VortexTriggerProjectileHit = callback
}

void function CreateVortexSphere( entity vortexWeapon, bool useCylinderCheck, bool blockOwnerWeapon, int sphereRadius = 40, int bulletFOV = 180 )
{
	entity owner = vortexWeapon.GetWeaponOwner()
	Assert( owner )






















































	SetVortexAmmo( vortexWeapon, 0 )
}

void function EnableVortexSphere( entity vortexWeapon )
{
	string tagname = GetVortexTagName( vortexWeapon )
	entity weaponOwner = vortexWeapon.GetWeaponOwner()
	bool hasBurnMod = vortexWeapon.GetWeaponSettingBool( eWeaponVar.is_burn_mod )







































	

	SetVortexAmmo( vortexWeapon, 0 )
}

void function DestroyVortexSphereFromVortexWeapon( entity vortexWeapon )
{
	DisableVortexSphereFromVortexWeapon( vortexWeapon )





}

void function DestroyVortexSphere( entity vortexSphere )
{
	if ( IsValid( vortexSphere ) )
	{
		vortexSphere.s.worldFX.Destroy()
		vortexSphere.Destroy()
	}
}

void function DisableVortexSphereFromVortexWeapon( entity vortexWeapon )
{
	vortexWeapon.Signal( "VortexStopping" )

	





}

void function DisableVortexSphere( entity vortexSphere )
{
	if ( IsValid( vortexSphere ) )
	{
		vortexSphere.FireNow( "Disable" )
		vortexSphere.Signal( SIGNAL_ID_BULLET_HIT_THINK )
	}
}

















































void function SetPlayerUsingVortex( entity weaponOwner, entity vortexWeapon )
{
	weaponOwner.EndSignal( "OnDeath" )

	weaponOwner.s.isVortexing <- true
	weaponOwner.s.vortexWeapon <- vortexWeapon

	vortexWeapon.WaitSignal( "VortexStopping" )

	OnThreadEnd
	(
		function() : ( weaponOwner )
		{
			if ( IsValid_ThisFrame( weaponOwner ) && "isVortexing" in weaponOwner.s )
			{
				delete weaponOwner.s.isVortexing
				delete weaponOwner.s.vortexWeapon
			}
		}
	)
}



















































































































































































































void function VortexDrainedByImpact( entity vortexWeapon, entity weapon, entity projectile )
{
	if ( vortexWeapon.HasMod( "unlimited_charge_time" ) )
		return

	if ( vortexWeapon.HasMod( "vortex_extended_effect_and_no_use_penalty" ) )
		return

	float amount
	if ( projectile )
		amount = projectile.GetProjectileWeaponSettingFloat( eWeaponVar.vortex_drain )
	else
		amount = weapon.GetWeaponSettingFloat( eWeaponVar.vortex_drain )

	if ( amount <= 0.0 )
		return

	if ( vortexWeapon.GetWeaponClassName() == "mp_titanweapon_vortex_shield_ion" )
	{
		entity owner = vortexWeapon.GetWeaponOwner()
		int totalEnergy = owner.GetSharedEnergyTotal()
		owner.TakeSharedEnergy( int( float( totalEnergy ) * amount ) )
	}
	else
	{
		float frac = min( vortexWeapon.GetWeaponChargeFraction() + amount, 1.0 )
		vortexWeapon.SetWeaponChargeFraction( frac )
	}
}


void function VortexSlowOwnerFromAttacker( entity player, entity attacker, vector velocity, float multiplier )
{
	vector damageForward = player.GetOrigin() - attacker.GetOrigin()
	damageForward.z = 0
	damageForward.Norm()

	vector velForward = player.GetVelocity()
	velForward.z = 0
	velForward.Norm()

	float dot = DotProduct( velForward, damageForward )
	if ( dot >= -0.5 )
		return

	dot += 0.5
	dot *= -2.0

	vector negateVelocity = velocity * -multiplier
	negateVelocity *= dot

	velocity += negateVelocity
	player.SetVelocity( velocity )
}



























































































































































































































































































































int function VortexPrimaryAttack( entity vortexWeapon, WeaponPrimaryAttackParams attackParams )
{
	entity vortexSphere = vortexWeapon.GetWeaponUtilityEntity()
	if ( !vortexSphere )
		return 0





	int totalfired = 0
	int totalAttempts = 0

	bool forceReleased = false
	
	if ( vortexWeapon.IsForceRelease() || vortexWeapon.GetWeaponChargeFraction() == 1 )
		forceReleased = true

	
	
	int bulletsFired = Vortex_FireBackBullets( vortexWeapon, attackParams )
	totalfired += bulletsFired

	





















		totalfired += GetProjectilesAbsorbedCount( vortexWeapon )


	SetVortexAmmo( vortexWeapon, 0 )

	vortexWeapon.Signal( "VortexFired" )

	if ( forceReleased )
		DestroyVortexSphereFromVortexWeapon( vortexWeapon )
	else
		DisableVortexSphereFromVortexWeapon( vortexWeapon )

	return totalfired
}

const int MAX_BULLET_PER_SHOT = 35
int function Vortex_FireBackBullets( entity vortexWeapon, WeaponPrimaryAttackParams attackParams )
{
	int bulletCount = GetBulletsAbsorbedCount( vortexWeapon )
	
	if ( "shotgunPelletsToIgnore" in vortexWeapon.s )
		bulletCount = int( ceil( bulletCount - vortexWeapon.s.shotgunPelletsToIgnore ) )

	if ( bulletCount > 0 )
	{
		bulletCount = minint( bulletCount, MAX_BULLET_PER_SHOT )

		
		

		float radius = LOUD_WEAPON_AI_SOUND_RADIUS_MP
		vortexWeapon.EmitWeaponNpcSound( radius, 0.2 )
		int damageType = damageTypes.shotgun | DF_VORTEX_REFIRE
		if ( bulletCount == 1 )
			vortexWeapon.FireWeaponBullet( attackParams.pos, attackParams.dir, bulletCount, damageType )
		else
			FireHitscanShotgunBlast( vortexWeapon, attackParams.pos, attackParams.dir, bulletCount, damageType )
	}

	return bulletCount
}



































































































































































































































int function GetBulletsAbsorbedCount( entity vortexWeapon )
{
	if ( !vortexWeapon )
		return 0

	entity vortexSphere = vortexWeapon.GetWeaponUtilityEntity()
	if ( !vortexSphere )
		return 0

	return vortexSphere.GetBulletAbsorbedCount()
}

int function GetProjectilesAbsorbedCount( entity vortexWeapon )
{
	if ( !vortexWeapon )
		return 0

	entity vortexSphere = vortexWeapon.GetWeaponUtilityEntity()
	if ( !vortexSphere )
		return 0

	return vortexSphere.GetProjectileAbsorbedCount()
}








































void function Vortex_NotifyAttackerDidDamage( entity attacker, entity vortexOwner, vector hitPos )
{
	if ( !IsValid( attacker ) || !attacker.IsPlayer() )
		return

	if ( !IsValid( vortexOwner ) )
		return

	attacker.NotifyDidDamage( vortexOwner, 0, hitPos, 0, 0, DAMAGEFLAG_VICTIM_HAS_VORTEX, 0, null, 0 )
}

void function SetVortexAmmo( entity vortexWeapon, int count )
{
	entity owner = vortexWeapon.GetWeaponOwner()
	if ( !IsValid_ThisFrame( owner ) )
		return

		if ( !IsLocalViewPlayer( owner ) )
		return


	vortexWeapon.SetWeaponPrimaryAmmoCount( AMMOSOURCE_STOCKPILE, count )
}

vector function GetVortexSphereCurrentColor( float chargeFrac, vector fullHealthColor = VORTEX_SPHERE_COLOR_CHARGE_FULL )
{
	return GetTriLerpColor( chargeFrac, fullHealthColor, VORTEX_SPHERE_COLOR_CHARGE_MED, VORTEX_SPHERE_COLOR_CHARGE_EMPTY )
}

vector function GetShieldTriLerpColor( float frac )
{
	return GetTriLerpColor( frac, VORTEX_SPHERE_COLOR_CHARGE_FULL, VORTEX_SPHERE_COLOR_CHARGE_MED, VORTEX_SPHERE_COLOR_CHARGE_EMPTY )
}

vector function GetTriLerpColor( float fraction, vector color1, vector color2, vector color3, float crossover1 = VORTEX_SPHERE_COLOR_CROSSOVERFRAC_FULL2MED, float crossover2 = VORTEX_SPHERE_COLOR_CROSSOVERFRAC_MED2EMPTY )
{
	float r, g, b

	
	if ( fraction < crossover1 )
	{
		r = Graph( fraction, 0, crossover1, color1.x, color2.x )
		g = Graph( fraction, 0, crossover1, color1.y, color2.y )
		b = Graph( fraction, 0, crossover1, color1.z, color2.z )
		return <r, g, b>
	}
	else if ( fraction < crossover2 )
	{
		r = Graph( fraction, crossover1, crossover2, color2.x, color3.x )
		g = Graph( fraction, crossover1, crossover2, color2.y, color3.y )
		b = Graph( fraction, crossover1, crossover2, color2.z, color3.z )
		return <r, g, b>
	}
	else
	{
		
		r = color3.x
		g = color3.y
		b = color3.z
		return <r, g, b>
	}

	unreachable
}









































void function Vortex_SetTagName( entity weapon, string tagName )
{
	Vortex_SetWeaponSettingOverride( weapon, "vortexTagName", tagName )
}

void function Vortex_SetBulletCollectionOffset( entity weapon, vector offset )
{
	Vortex_SetWeaponSettingOverride( weapon, "bulletCollectionOffset", offset )
}

void function Vortex_SetWeaponSettingOverride( entity weapon, string setting, value )
{
	if ( !( setting in weapon.s ) )
		weapon.s[ setting ] <- null
	weapon.s[ setting ] = value
}

string function GetVortexTagName( entity weapon )
{
	if ( "vortexTagName" in weapon.s )
		return expect string( weapon.s.vortexTagName )

	return "vortex_center"
}

vector function GetBulletCollectionOffset( entity weapon )
{
	if ( "bulletCollectionOffset" in weapon.s )
		return expect vector( weapon.s.bulletCollectionOffset )

	entity owner = weapon.GetWeaponOwner()
	if ( owner.IsTitan() )
		return <300,-90,-70>
	else
		return <80,17,-11>

	unreachable
}






























































bool function CodeCallback_OnVortexHitBullet( entity weapon, entity vortexSphere, var damageInfo )
{
	
	
	
	if ( vortexSphere.GetTargetName() == VORTEX_TRIGGER_AREA )
	{
		if ( vortexSphere.e.Callback_VortexTriggerBulletHit != null )
			vortexSphere.e.Callback_VortexTriggerBulletHit( weapon, vortexSphere, damageInfo )



		return false

	}

	bool isAmpedWall = vortexSphere.GetTargetName() == PROTO_AMPED_WALL
	bool takesDamage = !isAmpedWall
	bool adjustImpactAngles = !(vortexSphere.GetTargetName() == GUN_SHIELD_WALL)









	vector damageAngles = vortexSphere.GetAngles()

	if ( adjustImpactAngles )
		damageAngles = AnglesCompose( damageAngles, <90,0,0> )

	int teamNum = vortexSphere.GetTeam()

	vector damageOrigin = DamageInfo_GetDamagePosition( damageInfo )


		if ( !isAmpedWall )
		{
			
			int effectHandle = StartParticleEffectInWorldWithHandle( GetParticleSystemIndex( SHIELD_WALL_BULLET_FX ), damageOrigin, damageAngles )
			
			vector color = GetShieldTriLerpColor( 0.0 )
			EffectSetControlPointVector( effectHandle, 1, color )
		}

		
		
		
		
		
		
		
		
		
		
		
		
		

		if ( DamageInfo_GetAttacker( damageInfo ) && DamageInfo_GetAttacker( damageInfo ).IsTitan() )
			EmitSoundAtPosition( teamNum, DamageInfo_GetDamagePosition( damageInfo ), "TitanShieldWall.Heavy.BulletImpact_1P_vs_3P" )
		else
			EmitSoundAtPosition( teamNum, DamageInfo_GetDamagePosition( damageInfo ), "TitanShieldWall.Light.BulletImpact_1P_vs_3P" )




























	if ( isAmpedWall )
	{



		return false
	}

	return true
}

bool function OnVortexHitBullet_BubbleShieldNPC( entity vortexSphere, var damageInfo )
{
	vector vortexOrigin 	= vortexSphere.GetOrigin()
	vector damageOrigin 	= DamageInfo_GetDamagePosition( damageInfo )

	float distSq = DistanceSqr( vortexOrigin, damageOrigin )
	if ( distSq < MINION_BUBBLE_SHIELD_RADIUS_SQR )
		return false

	vector damageVec 	= damageOrigin - vortexOrigin
	vector damageAngles = VectorToAngles( damageVec )
	damageAngles = AnglesCompose( damageAngles, <90,0,0> )

	int teamNum = vortexSphere.GetTeam()


		int effectHandle = StartParticleEffectInWorldWithHandle( GetParticleSystemIndex( SHIELD_WALL_BULLET_FX ), damageOrigin, damageAngles )

		vector color = GetShieldTriLerpColor( 0.9 )
		EffectSetControlPointVector( effectHandle, 1, color )

		if ( DamageInfo_GetAttacker( damageInfo ) && DamageInfo_GetAttacker( damageInfo ).IsTitan() )
			EmitSoundAtPosition( teamNum, DamageInfo_GetDamagePosition( damageInfo ), "TitanShieldWall.Heavy.BulletImpact_1P_vs_3P" )
		else
			EmitSoundAtPosition( teamNum, DamageInfo_GetDamagePosition( damageInfo ), "TitanShieldWall.Light.BulletImpact_1P_vs_3P" )










	return true
}

bool function CodeCallback_OnVortexHitProjectile( entity weapon, entity vortexSphere, entity attacker, entity projectile, vector contactPos )
{
	
	if ( !IsValid( vortexSphere ) )
		return false

	
	
	
	if ( vortexSphere.GetTargetName() == VORTEX_TRIGGER_AREA )
	{
		if ( vortexSphere.e.Callback_VortexTriggerProjectileHit != null )
			vortexSphere.e.Callback_VortexTriggerProjectileHit( weapon, vortexSphere, attacker, projectile, contactPos )



		return false

	}

	var ignoreVortex = projectile.ProjectileGetWeaponInfoFileKeyField( "projectile_ignores_vortex" )
	if ( ignoreVortex != null )
	{
































		return false
	}

	bool adjustImpactAngles = !(vortexSphere.GetTargetName() == GUN_SHIELD_WALL)

	vector damageAngles = vortexSphere.GetAngles()

	if ( adjustImpactAngles )
		damageAngles = AnglesCompose( damageAngles, <90,0,0> )

	asset projectileSettingFX = projectile.GetProjectileWeaponSettingAsset( eWeaponVar.vortex_impact_effect )
	asset impactFX = (projectileSettingFX != $"") ? projectileSettingFX : SHIELD_WALL_EXPMED_FX

	bool isAmpedWall = vortexSphere.GetTargetName() == PROTO_AMPED_WALL
	bool takesDamage = !isAmpedWall





	
	if ( isAmpedWall )
		impactFX = AMPED_WALL_IMPACT_FX

	int teamNum = vortexSphere.GetTeam()


		if ( !isAmpedWall )
		{
			int effectHandle = StartParticleEffectInWorldWithHandle( GetParticleSystemIndex( impactFX ), contactPos, damageAngles )
			
			vector color = GetShieldTriLerpColor( 0.0 )
			EffectSetControlPointVector( effectHandle, 1, color )
		}

		var impact_sound_1p = projectile.ProjectileGetWeaponInfoFileKeyField( "vortex_impact_sound_1p" )
		if ( impact_sound_1p == null )
			impact_sound_1p = "TitanShieldWall.Explosive.BulletImpact_1P_vs_3P"

		EmitSoundAtPosition( teamNum, contactPos, impact_sound_1p )



































	
	if ( isAmpedWall )
	{




		return false
	}

	return true
}

bool function OnVortexHitProjectile_BubbleShieldNPC( entity vortexSphere, entity attacker, entity projectile, vector contactPos )
{
	vector vortexOrigin 	= vortexSphere.GetOrigin()

	float dist = DistanceSqr( vortexOrigin, contactPos )
	if ( dist < MINION_BUBBLE_SHIELD_RADIUS_SQR )
		return false 

	vector damageVec 	= Normalize( contactPos - vortexOrigin )
	vector damageAngles 	= VectorToAngles( damageVec )
	damageAngles = AnglesCompose( damageAngles, <90,0,0> )

	asset projectileSettingFX = projectile.GetProjectileWeaponSettingAsset( eWeaponVar.vortex_impact_effect )
	asset impactFX = (projectileSettingFX != $"") ? projectileSettingFX : SHIELD_WALL_EXPMED_FX

	int teamNum = vortexSphere.GetTeam()


		int effectHandle = StartParticleEffectInWorldWithHandle( GetParticleSystemIndex( impactFX ), contactPos, damageAngles )

		vector color = GetShieldTriLerpColor( 0.9 )
		EffectSetControlPointVector( effectHandle, 1, color )

		EmitSoundAtPosition( teamNum, contactPos, "TitanShieldWall.Explosive.BulletImpact_1P_vs_3P" )







	return true
}

int function VortexReflectAttack( entity vortexWeapon, table attackParams, vector reflectOrigin )
{
	entity vortexSphere = vortexWeapon.GetWeaponUtilityEntity()
	if ( !vortexSphere )
		return 0





	int totalfired = 0
	int totalAttempts = 0

	bool forceReleased = false
	
	if ( vortexWeapon.IsForceRelease() || vortexWeapon.GetWeaponChargeFraction() == 1 )
		forceReleased = true

	
	
	

	
	

	
	
	
	int bulletCount = GetBulletsAbsorbedCount( vortexWeapon )
	if ( bulletCount > 0 )
	{
		if ( "ampedBulletCount" in vortexWeapon.s )
			vortexWeapon.s.ampedBulletCount++
		else
			vortexWeapon.s.ampedBulletCount <- 1
		vortexWeapon.Signal( "FireAmpedVortexBullet" )
		totalfired += 1
	}

	



















	SetVortexAmmo( vortexWeapon, 0 )
	vortexWeapon.Signal( "VortexFired" )





	






	return totalfired
}

bool function IsIgnoredByVortex( string weaponName )
{
	if ( weaponName in VortexIgnoreClassnames )
		return true

	return false
}








