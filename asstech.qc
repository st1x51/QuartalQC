/********************************************
  Aperture Science Technologies (asstech.qc)
  ==========================================
********************************************/

// for for hardlight bridge
float HL_STARTOFF = 1;
float HL_PPROOF = 2;
// for particle fields
float USE_COUNT = 1;
.float cubeout;
.float type;
// for counters
float COUNTER_TOGGLE = 1;
float COUNTER_LOOP = 2;
float COUNTER_STEP = 4;
float COUNTER_RESET = 8;
float COUNTER_RANDOM = 16;
float COUNTER_FINISHCOUNT = 32;
float COUNTER_START_ON = 64;

// for pellet
float PELLET_SPEED = 150;
float PELLET_TTL = 20;
.float ttl;
.float sleep;


/* COUNTERS (hipnotic)
*********************/
void() counter_on_use;
void() counter_off_use;

void() counter_think =
{
        self.cnt = self.cnt + 1;
        if ( self.spawnflags & COUNTER_RANDOM )
        {
                self.state = random() * self.count;
                self.state = floor (self.state) + 1;
        }
        else
        {
                self.state = self.cnt;
        }

        activator = other;
        SUB_UseTargets();
        self.nextthink = time + self.wait;
        
        if ( self.spawnflags & COUNTER_STEP )
        {
                counter_on_use();
        }

        if ( self.cnt >= self.count )
        {
                self.cnt = 0;
                if ( ( self.aflag ) || !( self.spawnflags & COUNTER_LOOP ) )
                {
                        if (self.spawnflags & COUNTER_TOGGLE)
                        {
                                counter_on_use();
                        }
                        else
                        {
                                remove (self);
                        }
                }
        }
};

void() counter_on_use =
{
        if ( ( self.cnt != 0 ) && ( self.spawnflags & COUNTER_FINISHCOUNT ) )
        {
                self.aflag = TRUE;
                return;
        }

        self.use = counter_off_use;
        self.think = SUB_Null;
        self.aflag = FALSE;
};

void() counter_off_use =
{
        self.aflag = FALSE;
        if (self.spawnflags & COUNTER_TOGGLE)
        {
                self.use = counter_on_use;
        }
        else
        {
                self.use = SUB_Null;
        }

        if ( self.spawnflags & COUNTER_RESET )
        {
                self.cnt = 0;
                self.state = 0;
        }
        self.think = counter_think;
        if (self.delay)
        {
                self.nextthink = time + self.delay;
        }
        else
        {
                counter_think();
        }
};

float(entity counter) counter_GetCount =
{
        if ( counter.classname == "counter" )
        {
                return counter.state;
        }
        return 0;
};

/*QUAKED func_counter (0 0 1) (0 0 0) (32 32 32) TOGGLE LOOP STEP RESET RANDOM FINISHCOUNT START_ON
TOGGLE causes the counter to switch between an on and off state
each time the counter is triggered.

LOOP causes the counter to repeat infinitly.  The count resets to zero
after reaching the value in "count".

STEP causes the counter to only increment when triggered.  Effectively,
this turns the counter into a relay with counting abilities.

RESET causes the counter to reset to 0 when restarted.

RANDOM causes the counter to generate random values in the range 1 to "count"
at the specified interval.

FINISHCOUNT causes the counter to continue counting until it reaches "count"
before shutting down even after being set to an off state.

START_ON causes the counter to be on when the level starts.

"count" specifies how many times to repeat the event.  If LOOP is set,
it specifies how high to count before reseting to zero.  Default is 10.

"wait"  the length of time between each trigger event. Default is 1 second.

"delay" how much time to wait before firing after being switched on.
*/
void() func_counter =
{
        if ( !self.wait )
        {
                self.wait = 1;
        }

        self.count = floor (self.count);
        if ( self.count <= 0 )
        {
                self.count = 10;
        }
        self.cnt = 0;
        self.state = 0;

        self.classname = "counter";
        self.use = counter_off_use;
        self.think = SUB_Null;
        
        if ( self.spawnflags & COUNTER_START_ON )
        {
                self.think = counter_off_use;
                self.nextthink = time + 0.1;
        }
};

