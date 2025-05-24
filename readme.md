# Disclaimer
 
!!! 

I am currently in the process of porting this addon from my game project files, so if you stumble
across this repository and are still seeing this message, please be aware the addon is not in a 
usable state. Please reach out to me with any questions or concerns!

!!!

![alt text](https://github.com/liamhendricks/cellblock/blob/main/docs/cellblockicon.png "Cellblock Icon")

# Cellblock

Open world scene management in gdscript.

## Making an open world game?

Cellblock provides a simple and performant framework for developing open world games with a lot of
assets. Open world games have unique problems with asset management. As the player moves around the
world, content should seamlessly load and unload from the scene to keep framerate stable. There's no
reason to load assets into the scene tree if the player is nowhere near them. Building world assets
with Cellblock allows for real time loading and unloading of world content.

There is also a central workflow problem to solve while developing your game. How do you build the
world content efficiently without blowing up your machine? The player only sees the content around
her, but how is this possible in the godot editor while developing? The solution is a data driven
approach, and easy-to-use editor tools. Cellblock allows devs to build their open world game as
efficiently as the player exploring it!

## Cellblock's Design

Cellblock has taken design queues from classic Elder Scrolls games like Morrowind, and it's open
source engine OpenMW. A Cell is a small area containing game content. It can contain static art
assets like trees, rocks or castles - mutable objects such as items, doors or other scriptable
objects - and even characters! These Cells will be seamlessly streamed in and out of the world
according to various settings. Cellblock also sets you up to manage the saving and loading of all
this game state data as serializable JSON.

Only the Cells surrounding the player will be loaded, and there are many configurable options to
decide when, how and how many cells to load. Some games have large assets that are impractical to
keep in memory all the time, other games can load all the Cell data into RAM and only pop them in and
out of the tree. Both situations can be handled with this Addon. There are also customizable 
in-memory caching options.

Discovering the nearby Cells is done by constructing a `KDTree` from all the `CellData` Vector3i
coordinates one time on game load. This ensures efficient searching for neighboring Cells.

## Installation

Follow normal godot 4.x addon installation procedures. Copy the project/addons/cellblock folder into
your projects addon folder. Enable the addon in your project's plugin settings, and restart the
engine.

This addon has only been tested with godot 4.4.x as of right now.

## Setup and Usage

First, you'll need to create a `CellAnchor` node in your game world, which is provided by the addon.
This node is the attachment point for the editor tools, and also the in-game data. Next you will need
to create a `CellRegistry` resource in the inspector.

![alt text](https://github.com/liamhendricks/cellblock/blob/main/docs/setup1.png "Setup 1")

The `CellRegistry` contains most of the relevant setup variables. Lets go over the properties here.

- cells: This is a dictionary containing all of your `CellData`. More about `CellData` discussed
below.
- max_loaded_cells: An int controlling the max number of `Cell` scenes loaded around the player at
once.
- max_cache_size: An int controlling the max number of `Cell` scenes kept in the cache (if your 
chosen `LoadStrategy` is using the LRU cache).
- load_strategy: This enum controls the way your `Cells` will be loaded and kept in memory.
- grid_size: The size of the cell grid in your game world.
- cell_size: The size of the 'gap' between cells. Lower value means more cells in the grid, i.e a
value of 1 would mean 1 cell for every vertex in the grid.
- max_dist: This value controls the max distance that the `KDTree` will consider searching for nearby
cells.
- cell_save: This is a `CellSave` resource that enables saving and loading for your mutable objects.
- cell_directory: The directory where your `Cell` scenes will be saved.

Cellblock registers a singleton called `CellManager` that you need to hook into. Once you have
created a `CellRegistry`, somewhere you will need to start the `CellManager`. In this repo's example
project, I put it in the World script itself like this:

```
class_name World
extends Node3D

@onready var player = $Player
@onready var cell_anchor = $CellAnchor

func _ready():
	CellManager.start(player, self, cell_anchor)
```

## Cell Creating and Editing Workflow

In the editor, when you click on your `CellAnchor` node, you'll notice some options in the bottom
right area of the editor, below the inspector window. This is how you will create, save and load the
cells you are editing. You'll notice X, Y and Z spinner buttons. When updating these coordinates, you
will see the `CellAnchor` node moving to that coordinate in world space. You will be interacting with
1 cell at a time at the current coordinates. The cell data is keyed by this `Vector3i`, which means
1 cell to 1 vertex in cell space.

## LICENCE

This addon is released under the MIT Licence.
