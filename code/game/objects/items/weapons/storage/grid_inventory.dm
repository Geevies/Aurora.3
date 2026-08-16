/**
 * Spatial storage UI ported from Azure Peak's Tarkov inventory.
 *
 * Aurora's storage implementation predates storage components, so this keeps the
 * existing slot, weight, whitelist, nesting and lifecycle checks and layers a
 * two-dimensional placement map over them.
 */

#define GRID_INVENTORY_MAX_CAPACITY 100

/obj/item/proc/initialize_grid_dimensions()
	if(initial(grid_width) > 0 && initial(grid_height) > 0)
		return
	var/storage_area = get_storage_cost()
	if(grid_storage_cost == storage_area && grid_width > 0 && grid_height > 0)
		return
	grid_storage_cost = storage_area
	if(storage_area == INFINITY)
		grid_width = 1
		grid_height = 1
		return
	grid_width = max(1, FLOOR(sqrt(storage_area), 1))
	while(storage_area % grid_width)
		grid_width--
	grid_height = storage_area / grid_width

/obj/item/proc/inventory_flip(mob/user, force = FALSE)
	if(!force && (!user || !user.Adjacent(src) || !isliving(user)))
		return FALSE
	var/old_width = grid_width
	grid_width = grid_height
	grid_height = old_width
	return TRUE

/obj/item/storage/proc/uses_grid_inventory()
	return grid_inventory && !display_contents_with_number && max_storage_space <= GRID_INVENTORY_MAX_CAPACITY

/obj/item/storage/proc/initialize_grid_inventory()
	if(!uses_grid_inventory())
		return
	grid_calculate_dimensions()
	grid_rebuild()
	grid_box_size = world.icon_size
	boxes.icon = 'icons/hud/storage.dmi'
	boxes.icon_state = "background"
	boxes.alpha = 180
	closer.icon = 'icons/hud/storage.dmi'
	closer.icon_state = "close"
	if(!grid_hover)
		grid_hover = new
		grid_hover.master = src

/obj/item/storage/proc/grid_calculate_dimensions()
	var/capacity = max(1, max_storage_space)
	var/contents_cost = 0
	for(var/obj/item/stored_item in contents)
		contents_cost += stored_item.get_storage_cost()
	capacity = max(capacity, contents_cost)
	if(initial(grid_columns) && initial(grid_rows))
		grid_columns = initial(grid_columns)
		grid_rows = initial(grid_rows)
		grid_capacity = capacity
		return
	if(grid_capacity == capacity && grid_columns && grid_rows)
		return
	grid_columns = null
	grid_rows = null
	grid_capacity = capacity
	if(force_column_number)
		grid_columns = max(1, force_column_number)
	else
		// Keep ordinary storage narrow and tall, as in Azure Peak, rather than
		// stretching backpacks across the middle of widescreen clients.
		grid_columns = min(4, capacity)
		if(CEILING(capacity / grid_columns, 1) > 8)
			grid_columns = CEILING(capacity / 8, 1)
	grid_rows = CEILING(capacity / grid_columns, 1)

/obj/item/storage/proc/grid_rebuild()
	grid_cells = list()
	grid_item_cells = list()
	for(var/obj/item/stored_item in contents)
		stored_item.initialize_grid_dimensions()
		var/coordinates = grid_find_space(stored_item)
		if(!coordinates)
			// Rotating once mirrors Azure Peak's fallback for pre-populated containers.
			stored_item.inventory_flip(null, TRUE)
			coordinates = grid_find_space(stored_item)
		while(!coordinates)
			// Never hide map-spawned contents if an unusual mixture cannot be packed.
			grid_rows++
			coordinates = grid_find_space(stored_item)
		if(coordinates)
			grid_add_item(stored_item, coordinates)

/obj/item/storage/proc/grid_find_space(obj/item/storing, requested_coordinates)
	if(!uses_grid_inventory() || !istype(storing))
		return FALSE
	storing.initialize_grid_dimensions()
	if(requested_coordinates && grid_validate_coordinates(requested_coordinates, storing))
		return requested_coordinates
	if(requested_coordinates)
		return FALSE
	for(var/y in 0 to grid_rows - 1)
		for(var/x in 0 to grid_columns - 1)
			var/coordinates = "[x],[y]"
			if(grid_validate_coordinates(coordinates, storing))
				return coordinates
	return FALSE

