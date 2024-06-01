#define EQUIP_PREVIEW_LOADOUT BITFLAG(0)
#define EQUIP_PREVIEW_JOB BITFLAG(1)
#define EQUIP_PREVIEW_JOB_HAT BITFLAG(2)
#define EQUIP_PREVIEW_JOB_UNIFORM BITFLAG(3)
#define EQUIP_PREVIEW_JOB_SUIT BITFLAG(4)
#define EQUIP_PREVIEW_ALL (EQUIP_PREVIEW_LOADOUT|EQUIP_PREVIEW_JOB|EQUIP_PREVIEW_JOB_HAT|EQUIP_PREVIEW_JOB_UNIFORM|EQUIP_PREVIEW_JOB_SUIT)

/// External organ. Is a prosthesis with a robo-limb manufacturer.
#define ORGAN_PREF_CYBORG "cyborg"
/// External organ. Amputated.
#define ORGAN_PREF_AMPUTATED "amputated"
/// External organ. Nymph-limb.
#define ORGAN_PREF_NYMPH "nymph"

/// Internal organ. Assisted, so halfway through mechanical.
#define ORGAN_PREF_ASSISTED "assisted"
/// Internal organ. Mechanical, so has a robo-limb manufacturer.
#define ORGAN_PREF_MECHANICAL "mechanical"
/// Internal organ. Removed, used for appendixes.
#define ORGAN_PREF_REMOVED "removed"
/// Note that a "normal" limb or organ has no pref, so there's no define for it.
