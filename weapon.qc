/*
======================
Weapon Stuff
======================
*/
void(vector org, vector vel, float damage) SpawnBlood;


//EXPLODE
void()	s_explode1	=	[0,		s_explode2] {};
void()	s_explode2	=	[1,		s_explode3] {};
void()	s_explode3	=	[2,		s_explode4] {};
void()	s_explode4	=	[3,		s_explode5] {};
void()	s_explode5	=	[4,		s_explode6] {};
void()	s_explode6	=	[5,		SUB_Remove] {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
//EXPLODE


void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel*0.1, 73, damage*4);
};

entity	multi_ent;
float	multi_damage;
void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() UpdateWeapon =								//Update the weapon model here
{
	player_run();
	if (self.weapon == IT_PORTAL_GUN)
	{
		self.currentammo = 2; //wtf? when set to 0, i can't pull out the gun!
		self.weaponmodel = "progs/v_portal.mdl";
		self.weaponframe = 0;
	}
};

void()	player_portal1;
void() W_Attack =
{

	if (self.weapon == IT_PORTAL_GUN) {
		player_portal1();
		self.attack_finished = time + 0.8;
        }	
};
void() zoom_on =
{
	if(self.weapon == IT_PORTAL_GUN)
		{
		if (self.zoom == 1)
			{
			stuffcmd (self, "fov 90\n");
			self.zoom = 0;
			}
		else
			{
			stuffcmd(self, "fov 30\n");
			self.zoom = 1;
			}
		}
};	

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{	
	if (self.impulse == 33)
		crouch_on ();
	if (self.impulse == 94)
	{
		use_cmd();
	}
	if(self.impulse == 30)
		zoom_on();
	self.impulse = 0;
};

/*
-=-=-=-=-=-=-=
W_WeaponFrame
-=-=-=-=-=-=-=
*/
void() W_WeaponFrame =
{
	if (time < self.attack_finished)
		return;	
	if (self.impulse) PortalImpulses ();
	if (self.impulse) ImpulseCommands ();
// check for attack	
	if (self.button0)
		W_Attack ();
};