/**
 * Repack the current contents to make room for an automatically inserted item.
 * Largest footprints are placed first to avoid roundstart insertion order
 * fragmenting an otherwise sufficiently large backpack.
 */
/obj/item/storage/proc/grid_repack_for_item(obj/item/item_to_place)
	if(!uses_grid_inventory() || !istype(item_to_place))
		return FALSE
	var/list/old_grid_cells = grid_cells
	var/list/old_item_cells = grid_item_cells
	var/list/old_widths = list()
	var/list/old_heights = list()
	var/list/remaining = contents.Copy()
	if(!(item_to_place in remaining))
		remaining += item_to_place
	for(var/obj/item/stored_item in remaining)
		stored_item.initialize_grid_dimensions()
		old_widths[stored_item] = stored_item.grid_width
		old_heights[stored_item] = stored_item.grid_height
	grid_cells = list()
	grid_item_cells = list()
	while(length(remaining))
		var/obj/item/largest_item
		var/largest_area = -1
		var/largest_side = -1
		for(var/obj/item/candidate in remaining)
			var/candidate_area = candidate.grid_width * candidate.grid_height
			var/candidate_side = max(candidate.grid_width, candidate.grid_height)
			if(candidate_area > largest_area || (candidate_area == largest_area && candidate_side > largest_side))
				largest_item = candidate
				largest_area = candidate_area
				largest_side = candidate_side
		remaining -= largest_item
		var/coordinates = grid_find_space(largest_item)
		if(!coordinates && largest_item.grid_width != largest_item.grid_height)
			largest_item.inventory_flip(null, TRUE)
			coordinates = grid_find_space(largest_item)
		if(!coordinates)
			for(var/obj/item/original_item in old_widths)
				original_item.grid_width = old_widths[original_item]
				original_item.grid_height = old_heights[original_item]
			grid_cells = old_grid_cells
			grid_item_cells = old_item_cells
			return FALSE
		grid_add_item(largest_item, coordinates)
	var/item_coordinates = grid_get_origin(item_to_place)
	if(!(item_to_place in contents))
		grid_remove_item(item_to_place)
	return item_coordinates

/obj/item/storage/proc/grid_sync_forced_item(obj/item/stored_item)
	if(!uses_grid_inventory() || !istype(stored_item) || grid_get_origin(stored_item))
		return
	var/coordinates = grid_find_space(stored_item)
	if(!coordinates)
		coordinates = grid_repack_for_item(stored_item)
	if(coordinates && !grid_get_origin(stored_item))
		grid_add_item(stored_item, coordinates)

/obj/item/storage/proc/grid_validate_coordinates(coordinates, obj/item/storing)
	var/comma = findtext(coordinates, ",")
	if(!comma)
		return FALSE
	var/start_x = text2num(copytext(coordinates, 1, comma))
	var/start_y = text2num(copytext(coordinates, comma + 1))
	for(var/x in start_x to start_x + storing.grid_width - 1)
		for(var/y in start_y to start_y + storing.grid_height - 1)
			if(x < 0 || y < 0 || x >= grid_columns || y >= grid_rows)
				return FALSE
			var/obj/item/occupant = grid_cells["[x],[y]"]
			if(occupant && occupant != storing)
				return FALSE
	return TRUE

/obj/item/storage/proc/grid_add_item(obj/item/storing, coordinates)
	grid_remove_item(storing)
	var/comma = findtext(coordinates, ",")
	var/start_x = text2num(copytext(coordinates, 1, comma))
	var/start_y = text2num(copytext(coordinates, comma + 1))
	var/list/occupied = list()
	for(var/x in start_x to start_x + storing.grid_width - 1)
		for(var/y in start_y to start_y + storing.grid_height - 1)
			var/cell = "[x],[y]"
			grid_cells[cell] = storing
			occupied += cell
	grid_item_cells[storing] = occupied
	return TRUE