void() oncount_use =
{
        if ( counter_GetCount( other ) == self.count )
        {
                activator = other;
                SUB_UseTargets();
        }
};



/* TOGGLE WALL (hipnotic)
************************/
void() hardlight_touch = {};

void() hardlight_use =
{
        if (!self.state)
        {
                self.state = 1;
                setorigin (self, self.origin - '8000 8000 8000');
                sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
        } else
        {
                self.state = 0;
                setorigin (self, self.origin + '8000 8000 8000');
                sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
        }
};

/*QUAKED ass_hardlight (0 0 1) ? START_OFF PORTAL_PROOF
Creates a invisible wall that can be toggled on and off.

START_OFF      wall doesn't block until triggered.
PORTAL_PROOF   when the wall is toggled, you can't shoot portal through it.
*/
void() ass_hardlight =
{
        self.classname = "hardlight";
        self.movetype = MOVETYPE_PUSH;
        self.mdl = self.model;
        setmodel (self, self.model);
        setsize (self, self.mins, self.maxs);
        setorigin (self, self.origin);

        self.touch = hardlight_touch;
        self.use = hardlight_use;

        self.noise = "misc/null.wav";
        self.noise1 = "misc/null.wav";

        precache_sound (self.noise);
        precache_sound (self.noise1);
        
        self.solid = SOLID_BSP;
        self.model = string_null;

        if (self.spawnflags & HL_STARTOFF )
        {
                self.state = 0;
                setorigin (self, self.origin + '8000 8000 8000');
        } else
        {
                self.state = 1;
                sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
        }

        if (self.spawnflags & HL_PPROOF)
        {
                self.classname = "hardlight2";
        }
};
/* PARTICLE FIELD (hipnotic)
***************************/
void() particlefield_XZ =
{
        local vector pos;
        local vector start;
        local vector end;

        if ( (self.spawnflags & USE_COUNT) && 
                (counter_GetCount (other) != self.cnt) )
        {
                return;
        }

        self.ltime = time + 0.25;
        if ( self.noise )
        {
                sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
        }

        // Only show particles if client is visible.
        // This helps to keep network traffic down to a minimum.
        if (!checkclient() )
                return;

        start = self.dest1 + self.origin;
        end   = self.dest2 + self.origin;
        pos_y = start_y;
        pos_z = start_z;
        while( pos_z <= end_z )
        {
                pos_x = start_x;
                while( pos_x <= end_x )
                {
                        particle (pos, '0 0 0', self.color, self.count);
                        pos_x = pos_x + 16;
                }
                pos_z = pos_z + 16;
        }
};

void () particlefield_YZ =
{
        local vector pos;
        local vector start;
        local vector end;

        if ( (self.spawnflags & USE_COUNT) &&
                (counter_GetCount (other) != self.cnt) )
        {
                return;
        }

        self.ltime = time + 0.25;
        if ( self.noise )
        {
                sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
        }

        // Only show particles if client is visible.
        // This helps to keep network traffic down to a minimum.
        if (!checkclient() )
                return;

        start = self.dest1 + self.origin;
        end   = self.dest2 + self.origin;
        pos_x = start_x;
        pos_z = start_z;
        while( pos_z < end_z )
        {
                pos_y = start_y;
                while( pos_y < end_y )
                {
                        particle ( pos, '0 0 0', self.color, self.count );
                        pos_y = pos_y + 16;
                }
                pos_z = pos_z + 16;
        }
};

void () particlefield_XY =
{
        local vector pos;
        local vector start;
        local vector end;

        if ( (self.spawnflags & USE_COUNT) &&
                (counter_GetCount (other) != self.cnt) )
        {
                return;
        }

        self.ltime = time + 0.25;
        if ( self.noise )
        {
                sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
        }

        // Only show particles if client is visible.
        // This helps to keep network traffic down to a minimum.
        if (!checkclient() )
                return;


        start = self.dest1 + self.origin;
        end   = self.dest2 + self.origin;
        pos_x = start_x;
        pos_z = start_z;
        while( pos_x < end_x )
        {
                pos_y = start_y;
                while( pos_y < end_y )
                {
                        particle ( pos, '0 0 0', self.color, self.count );
                        pos_y = pos_y + 16;
                }
                pos_x = pos_x + 16;
        }
};

