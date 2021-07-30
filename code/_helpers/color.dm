var/static/list/angle_to_color = list(
	"0" = "Mid Red",
	"15" = "Warm Red",
	"30" = "Orange",
	"45" = "Warm Yellow",
	"60" = "Mild Yellow",
	"75" = "Cool Yellow",
	"90" = "Yellow Green",
	"105" = "Warm Green",
	"120" = "Mid Green",
	"135" = "Cool Green",
	"150" = "Green Cyan",
	"165" = "Warm Cyan",
	"180" = "Mid Cyan",
	"195" = "Cool Cyan",
	"225" = "Cool Blue",
	"240" = "Mid Blue",
	"255" = "Warm Blue",
	"270" = "Violet",
	"285" = "Cool Magenta",
	"300" = "Mid Magenta",
	"315" = "Warm Magenta",
	"330" = "Red Magenta",
	"345" = "Cool Red"
)

/proc/hex2colorname(var/hex_code)
	var/list/hex_colors = GetHexColors()
	var/HSV = RGBtoHSV(rgb(hex_colors[1], hex_colors[2], hex_colors[3]))
	var/hue = ReadHSV(HSV)[1]
	message_admins("hue: [hue]")
	var/hue_angle = HueToAngle(hue)

	message_admins("hue to angle: [HueToAngle(hue)]")
	message_admins("angle to hue: [AngleToHue(hue)]")

	if(hue_angle < 0)
		hue_angle = 0
	else if(hue_angle > 345)
		hue_angle = 0
	hue_angle = round(hue_angle, 15)
	message_admins("final angle: [hue_angle]")

	return angle_to_color[hue_angle]