class_name TerrainDual
extends Resource

enum Layout {
	SQUARE,
	ISOMETRIC,
	TRIANGLE_HORIZONTAL,
	TRIANGLE_VERTICAL,
}

const TERRAINS: Array[Dictionary] = [
	{ # Layout.SQUARE
		[
			TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
			TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		]: [
			Vector2i(0, 3),
			Vector2i(3, 3),
			Vector2i(0, 0),
			Vector2i(3, 2),
			Vector2i(0, 2),
			Vector2i(1, 2),
			Vector2i(2, 3),
			Vector2i(3, 1),
			Vector2i(1, 3),
			Vector2i(0, 1),
			Vector2i(3, 0),
			Vector2i(2, 0),
			Vector2i(1, 0),
			Vector2i(2, 2),
			Vector2i(1, 1),
			Vector2i(2, 1),
		],
	},
	{ # Layout.ISOMETRIC
		[
			TileSet.CELL_NEIGHBOR_TOP_CORNER,
			TileSet.CELL_NEIGHBOR_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_CORNER,
			TileSet.CELL_NEIGHBOR_LEFT_CORNER,
		]: [
			Vector2i(0, 3),
			Vector2i(3, 3),
			Vector2i(0, 0),
			Vector2i(3, 2),
			Vector2i(0, 2),
			Vector2i(1, 2),
			Vector2i(2, 3),
			Vector2i(3, 1),
			Vector2i(1, 3),
			Vector2i(0, 1),
			Vector2i(3, 0),
			Vector2i(2, 0),
			Vector2i(1, 0),
			Vector2i(2, 2),
			Vector2i(1, 1),
			Vector2i(2, 1),
		],
	},
	{ # Layout.TRIANGLE_HORIZONTAL
		[
			TileSet.CELL_NEIGHBOR_BOTTOM_CORNER,
			TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
			TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		]: [
			Vector2i(0, 0),
			Vector2i(2, 0),
			Vector2i(3, 1),
			Vector2i(1, 3),
			Vector2i(1, 1),
			Vector2i(3, 3),
			Vector2i(2, 2),
			Vector2i(0, 2),
		],
		[
			TileSet.CELL_NEIGHBOR_TOP_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		]: [
			Vector2i(0, 1),
			Vector2i(2, 1),
			Vector2i(3, 0),
			Vector2i(1, 2),
			Vector2i(1, 0),
			Vector2i(3, 2),
			Vector2i(2, 3),
			Vector2i(0, 3),
		],
	},
	{ # Layout.TRIANGLE_VERTICAL
		[
			TileSet.CELL_NEIGHBOR_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
		]: [
			Vector2i(0, 0),
			Vector2i(0, 2),
			Vector2i(1, 3),
			Vector2i(3, 1),
			Vector2i(1, 1),
			Vector2i(3, 3),
			Vector2i(2, 2),
			Vector2i(2, 0),
		],
		[
			TileSet.CELL_NEIGHBOR_LEFT_CORNER,
			TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		]: [
			Vector2i(1, 0),
			Vector2i(1, 2),
			Vector2i(0, 3),
			Vector2i(2, 1),
			Vector2i(0, 1),
			Vector2i(2, 3),
			Vector2i(3, 2),
			Vector2i(3, 0),
		],
	},
]


const TOPOLOGY_LAYOUTS = [
	Layout.SQUARE, # Display.Topology.SQUARE
	Layout.ISOMETRIC, # Display.Topology.ISO
	Layout.TRIANGLE_HORIZONTAL, # Display.Topology.HALF_OFF_HORI
	Layout.TRIANGLE_VERTICAL, # Display.Topology.HALF_OFF_VERT
	Layout.TRIANGLE_HORIZONTAL, # Display.Topology.HEX_HORI
	Layout.TRIANGLE_VERTICAL, # Display.Topology.HEX_VERT
]


## The exact type is {[TileSet.CellNeighbor]: {[int]: Vector2i}}
@export var terrain: Dictionary = {}
func _init(atlas: TileSetAtlasSource) -> void:
	# TODO: read terrain from atlas
	pass


## Would you like to automatically create tiles in the atlas?
static func create_tiles(tile_set: TileSet, atlas: TileSetAtlasSource) -> void:
	print('generating tiles')
	
	# Set size
	atlas.texture_region_size = atlas.texture.get_size() / 4

	# Create new terrain set
	var terrain_set = tile_set.get_terrain_sets_count()
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(terrain_set, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	tile_set.add_terrain(terrain_set)
	tile_set.set_terrain_name(terrain_set, 0, "Background")
	tile_set.add_terrain(terrain_set)
	tile_set.set_terrain_name(terrain_set, 1, "Foreground")

	# Create tiles with terrain set
	atlas.clear_tiles_outside_texture()
	for y in 4:
		for x in 4:
			var tile := Vector2i(x, y)
			if not atlas.has_tile(tile):
				atlas.create_tile(tile)
			var data = atlas.get_tile_data(tile, 0)
			data.terrain_set = terrain_set

	# Determine layout
	var topology := Display.get_topology(tile_set)
	var layout := TERRAINS[TOPOLOGY_LAYOUTS[topology]]
	print(layout)

	# Set terrains
	var sequence: Array
	# Get the first filter in the layout
	for filter in layout:
		sequence = layout[filter]
		break
	var tile_bg = sequence.front()
	atlas.get_tile_data(tile_bg, 0).terrain = 0
	var tile_fg = sequence.back()
	atlas.get_tile_data(tile_fg, 0).terrain = 1

	# Set peering bits
	for filter in layout:
		sequence = layout[filter]
		for i in sequence.size():
			var tile: Vector2i = sequence[i]
			var data := atlas.get_tile_data(tile, 0)
			for neighbor in filter:
				data.set_terrain_peering_bit(neighbor, i & 1)
				i >>= 1