void () particlefield_touch =
{
        if ( !self.dmg )
                return;

        if ( time > self.ltime)
                return;

        if (time < self.attack_finished)
                return;
        self.attack_finished = time + 0.5;
        T_Damage (other, self, self, self.dmg);
};

/*QUAKED func_particlefield (0 0 1) ? USE_COUNT
Creates a brief particle flash roughly the size of the defining
brush each time it is triggered.

USE_COUNT when the activator is a func_counter, the field will only
   activate when count is equal to "cnt".  Same as using a func_oncount
   to trigger.

"cnt" is the count to activate on when USE_COUNT is set.
"color" is the color of the particles.  Default is 192 (yellow).
"count" is the density of the particles.  Default is 2.
"noise" is the sound to play when triggered.  Do not use a looping sound here.
"dmg" is the amount of damage to cause when touched.
*/
void() func_particlefield =
{
        if ( !self.color )
        {
                self.color = 192;
        }
        if ( self.count == 0 )
        {
                self.count = 2;
        }
        self.classname = "particlefield";
        self.solid = SOLID_NOT;
        self.movetype = MOVETYPE_NONE;
        setmodel (self, self.model);
        self.model = string_null;

        self.origin = (self.mins + self.maxs) * 0.5;
        setorigin (self, self.origin);
        self.dest = self.maxs - self.mins - '16 16 16';
        self.dest1 = self.mins
        + '8 8 8' - self.origin;
        self.dest2 = self.maxs + '7.9 7.9 7.9' - self.origin;
        setsize (self, self.mins, self.maxs);
        self.touch = particlefield_touch;

        if ( self.dest_x > self.dest_z )
        {
                if ( self.dest_y > self.dest_z )
                {
                        self.use = particlefield_XY;
                        self.dest1_z = ( self.dest1_z + self.dest2_z ) / 2;
                }
                else
                {
                        self.use = particlefield_XZ;
                        self.dest1_y = ( self.dest1_y + self.dest2_y ) / 2;
                }
        }
        else
        {
                if ( self.dest_y > self.dest_x )
                {
                        self.use = particlefield_YZ;
                        self.dest1_x = ( self.dest1_x + self.dest2_x ) / 2;
                }
                else
                {
                        self.use = particlefield_XZ;
                        self.dest1_y = ( self.dest1_y + self.dest2_y ) / 2;
                }
        }

        if ( self.noise )
        {
                precache_sound (self.noise);
        }
        self.ltime = time;
};

void() togglewall_use =
{
	if (self.solid)
		self.solid = SOLID_NOT;
	else
		self.solid = SOLID_BBOX;

	// link into world
	setmodel (self, self.model);
	self.modelindex = 0;
}

void() togglewall_touch =
{
	// damage other
}


/*QUAKED func_particlefield
.dmg	when touched
*/
//float START_OFF = 1;
void() func_togglewall =
{
	if (!(self.spawnflags & 1))
		self.solid = SOLID_BBOX;

	setmodel (self, self.model);
	self.modelindex = 0;

	self.use = togglewall_use;
	if (self.dmg)
		self.touch = togglewall_touch;
}

/***
  Vital Apparatus Vent
  -------------------------------------
  - delivers new cube when the old one is destroyed

void() func_assvent = {};
***/


/*QUAKED ass_portalproof
  Creates the wall, that can't bear portals.
*/
void() ass_portalproof =
{
        self.solid = SOLID_BSP;
        self.movetype = MOVETYPE_PUSH;
        setorigin (self, self.origin);
        setmodel (self, self.model);
        self.classname = "portalproof";
};

        
/*QUAKED ass_grill
  Material Emancipation Grill
  - disintegrates every object but player and his gun. TODO
  - reboots gun (closes portals)
*/
void() grill_touch =
{
        if (other.classname == "player")
        {
                if (portal_mode == 1)
                {
                        if (other.lastport)
                        {
                                PortalErase (other.lastport);
                                PortalErase (other.lastport.enemy);
                                other.lastport = world;
                        }
                } else
                {
                        PortalErase (portal1_entity);
                        PortalErase (portal2_entity);
                }
        }
};

void() ass_grill =
{
        InitTrigger ();
        self.classname = "grill";
        self.touch = grill_touch;
};


/* QUAKED ass_gravitygrill
   Grill that changes gravity when touched by player.

   "gravity" - what to set the player's gravity to
   - 0 (default) normal gravity
   - 1 no gravity
   - 2 almost no gravity
     ...
   - 101 normal gravity
   - 102 slightly higher gravity
     ...
   - 1000 very high gravity

   the same goes subzero ;)
*/
void() gravitygrill_touch =
{
//        if (other.classname != "player")
//                return;
        if (self.gravity == -1)
                other.gravity = 1.0;
        else
                other.gravity = self.gravity;
};

void() ass_gravitygrill =
{
        InitTrigger ();
        self.classname = "gravitygrill";
        self.touch = gravitygrill_touch;
        if (!self.gravity)
                self.gravity = -1;
        else
                self.gravity = ((self.gravity - 1) / 100);
};
        

        
/* QUAKED ass_killgrill
   Grill that hurts player when touched.

   "dmg" - amount of damage to cause to player.
           default - 100
*/
void() killgrill_touch =
{
        if (other.classname != "player" && (other.classname != "turret"))
                return;
        if (other.health)
                T_Damage (other, self, self, self.dmg);		
};

void() ass_killgrill =
{
        InitTrigger ();
        self.classname ="killgrill";
        self.touch = killgrill_touch;
        if (!self.dmg)
                self.dmg = 100;
};



/* HIGH-ENERGY PELLETS
*********************/
void () pellet_remove =
{
        self.launcher.nextone = TRUE;
        T_RadiusDamage (self, self.owner, 120, world);
/*
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_EXPLOSION);
        WriteCoord (MSG_BROADCAST, self.origin_x);
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);
*/
		sound (self, CHAN_WEAPON, "pellet/explosion.wav", 1, ATTN_NORM);
        BecomeExplosion ();
};

void () pellet_think =
{
        if (self.sleep < time)
        {
                pellet_remove ();
                return;
        }
        if (self.movetype == MOVETYPE_BOUNCE) //my little bounce trick...
        {
                self.movetype = MOVETYPE_FLY;
                self.angles = vectoangles (self.velocity);
                self.velocity = normalize (self.velocity) * self.speed;
                self.oldvel = self.velocity;
               
        } else {
                self.velocity = normalize (self.velocity) * self.speed;
        }
        self.nextthink = time + 0.1;
};
void () pellet_touch =
{
        if (other.takedamage) 
        {
                pellet_remove ();
                return;
        }
        sound (self, CHAN_WEAPON, "pellet/hit.wav", 1, ATTN_NONE);
        traceline (self.origin, self.origin + v_forward * 8, TRUE, self); // is there a wall in front of me?
        setorigin (self, (trace_endpos - v_forward * 8 ));
//        self.velocity = normalize(self.velocity) * self.speed;
        self.movetype = MOVETYPE_BOUNCE;
        self.nextthink = time;
};

void (vector org, vector dir) pellet_fire =
{
        local entity pellet;

		sound (self, CHAN_WEAPON, "pellet/fire.wav", 1, ATTN_NORM);
        pellet = spawn ();
        pellet.launcher = self;
        pellet.movetype = MOVETYPE_FLY;
        pellet.solid = SOLID_BBOX;
        pellet.sleep = time + self.ttl; 
        pellet.speed = PELLET_SPEED;
        pellet.target = "pellet";
        pellet.angles = vectoangles(dir);

        pellet.classname = "pellet";
        pellet.touch = pellet_touch;
        pellet.think = pellet_think;
        pellet.nextthink = time + 0.1;
        pellet.effects = EF_DIMLIGHT;
        
        setmodel (pellet, "progs/pellet.mdl");
        setsize (pellet, '-16 -16 -16', '16 16 16');
        setorigin (pellet, org);

        pellet.velocity = normalize(dir) * PELLET_SPEED;
};

