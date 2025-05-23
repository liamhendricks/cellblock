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
this game state data.

Only the Cells surrounding the player will be loaded, and there are many configurable options to
decide when, how and how many cells to load. Some games have large assets that are impractical to
keep in memory all the time, other games can load all the Cell data into RAM and only pop them in and
out of the tree. Both situations can be handled with this Addon. There are also customizable 
in-memory caching options.

Discovering the nearby Cells is done by constructing a KDTree from all the CellData Vector3i
coordinates one time on game load. This ensures efficient searching for neighboring Cells.

## What Cellblock does not do

- Cellblock is not a Terrain addon, or a World 'chunking' tool. However, it works great with the
fantastic Terrain3D addon.

- Save serialization. Cellblock provides the user with custom resources that can be used to save, but
it does not perform the saving / loading logic for you. Saves using godot custom resources directly
are considered to be unsafe, but you can use them as your basis for your own serialization logic.

## LICENCE

This addon is released under the MIT Licence.