/obj/item/storage/proc/grid_remove_item(obj/item/removed)
	if(!grid_item_cells || !grid_item_cells[removed])
		return FALSE
	for(var/cell in grid_item_cells[removed])
		grid_cells -= cell
	grid_item_cells -= removed
	if(removed.grid_inventory_underlay)
		removed.underlays -= removed.grid_inventory_underlay
		removed.grid_inventory_underlay = null
	return TRUE

/obj/item/storage/proc/grid_get_origin(obj/item/stored_item)
	var/list/cells = grid_item_cells ? grid_item_cells[stored_item] : null
	return length(cells) ? cells[1] : null

/obj/item/storage/proc/grid_get_bound_underlay(grid_width = world.icon_size, grid_height = world.icon_size)
	var/underlay_key = "[grid_width]x[grid_height]"
	var/mutable_appearance/bound_underlay = grid_underlay_appearances_by_size[underlay_key]
	if(!bound_underlay)
		bound_underlay = grid_generate_bound_underlay(grid_width, grid_height)
		grid_underlay_appearances_by_size[underlay_key] = bound_underlay
	return bound_underlay

/obj/item/storage/proc/grid_generate_bound_underlay(grid_width = world.icon_size, grid_height = world.icon_size)
	var/mutable_appearance/final_appearance = mutable_appearance()
	final_appearance.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	var/icon/final_icon = icon('icons/hud/storage.dmi', "blank")
	final_icon.Scale(grid_width, grid_height)
	var/static/list/scale_both = list("block_under")
	var/static/list/scale_x_states = list("up", "down")
	var/static/list/scale_y_states = list("right", "left")

	var/width_offset = world.icon_size * ((grid_width/world.icon_size)-1)
	var/height_offset = world.icon_size * ((grid_height/world.icon_size)-1)
	var/icon/scaled_icon
	for(var/scaled_both in scale_both)
		scaled_icon = icon('icons/hud/storage.dmi', scaled_both)
		scaled_icon.Scale(grid_width, grid_height)
		final_icon.Blend(scaled_icon, ICON_OVERLAY)
	var/multiplier = 0
	for(var/scaled_x in scale_x_states)
		multiplier = !multiplier
		scaled_icon = icon('icons/hud/storage.dmi', scaled_x)
		scaled_icon.Scale(grid_width, world.icon_size)
		final_icon.Blend(scaled_icon, ICON_OVERLAY, 1, 1 + (height_offset * multiplier))
	multiplier = 0
	for(var/scaled_y in scale_y_states)
		multiplier = !multiplier
		scaled_icon = icon('icons/hud/storage.dmi', scaled_y)
		scaled_icon.Scale(world.icon_size, grid_height)
		final_icon.Blend(scaled_icon, ICON_OVERLAY, 1 + (width_offset * multiplier), 1)
	var/corner_pos_x = 1 + (grid_width - world.icon_size)
	var/corner_pos_y = 1 + (grid_height - world.icon_size)
	var/icon/corner_left_down = icon('icons/hud/storage.dmi', "corner_left_down")
	final_icon.Blend(corner_left_down, ICON_OVERLAY, 1, 1)
	var/icon/corner_right_down = icon('icons/hud/storage.dmi', "corner_right_down")
	final_icon.Blend(corner_right_down, ICON_OVERLAY, corner_pos_x, 1)
	var/icon/corner_left_up = icon('icons/hud/storage.dmi', "corner_left_up")
	final_icon.Blend(corner_left_up, ICON_OVERLAY, 1, corner_pos_y)
	var/icon/corner_right_up = icon('icons/hud/storage.dmi', "corner_right_up")
	final_icon.Blend(corner_right_up, ICON_OVERLAY, corner_pos_x, corner_pos_y)

	final_appearance.icon = final_icon
	final_appearance.transform = final_appearance.transform.Translate(-width_offset/2, -height_offset/2)
	return final_appearance

