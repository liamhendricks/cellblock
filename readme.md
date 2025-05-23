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