void() pelletlauncher_think = 
{
       if (self.nextone == TRUE) {
                pellet_fire(self.origin, self.movedir);
                self.nextone = FALSE;
       }
      sound (self, CHAN_WEAPON, "pellet/fly.wav", 1, ATTN_NORM);	   
       self.nextthink = time + 1;
};       


/*QUAKED ass_pelletlauncher (0 0 1) (-16 -16 -16) (16 16 16)
  High-Energy Pellet Launcher

  "wait" - delay before first shot [0]
  
  "ttl"  - time to live [180]
*/
void () ass_pelletlauncher =
{
        SetMovedir ();
        if (self.wait < 0) self.wait = 0;
        if (self.ttl < 1) self.ttl = PELLET_TTL;
        self.nextone = TRUE;
        self.think = pelletlauncher_think;
        self.nextthink = time + self.wait;
        precache_sound ("pellet/fire.wav");
		precache_sound ("pellet/explosion.wav");  
		precache_sound ("pellet/fly.wav");  
        precache_sound ("pellet/hit.wav");        
        precache_model ("progs/pellet.mdl");
};

/*QUAKED ass_pelletcatcher (0 0 1)
  High-Energy Pellet Catcher
  NOTE: you can use 'trigger_once' instead.
*/

void() assbutton_think =
{
    if ((other.classname != "player") && (other.classname != "cube"))
        return;
};

//TODO
//light button is in buttons.qc
/***
  1500 Megawatt Heavy Duty Super-Colliding Super Button
  -----------------------------------------------------
  - weighted by player, cube, sentry gun
  Variable sized trigger. Triggers once, then 
*/
void() ass_button = 
{
    InitTrigger ();
    
    self.think = assbutton_think;

    
    


};


/*QUAKED ass_cube
  Companion Cube
*/
void() asscube_think =
{
	self.nextthink = time + 0.01;

	if (self.flags & FL_ONGROUND)
	{
		self.velocity_z = 0;
		self.angles_x = 0;
	}		
	self.flags = (self.flags | FL_ONGROUND) - FL_ONGROUND;
};

void() asscube_push =
{
	local vector v;
	local float yaw;
 
	if (other.classname != "player") return;
	if (other.groundentity == self ) return;
        if (other.origin_z + other.mins_z + 8 >= self.absmax_z)
{
        if ((!other.flags & FL_ONGROUND))
        other.flags = other.flags + FL_ONGROUND;
        return;
}

	v = self.origin - other.origin;
	yaw = vectoyaw( v );
	walkmove( yaw, frametime * 50 );
};


void() ass_cube =
{
        self.mangle = self.angles;
        self.angles = '0 0 0';

        setmodel (self, "progs/cube.bsp");
        setsize (self, '-16 -16 -18', '16 16 18');
        self.classname = "cube";
        self.solid = SOLID_BBOX;
        self.movetype = MOVETYPE_BOUNCE;
        setorigin( self, self.origin );
        self.oldorigin = self.origin;
        self.gravity = 1;
        self.touch = asscube_push;
        self.nextthink = time + 0.1;
        self.think = asscube_think;
		Gyro_Object_Activate(self, 800);
		Gyro_Object_SetBouyancy(self, 900);
		Gyro_Object_SetAerodynamics(self, 2400);	
};

void() ass_lovecube =
{

        self.mangle = self.angles;
        self.angles = '0 0 0';

        setmodel (self, "progs/lovecube.bsp");
        setsize (self, '-16 -16 -18', '16 16 18');

        self.classname = "cube";
        self.solid = SOLID_BBOX;
        self.movetype = MOVETYPE_BOUNCE;
        setorigin (self, self.origin);
        self.oldorigin = self.origin;
        self.gravity = 1;
        self.touch = asscube_push;
        self.nextthink = time + 0.1;
        self.think = asscube_think;
		Gyro_Object_Activate(self, 800);
		Gyro_Object_SetBouyancy(self, 900);
		Gyro_Object_SetAerodynamics(self, 2400);	
};