/obj/item/storage/proc/grid_coordinates_to_screen_loc(coordinates = "")
	var/coordinate_x = copytext(coordinates, 1, findtext(coordinates, ","))
	coordinate_x = text2num(copytext(coordinate_x, 1, findtext(coordinate_x, ":")))

	var/coordinate_y = copytext(coordinates, findtext(coordinates, ",") + 1)
	coordinate_y = text2num(copytext(coordinate_y, 1, findtext(coordinate_y, ":")))

	var/screen_x_pixels = coordinate_x * grid_box_size
	screen_x_pixels += (src.screen_start_x * world.icon_size) + src.screen_pixel_x
	var/screen_y_pixels = coordinate_y * grid_box_size
	screen_y_pixels += ((src.screen_start_y - src.grid_rows + 1) * world.icon_size) + src.screen_pixel_y

	var/screen_x = FLOOR(screen_x_pixels/world.icon_size, 1)
	var/screen_pixel_x = FLOOR(screen_x_pixels - FLOOR(screen_x_pixels, world.icon_size), 1)
	var/screen_y = FLOOR(screen_y_pixels/world.icon_size, 1)
	var/screen_pixel_y = FLOOR(screen_y_pixels - FLOOR(screen_y_pixels, world.icon_size), 1)

	return "[screen_x]:[screen_pixel_x],[screen_y]:[screen_pixel_y]"

/obj/item/storage/proc/grid_screen_loc_to_coordinates(screen_loc = "")
	var/screen_x = copytext(screen_loc, 1, findtext(screen_loc, ","))
	var/screen_pixel_x = text2num(copytext(screen_x, findtext(screen_x, ":") + 1))
	screen_x = text2num(copytext(screen_x, 1, findtext(screen_x, ":")))

	var/screen_y = copytext(screen_loc, findtext(screen_loc, ",") + 1)
	var/screen_pixel_y = text2num(copytext(screen_y, findtext(screen_y, ":") + 1))
	screen_y = text2num(copytext(screen_y, 1, findtext(screen_y, ":")))

	var/screen_x_pixels = (screen_x * world.icon_size) + screen_pixel_x
	screen_x_pixels -= (src.screen_start_x * world.icon_size) + src.screen_pixel_x
	screen_x_pixels = FLOOR(screen_x_pixels/grid_box_size, 1)
	var/screen_y_pixels = (screen_y * world.icon_size) + screen_pixel_y
	screen_y_pixels -= ((src.screen_start_y - src.grid_rows + 1) * world.icon_size) + src.screen_pixel_y
	screen_y_pixels = FLOOR(screen_y_pixels/grid_box_size, 1)

	return "[screen_x_pixels],[screen_y_pixels]"

