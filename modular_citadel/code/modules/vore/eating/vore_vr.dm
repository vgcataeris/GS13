
/*
VVVVVVVV           VVVVVVVV     OOOOOOOOO     RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEE
V::::::V           V::::::V   OO:::::::::OO   R::::::::::::::::R  E::::::::::::::::::::E
V::::::V           V::::::V OO:::::::::::::OO R::::::RRRRRR:::::R E::::::::::::::::::::E
V::::::V           V::::::VO:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEEE::::E
 V:::::V           V:::::V O::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
  V:::::V         V:::::V  O:::::O     O:::::O  R::::R     R:::::R  E:::::E
   V:::::V       V:::::V   O:::::O     O:::::O  R::::RRRRRR:::::R   E::::::EEEEEEEEEE
    V:::::V     V:::::V    O:::::O     O:::::O  R:::::::::::::RR    E:::::::::::::::E
     V:::::V   V:::::V     O:::::O     O:::::O  R::::RRRRRR:::::R   E:::::::::::::::E
      V:::::V V:::::V      O:::::O     O:::::O  R::::R     R:::::R  E::::::EEEEEEEEEE
       V:::::V:::::V       O:::::O     O:::::O  R::::R     R:::::R  E:::::E
        V:::::::::V        O::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
         V:::::::V         O:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEE:::::E
          V:::::V           OO:::::::::::::OO R::::::R     R:::::RE::::::::::::::::::::E
           V:::V              OO:::::::::OO   R::::::R     R:::::RE::::::::::::::::::::E
            VVV                 OOOOOOOOO     RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEE

-Aro <3 */

//
// Overrides/additions to stock defines go here, as well as hooks. Sort them by
// the object they are overriding. So all /mob/living together, etc.
//

//
// The datum type bolted onto normal preferences datums for storing Vore stuff
//

#define VORE_VERSION 4

GLOBAL_LIST_EMPTY(vore_preferences_datums)

/client
	var/datum/vore_preferences/prefs_vr

/datum/vore_preferences
	//Actual preferences
	var/digestable = FALSE
	var/devourable = FALSE
	var/feeding = FALSE
//	var/allowmobvore = TRUE
	var/list/belly_prefs = list()
	var/vore_taste = "nothing in particular"
//	var/can_be_drop_prey = FALSE
//	var/can_be_drop_pred = FALSE

	//Mechanically required
	var/path
	var/slot
	var/client/client
	var/client_ckey

/datum/vore_preferences/New(client/C)
	if(istype(C))
		client = C
		client_ckey = C.ckey
		load_vore()

//
//	Check if an object is capable of eating things, based on vore_organs
//
/proc/is_vore_predator(var/mob/living/O)
	if(istype(O,/mob/living))
		if(O.vore_organs.len > 0)
			return TRUE

	return FALSE

//
//	Belly searching for simplifying other procs
//  Mostly redundant now with belly-objects and isbelly(loc)
//
/proc/check_belly(atom/movable/A)
	return isbelly(A.loc)

//
// Save/Load Vore Preferences
//
/datum/vore_preferences/proc/load_path(ckey,slot,filename="character",ext="json")
	if(!ckey || !slot)	return
	path = "data/player_saves/[ckey[1]]/[ckey]/vore/[filename][slot].[ext]"

/datum/vore_preferences/proc/load_vore()
	if(!client || !client_ckey)
		return 0 //No client, how can we save?
	if(!client.prefs || !client?.prefs?.default_slot)
		return 0 //Need to know what character to load!

	slot = client?.prefs?.default_slot

	load_path(client_ckey,slot)

	if(!path) return 0 //Path couldn't be set?
	if(!fexists(path)) //Never saved before
		save_vore() //Make the file first
		return 1

	var/list/json_from_file = json_decode(file2text(path))
	if(!json_from_file)
		return 0 //My concern grows

	var/version = json_from_file["version"]
	json_from_file = patch_version(json_from_file,version)

	digestable = json_from_file["digestable"]
	devourable = json_from_file["devourable"]
	feeding = json_from_file["feeding"]
	vore_taste = json_from_file["vore_taste"]
	belly_prefs = json_from_file["belly_prefs"]

	//Quick sanitize
	if(isnull(digestable))
		digestable = FALSE
	if(isnull(devourable))
		devourable = FALSE
	if(isnull(feeding))
		feeding = FALSE
	if(isnull(belly_prefs))
		belly_prefs = list()

	return 1

/datum/vore_preferences/proc/save_vore()
	if(!path)
		return 0

	var/version = VORE_VERSION	//For "good times" use in the future
	var/list/settings_list = list(
			"version"				= version,
			"digestable"			= digestable,
			"devourable"			= devourable,
			"feeding"				= feeding,
			"vore_taste"			= vore_taste,
			"belly_prefs"			= belly_prefs,
		)

	//List to JSON
	var/json_to_file = json_encode(settings_list)
	if(!json_to_file)
		testing("Saving: [path] failed jsonencode")
		return 0

	//Write it out
//#ifdef RUST_G
//	call(RUST_G, "file_write")(json_to_file, path)
//#else
	// Fall back to using old format if we are not using rust-g
	if(fexists(path))
		fdel(path) //Byond only supports APPENDING to files, not replacing.
	text2file(json_to_file, path)
//#endif
	if(!fexists(path))
		testing("Saving: [path] failed file write")
		return 0

	return 1

/* commented out list things
	"allowmobvore"			= allowmobvore,
	"can_be_drop_prey"		= can_be_drop_prey,
	"can_be_drop_pred"		= can_be_drop_pred, */

//Can do conversions here
datum/vore_preferences/proc/patch_version(var/list/json_from_file,var/version)
	return json_from_file

#undef VORE_VERSION