void() ass_dtcube =
{

        self.mangle = self.angles;
        self.angles = '0 0 0';
        setmodel (self, "progs/dtcube.bsp");
        setsize (self, '-16 -16 -18', '16 16 18');

        self.classname = "cube";
        self.solid = SOLID_BBOX;
        self.movetype = MOVETYPE_BOUNCE;
        setorigin (self, self.origin);
        self.oldorigin = self.origin;
        self.gravity = 1;
        self.touch = asscube_push;
        self.nextthink = time + 0.1;
        self.think = asscube_think;
		Gyro_Object_Activate(self, 800);
		Gyro_Object_SetBouyancy(self, 900);
		Gyro_Object_SetAerodynamics(self, 2400);	
};


//============================================================================

//##########################################
//#### GLASS from Kurok                 ####
//##########################################

// glass spawnflag constants
float GLASS_SMOOTH      = 1;
float GLASS_BLOCKABLE   = 2;
float GLASS_STARTOFF   = 4;
float GLASS_ONEHIT      = 8;
.float   color;

void () blocker_use =
   {
   if ( !self.state )
      {
      self.state = 1;
      setorigin( self, self.origin - '8000 8000 8000' );
      sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
      }
   else
      {
      self.state = 0;
      setorigin( self, self.origin + '8000 8000 8000' );
      sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
      }
   };

void(entity attacker, float damage)   glass_pain =
{
   sound (self, CHAN_VOICE, "weapons/ghit.wav", 1, ATTN_NORM);

// check if one hit is required to break it
   if(self.spawnflags & GLASS_ONEHIT)
      self.health = self.max_health;
};

void() glass_die=
{
   local entity new;
   local vector tmpvec;

   while(self.color > 0)
   {
      new = spawn();
      new.origin = self.origin;
      if(random() < 0.33)
         setmodel (new, "progs/glass3.mdl" );
      else if(random() < 0.5)
         setmodel (new, "progs/glass2.mdl" );
      else
         setmodel (new, "progs/glass1.mdl" );
      setsize (new, '0 0 0', '0 0 0');
      new.velocity_x = 70 * crandom();
      new.velocity_y = 70 * crandom();
      new.velocity_z = 140 + 70 * random();
      new.movetype = MOVETYPE_BOUNCE;
      new.solid = SOLID_BBOX;
      new.avelocity_x = random()*600;
      new.avelocity_y = random()*600;
      new.avelocity_z = random()*600;
      new.nextthink = time + 2 + random()*3;
      new.think = SUB_Remove;

      self.absmin = self.origin + self.mins;
      self.absmax = self.origin + self.maxs;
      tmpvec_x = self.absmin_x + (random() * (self.absmax_x - self.absmin_x));
      tmpvec_y = self.absmin_y + (random() * (self.absmax_y - self.absmin_y));
      tmpvec_z = self.absmin_z + (random() * (self.absmax_z - self.absmin_z));

      setorigin(new, tmpvec);

      self.color = self.color - 1;
   }
   if(self.noise2)
      sound (self , CHAN_VOICE, self.noise2, 1, ATTN_NORM);

//   if(self.event)
//      SUB_UseName(self.event);

   remove(self);
};