/obj/item/storage/proc/grid_orient_objs()
	if(!grid_columns || !grid_rows)
		initialize_grid_inventory()
	boxes.screen_loc = "[screen_start_x]:[screen_pixel_x],[screen_start_y]:[screen_pixel_y] to [screen_start_x+grid_columns-1]:[screen_pixel_x],[screen_start_y-grid_rows+1]:[screen_pixel_y]"
	for(var/obj/item/stored_item in contents)
		var/origin = grid_get_origin(stored_item)
		if(!origin)
			origin = grid_find_space(stored_item)
			if(origin)
				grid_add_item(stored_item, origin)
			else
				continue
		var/used_gridwidth = stored_item.grid_width * grid_box_size
		var/used_gridheight = stored_item.grid_height * grid_box_size
		var/screen_loc = grid_coordinates_to_screen_loc(origin)
		var/screen_x = copytext(screen_loc, 1, findtext(screen_loc, ","))
		var/item_screen_pixel_x = text2num(copytext(screen_x, findtext(screen_x, ":") + 1))
		item_screen_pixel_x += (world.icon_size/2)*((used_gridwidth/world.icon_size)-1)
		screen_x = text2num(copytext(screen_x, 1, findtext(screen_x, ":")))
		var/screen_y = copytext(screen_loc, findtext(screen_loc, ",") + 1)
		var/item_screen_pixel_y = text2num(copytext(screen_y, findtext(screen_y, ":") + 1))
		item_screen_pixel_y += (world.icon_size/2)*((used_gridheight/world.icon_size)-1)
		screen_y = text2num(copytext(screen_y, 1, findtext(screen_y, ":")))
		stored_item.screen_loc = "[screen_x]:[item_screen_pixel_x],[screen_y]:[item_screen_pixel_y]"
		stored_item.maptext = ""
		stored_item.mouse_opacity = MOUSE_OPACITY_OPAQUE
		stored_item.hud_layerise()
		stored_item.layer = HUD_ABOVE_ITEM_LAYER
		if(stored_item.grid_inventory_underlay)
			stored_item.underlays -= stored_item.grid_inventory_underlay
		var/mutable_appearance/bounds = grid_get_bound_underlay(used_gridwidth, used_gridheight)
		stored_item.grid_inventory_underlay = bounds
		stored_item.underlays += bounds
	closer.ClearOverlays()
	closer.icon_state = "close"
	var/half_rows = FLOOR((grid_rows-1) * 0.5, 1)
	var/half_row_ceil = CEILING((grid_rows-1) * 0.5, 1)
	var/extra = 0
	if(ISEVEN(grid_rows))
		extra = 1
	closer.screen_loc = "[src.screen_start_x+grid_columns]:[src.screen_pixel_x],[src.screen_start_y - (half_rows + extra)]:[src.screen_pixel_y]"
	switch(grid_rows)
		if(-INFINITY to 1)
			closer.icon_state = "close"
		if(2)
			closer.icon_state = "close_left"
		if(3 to INFINITY)
			closer.icon_state = "close_mid"
	var/image/offset_image
	for(var/overlayer in 1 to half_rows)
		var/state = (overlayer >= half_rows) ? "close_right" : "close_mid"
		offset_image = image(closer.icon, state)
		offset_image.transform = offset_image.transform.Translate(0, world.icon_size * -overlayer)
		closer.AddOverlays(offset_image)
	for(var/overlayer in 1 to half_row_ceil)
		var/state = (overlayer >= half_row_ceil) ? "close_left" : "close_mid"
		offset_image = image(closer.icon, state)
		offset_image.transform = offset_image.transform.Translate(0, world.icon_size * overlayer)
		closer.AddOverlays(offset_image)
	if(grid_rows > 1)
		var/image/close_overlay = image(closer.icon, "close_overlay")
		close_overlay.transform = close_overlay.transform.Translate(0, world.icon_size * ((((grid_rows-1) * 0.5) + extra) - (half_row_ceil)))
		closer.AddOverlays(close_overlay)

/obj/item/storage/proc/reset_grid_inventory_visuals()
	if(!boxes || boxes.icon != 'icons/hud/storage.dmi')
		return
	boxes.icon = 'icons/hud/mob/generic.dmi'
	boxes.icon_state = "block"
	boxes.alpha = 255
	closer.icon = 'icons/hud/mob/generic.dmi'
	closer.icon_state = "x"
	for(var/obj/item/stored_item in contents)
		if(stored_item.grid_inventory_underlay)
			stored_item.underlays -= stored_item.grid_inventory_underlay
			stored_item.grid_inventory_underlay = null

/obj/item/storage/proc/grid_update_hover(mob/user, params)
	if(!user || !user.client || user.s_active != src || !uses_grid_inventory())
		return
	user.client.screen -= grid_hover
	var/obj/item/held_item = user.get_active_hand()
	if(!held_item)
		return
	var/coordinates = grid_screen_loc_to_coordinates(params2list(params)["screen-loc"])
	if(!coordinates)
		return
	grid_hover.color = grid_validate_coordinates(coordinates, held_item) ? COLOR_GREEN : COLOR_RED
	grid_hover.transform = matrix().Scale(held_item.grid_width, held_item.grid_height)
	grid_hover.transform = grid_hover.transform.Translate(world.icon_size * (held_item.grid_width - 1) / 2, world.icon_size * (held_item.grid_height - 1) / 2)
	grid_hover.screen_loc = grid_coordinates_to_screen_loc(coordinates)
	user.client.screen += grid_hover

/atom/movable/screen/storage_hover
	icon = 'icons/hud/storage.dmi'
	icon_state = "white"
	plane = HUD_PLANE
	layer = HUD_ITEM_LAYER + 1
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 96

#undef GRID_INVENTORY_MAX_CAPACITY
