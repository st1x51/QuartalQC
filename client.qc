/*
+------+
|Client|
+------+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| Scratch                                      Http://www.admdev.com/scratch |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| Handle's "clients" (eg, Players) connecting, disconnecting, etc.           |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
*/
void() ImpulseCommands;
void() W_WeaponFrame;
void() player_pain;
.float attack_finished;
void(vector org, entity death_owner) spawn_tdeath;
/*
PLAYER JUMP CODE
*/
void() PlayerJump =
{
	if (self.flags & FL_WATERJUMP)
		return;
	if (self.crouch == 1 && (!self.velocity_z) && (crouchcheck(self)))
		{
		setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
		self.crouch = 0;
		self.origin_z = self.origin_z + 16;
		self.view_ofs = '0 0 22';
		}
	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;

// play swiming sound
		if (self.swim_flag < time)
		{
			self.swim_flag = time + 1;
			if (random() < 0.5)
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
	
	self.button2 = 0;
// player jumping sound
	sound (self, CHAN_BODY, "player/jump.wav", 1, ATTN_NORM);
	self.velocity_z = self.velocity_z + 270;
};

void() ClientRespawn =
{
if(!deathmatch && !coop)
localcmd("restart\n");
}
 void() ClientKill = 
{
	T_Damage(self, self, self, self.health);
	ClientRespawn();
};
 void() ClientConnect = 
{
};
 void() ClientDisconnect = 
{
};
void() respawn =
{
if(!deathmatch && !coop)
localcmd("restart\n");
};
void() PlayerDeathThink =
{
	local float		forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else	
			self.velocity = forward * normalize(self.velocity);
	}

// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

// wait for any button down
	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn();
};

void() CheckWaterJump =
{
	local vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8; 
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.flags = self.flags | FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}
};

 void() PlayerPreThink = 
{
	WaterMove (); 
	if (self.waterlevel == 2)
	{
	CheckWaterJump();
	}
	if ((self.regen_time < time))
   {
   self.regen_time = time + 0.5;
   if(self.health < 100 && self.deadflag == DEAD_NO)
   {
   self.health = self.health +1;
   }
   else if(self.health > 100)
   {
   self.health = 100;
   }
      if(self.deadflag == DEAD_DEAD)
	return;
}
	if ((self.health <= 0 && self.button2) || (self.health <= 0 && self.impulse == 95) || (self.health <= 0 && self.impulse == 96) || (self.health <= 0 && self.impulse == 33 ))
	{
	ClientRespawn();
	}
	//st1x:disabled,i have a little crash in FitzQuake
	/*
	if (self.deadflag >= DEAD_DEAD)
	{
		PlayerDeathThink (); 
		return;
	}
	*/
	
	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing
	if (self.button2)
	{
	PlayerJump ();
	}
	else
		self.flags = self.flags | FL_JUMPRELEASED;
};
 
 
 void() PlayerPostThink = 
{ 
	W_WeaponFrame ();

};
string nextmap;
void() GotoNextMap =
{
	if (cvar("samelevel"))	// if samelevel is set, stay on same level
		changelevel (mapname);
	else
		changelevel (nextmap);
};

void() changelevel_touch =
{

	if (other.classname != "player")
		return;

	if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
	{
		T_Damage (other, self, self, 50000);
		return;
	}

	if (coop || deathmatch)
	{
		bprint (other.netname);
		bprint (" exited the level\n");
	}
	
	nextmap = self.map;

	SUB_UseTargets ();

	if ( (self.spawnflags & 1) && (deathmatch == 0) )
	{	// NO_INTERMISSION
		GotoNextMap();
		return;
	}
	
	self.touch = SUB_Null;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("changelevel trigger doesn't have map");
	
	InitTrigger ();
	self.touch = changelevel_touch;
};
void() PutClientInServer = 
{
local entity spot;            						 	// This holds where we want to spawn
spot = find (world,classname,"info_player_start");	 								// Find it
self.classname = "player";           							// I'm a player!
self.health = 100; 												// Set my Health
self.takedamage = DAMAGE_AIM;        							// I can be shot
self.solid = SOLID_SLIDEBOX;         							// Sliding solid
self.movetype = MOVETYPE_WALK;       							// Walking movement
self.flags = FL_CLIENT;              							// Client flag
self.deadflag = DEAD_NO;
self.origin = self.oldorigin = spot.origin + '0 0 1';	//���� ���� � ���������
self.angles = spot.angles;     							// Face the angle the spawnspot indicates
self.fixangle = TRUE;                							// Turn this way immediately

setmodel (self, "progs/player.mdl"); 								// Set my model to the player model
setsize (self, VEC_HULL_MIN, VEC_HULL_MAX); 					// Set my hull size

self.view_ofs = '0 0 22';            							// Set my eye Level
self.velocity = '0 0 0';             							// Stop any old movement

self.attack_finished = time;
self.th_pain = player_pain;
self.th_die = PlayerDie;
self.gravity = 1;
spawn_tdeath (self.origin, self);
GetLevelParms();
};

/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


�
