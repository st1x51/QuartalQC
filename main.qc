/*
+----+
|Main|
+----+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| Scratch                                      Http://www.admdev.com/scratch |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| Contains some 'base' subroutines. As a general rule nothing in this file   |
| does much, except to setup basic variables and entities.                   |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
*/
 float START_OFF = 1; 
void() Light_setup; 
void() precaches;
void() PortalInit;
void() UpdateWeapon;
void() main = 
 {
 };
 /*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
void() info_null =
{
	remove(self);
};

/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*/
void() info_notnull =
{
};
void() light = // Basic Light
{
 Light_setup(); // Setup Light
};

void() light_fluoro = // Light with hum ambient
{
 Light_setup(); // Setup Light
};

void() light_fluorospark = // Light with buzz ambient
{
 Light_setup(); // Setup Light
};
void() Light_setup = // Set light on or off, as per spawnflags
{
 if (self.style < 32) {return;} // Dont switch other styles.

 if (self.spawnflags & START_OFF)
  lightstyle(self.style, "a"); // If light starts off, set it off.
 else
  lightstyle(self.style, "m"); // If light starts ON, turn in ON. Simple :)
};
void() LightStyles_setup =
{
//
// Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
//

// 0 normal
lightstyle(0, "m");

// 1 FLICKER (first variety)
lightstyle(1, "mmnmmommommnonmmonqnmmo");

// 2 SLOW STRONG PULSE
lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

// 3 CANDLE (first variety)
lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

// 4 FAST STROBE
lightstyle(4, "mamamamamama");

// 5 GENTLE PULSE 1
lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

// 6 FLICKER (second variety)
lightstyle(6, "nmonqnmomnmomomno");

// 7 CANDLE (second variety)
lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

// 8 CANDLE (third variety)
lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

// 9 SLOW STROBE (fourth variety)
lightstyle(9, "aaaaaaaazzzzzzzz");

// 10 FLUORESCENT FLICKER
lightstyle(10, "mmamammmmammamamaaamammma");

// 11 SLOW PULSE NOT FADE TO BLACK
lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

// styles 32-62 are assigned by the light program for switchable lights

// 63 testing
lightstyle(63, "a");
};
 void() worldspawn = 
 {
 precaches();
 PortalInit();
 LightStyles_setup();
 };

/*
================
|SETNEWPARMS():|
=================================================================================
Description:
This function is called to set up new player info.
=================================================================================
*/

void() SetNewParms = //Sets up start game parms
{
	parm1 = 0;
	parm2 = 100;
	parm3 = 0;
};

/*
==================
|SETCHANGEPARMS():|
=================================================================================
Description:

This function is called when the player hits a change level. Stores player info for
loading upon next level.
=================================================================================
*/

void() SetChangeParms = //called on changelevel; command 
{
	if (self.health <= 0)
	{
		SetNewParms();
		return;
	}

	parm1 = self.items;
	parm2 = self.health;
	parm3 = self.weapon;
};

/*
==================
|GETLEVELPARMS():|
=================================================================================
Description:

This function is called by 'PUTCLIENTINSERVER(); in (CLIENT.QC)' and carries over
information in between level loads, or sets new parms at start map.

Information stored in .parms which are the ONLY floats to be stored in memory in
between level loads.
=================================================================================
*/

void() GetLevelParms = 
{
	if (world.model == "maps/start.bsp")
		SetNewParms ();		// take away all stuff on starting new episode

	self.items = parm1;
	self.health = parm2;
	self.weapon = parm3;
	UpdateWeapon();
};

 void() StartFrame = 
 {
 Gyro_Run();
 };
 
 void() precaches =
{
 precache_model ("progs/player.mdl");
 precache_model ("progs/v_portal.mdl");
 precache_model ("progs/portal1.bsp");
 precache_model ("progs/portal2.bsp");
 precache_model ("progs/portal_flash.mdl");
 precache_model ("progs/s_explod.spr");
 precache_sound ("player/foot1.wav");
 precache_sound ("player/foot2.wav");
 precache_sound ("player/foot3.wav");
 precache_sound ("player/foot4.wav");
 //Portal precashes
precache_sound ("portal/fire.wav");
precache_sound ("portal/close.wav");
precache_sound ("portal/create.wav");
precache_sound ("portal/use.wav");
//turret
 precache_model ("progs/spike.mdl");
 //player
 precache_sound ("player/jump.wav");
 precache_sound ("player/foot1.wav");
 precache_sound ("player/foot2.wav");
 precache_sound ("player/foot3.wav");
 precache_sound ("player/foot4.wav");
 precache_sound ("misc/water1.wav");
 precache_sound ("misc/water2.wav"); 
 //weapons and other
 precache_sound ("weapons/pkup.wav");
 precache_sound ("misc/null.wav");
 precache_model ("progs/cube.bsp");
 precache_model ("progs/lovecube.bsp");
 precache_model ("progs/dtcube.bsp");
};