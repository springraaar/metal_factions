--- Valid entries used by engine: IncomingChat, MultiSelect, MapPoint
--- other than that, you can give it any name and access it like before with filenames
local Sounds = {
	SoundItems = {
		Victory = {
			file = "sounds/victory.wav",
			in3d = "false",
			maxconcurrent = 1,
			gain=1,
		},
		Defeat = {
			file = "sounds/defeat.wav",
			in3d = "false",
			maxconcurrent = 1,
			gain=1,
		},
		IncomingChat = {
			--- always play on the front speaker(s)
			file = "sounds/chatmsg.wav",
			in3d = "false",
			maxconcurrent = 2,
			gain=0.05,
		},
		MultiSelect = {
			--- always play on the front speaker(s)
			file = "sounds/multisel.wav",
			pitch=0.6,
			pitchmod = 0.25,
			gain = 0.8,
			in3d = "false",
			maxconcurrent = 2,
		},
		MapPoint = {
			--- respect where the point was set, but don't attuenuate in distace
			--- also, when moving the camera, don't pitch it
			file = "sounds/mappoint.wav",
			rolloff = 0,
			dopplerscale = 0,
			maxconcurrent = 2,
			gain=0.3,
		},
		ExampleSound = {
			--- some things you can do with this file

			--- can be either ogg or wav
			file = "somedir/subdir/soundfile.ogg",

			--- loudness, > 1 is louder, < 1  is more quiet, you will most likely not set it to 0
			gain = 1,

			--- > 1 -> high pitched, < 1 lowered
			pitch = 1,

			--- If > 0.0 then this adds a random amount to gain each time the sound is played.
			--- Clamped between 0.0 and 1.0. The result is in the range [(gain * (1 + gainMod)), (gain * (1 - gainMod))].
			gainmod = 0.0,

			--- If > 0.0 then this adds a random amount to pitch each time the sound is played.
			--- Clamped between 0.0 and 1.0. The result is in the range [(pitch * (1 + pitchMod)), (pitch * (1 - pitchMod))].
			pitchmod = 0.0,

			--- how unit / camera speed affects the sound, to exagerate it, use values > 1
			--- dopplerscale = 0 completely disables the effect
			dopplerscale = 1,

			--- when lots of sounds are played, sounds with lwoer priority are more likely to get cut off
			--- priority > 0 will never be cut of (priorities can be negative)
			priority = 0,

			--- this sound will not be played more than 16 times at a time
			maxconcurrent = 16,

			--- cutoff distance
			maxdist = 20000,

			--- how fast it becomes more quiet in the distance (0 means always the same loudness regardless of dist)
			rolloff = 1,

			--- non-3d sounds do always came out of the front-speakers (or the center one)
			--- 3d sounds are, well, in 3d
			in3d = true,

			--- you can loop it for X miliseconds
			looptime = 0,
		},
		FailedCommand = {
			file = "sounds/beep3.wav",
		},
		GenericCommand = {
			file = "sounds/genericcmd.wav",
			pitchmod = 0.15,
			gain = 0.45,
			in3d = "false",
		},
		ComsatFire = {
			file = "sounds/comsatfire.wav",
			gain = 1,
			gainmod = 0,
			pitchmod = 0.05,
			pitch = 1,
			in3d = true,
			maxdist = 2500,
			maxconcurrent = 12,
			dopplerscale = 0,
			priority = 0,
			rolloff = 1,
		},
		burrow = {
			file = "sounds/burrow.wav",
			gain = 1,
			gainmod = 0,
			pitchmod = 0.05,
			pitch = 1,
			in3d = true,
			maxdist = 2500,
			maxconcurrent = 12,
			dopplerscale = 0,
			priority = 0,
			rolloff = 1,
		},
		topspin = {
			file = "sounds/topspin.wav",
			gain = 1,
			gainmod = 0,
			pitchmod = 0.05,
			pitch = 1,
			in3d = true,
			maxdist = 2500,
			maxconcurrent = 7,
			dopplerscale = 0,
			priority = 0,
			rolloff = 4,
		},
		disrstormeffect = {
			file = "sounds/disrstormeffect.wav",
			gain = 1,
			gainmod = 0,
			pitchmod = 0.15,
			pitch = 1,
			in3d = true,
			maxdist = 3500,
			maxconcurrent = 7,
			dopplerscale = 0,
			priority = 0,
			rolloff = 0.5,
		},
		burn1 = {
			file = "sounds/burn1.wav",
			gain = 1,
			gainmod = 0,
			pitchmod = 0.15,
			pitch = 1,
			in3d = true,
			maxdist = 3500,
			maxconcurrent = 7,
			dopplerscale = 0,
			priority = 0,
			rolloff = 0.5,
		},
		default = {
			--- new since 89.0
			--- you can overwrite the fallback profile here (used when no corresponding SoundItem is defined for a sound)
			gain = 1,
			gainmod = 0,
			pitchmod = 0.05,
			pitch = 1,
			in3d = true,
			maxdist = 20000,
			maxconcurrent = 12,
			dopplerscale = 0,
			priority = 0,
			rolloff = 0.4,
		},
	},
}

return Sounds