void() func_glass=
{
   local vector tmpvec;

/*
   local entity glass;

   glass = spawn();
   glass.origin = self.origin;

   glass.movetype = MOVETYPE_NONE;
   glass.solid = SOLID_NOT;
   glass.mdl = self.model;
   setmodel (glass, self.model);
   setsize (glass, self.mins, self.maxs);
   setorigin (glass, self.origin);

   makestatic (glass);
*/
   self.movetype = MOVETYPE_PUSH;
   self.solid = SOLID_BSP;
   self.mdl = self.model;
   setmodel (self, self.model);
   setsize (self, self.mins, self.maxs);
   setorigin (self, self.origin);

//   self.model = string_null;

   precache_sound ("misc/null.wav");

// setup stuff for the glass being broken
   if(self.health > 0)
   {
      if(!self.color)
      {
         tmpvec = self.maxs - self.mins;
         tmpvec = tmpvec * 0.031; //(divide by about 32)
         if(tmpvec_x < 1)
            tmpvec_x = 1;
         if(tmpvec_y < 1)
            tmpvec_y = 1;
         if(tmpvec_z < 1)
            tmpvec_z = 1;
         self.color = tmpvec_x * tmpvec_y * tmpvec_z;
      }
      else if(self.color == -1)
         self.color = 0;
      if(self.color > 16) // max number of chunks
         self.color = 16;
      self.takedamage = DAMAGE_YES;
      self.max_health = self.health;
      self.th_die  = glass_die;
      self.th_pain = glass_pain;
      precache_model( "progs/glass1.mdl" );
      precache_model( "progs/glass2.mdl" );
      precache_model( "progs/glass3.mdl" );
   }

// setup as either moving or togglable
   if(self.target) // move like a train
   {
      if (!self.speed)
         self.speed = 100;
      if (!self.dmg)
         self.dmg = 2;

      if (self.sounds == 1)
      {
         if(!self.noise)
            self.noise = ("plats/train2.wav");
         if(!self.noise1)
            self.noise1 = ("plats/train1.wav");

         precache_sound( self.noise );
         precache_sound( self.noise1 );
      }

      self.cnt = 1;
      self.blocked = train_blocked;
      self.use = train_use;
/*
      if(self.spawnflags & GLASS_SMOOTH)
      {
         self.classname = "smtrain";
         self.think = func_smtrain_setup;
      }
      else
      { */
         self.classname = "train";
         self.think = func_train_find;
//      }

      self.nextthink = self.ltime + 0.6;
   }
   else // move like a togglable wall
   {
      self.use =    blocker_use;

      if ( self.spawnflags & GLASS_STARTOFF )
      {
         self.state = 0;
         setorigin( self, self.origin + '8000 8000 8000' );
      }
      else
      {
         self.state = 1;
         if(self.noise1)
            sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
      }
   }

   if ( !self.noise ) // move sound
      self.noise = ("misc/null.wav");
   if ( !self.noise1 ) // stop sound
      self.noise1 = ("misc/null.wav");
   if ( !self.noise2 ) // break sound
      self.noise2 = ("misc/shatter.wav");

   precache_sound( self.noise );
   precache_sound( self.noise1 );
   precache_sound( self.noise2 );
};
void() model_touch =
{
   if (other.classname != "player")
      return;
   
   if (other.health <= 0)
   {
      return;
   }

   if ((!other.flags & FL_ONGROUND) && (other.absmin_z >= self.absmax_z - 2))
      other.flags = other.flags | FL_ONGROUND;
};

/*
Place model code
How to use:
add key "model" with value "path to model"
*/
void() place_model =
{
    	self.movetype = MOVETYPE_STEP;
	self.solid = SOLID_BBOX;
	precache_model (self.model);
	setmodel (self, self.model);
	self.skin = 0;
	self.touch = model_touch;
};						
void() Spawn_Cube =
	{
	//In this function "self" is the spawner that made the cube
	//Cube is a local entity used for this function only, but
	//we can still use the Cube in other functions.
	
	if (self.cubeout == TRUE)			//If we have a cube out (TRUE)
		return;							//Don't do anything
	else								//If we don't
		{								//Spawn one
	self.cubeout = FALSE;				//We have spawned a cube and we need to keep track of it.
	if(self.type == 1)
		{
			ass_cube();
		}
	if(self.type == 2)	
		{
			ass_dtcube();
		}
	if(self.type == 3)	
		{
			ass_lovecube();
		}
		}
	};



void() info_cube_spawner =					//This is the function that will go in the map
	{
	self.movetype = MOVETYPE_NONE;			//its not going to move
	self.model = "";						//We don't want to see it
	self.use = Spawn_Cube;					//When used we want it to spawn a cube
}�
