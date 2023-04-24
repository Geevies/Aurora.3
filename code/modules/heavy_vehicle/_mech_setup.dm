var/global/image/default_hardpoint_background
var/global/image/hardpoint_error_icon
var/global/image/hardpoint_bar_empty
var/global/list/hardpoint_bar_cache = list()
var/global/list/mecha_damage_overlay_cache = list()

#define HARDPOINT_BACK_UTILITY "back utility"
#define HARDPOINT_BACK_COMBAT "back combat"//For missile pods and stuff that doesnt need to face forward
#define HARDPOINT_BACK_SUPERHEAVY "superheavy mount"//For very very big equipment and weapons
#define HARDPOINT_LEFT_UTILITY "left utility"
#define HARDPOINT_RIGHT_UTILITY "right utility"
#define HARDPOINT_LEFT_COMBAT "left combat"
#define HARDPOINT_RIGHT_COMBAT "right combat"
#define HARDPOINT_HEAD_UTILITY "head mount"
#define HARDPOINT_FRAME_UTILITY "frame utility"//Clamps and other equipment that take lots of space

// No software required: taser. light, radio.
#define MECH_SOFTWARE_UTILITY "utility equipment"                // Plasma torch, clamp, drill.
#define MECH_SOFTWARE_MEDICAL "medical support systems"          // Sleeper.
#define MECH_SOFTWARE_WEAPONS "exosuit weapon systems"           // Combat equipment
#define MECH_SOFTWARE_CULT "daemon systems"                      // Souljavelin, Doomblade
#define MECH_SOFTWARE_ENGINEERING "advanced engineering systems" // RCD.

// EMP damage points before various effects occur.
#define EMP_GUI_DISRUPT 5     // 1 ion rifle shot == 8.
#define EMP_MOVE_DISRUPT 10   // 2 shots.
#define EMP_ATTACK_DISRUPT 20 // 3 shots.

//About components
#define MECH_COMPONENT_DAMAGE_UNDAMAGED 1
#define MECH_COMPONENT_DAMAGE_DAMAGED 2
#define MECH_COMPONENT_DAMAGE_DAMAGED_BAD 3
#define MECH_COMPONENT_DAMAGE_DAMAGED_TOTAL 4

//Construction
#define FRAME_REINFORCED 1
#define FRAME_REINFORCED_SECURE 2
#define FRAME_REINFORCED_WELDED 3

#define FRAME_WIRED 1
#define FRAME_WIRED_ADJUSTED 2

//POWER!
#define MECH_POWER_OFF 0
#define MECH_POWER_TRANSITION 1
#define MECH_POWER_ON 2
