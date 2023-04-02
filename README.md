# Nazi Zombies: Portable Game Assets

## About 
This repository stores the game data required to play the game, such as maps, textures, or sounds. It also includes the source data for some, and will be updated over time to eventually include them all.

## Project Structure
Here is how the files in this asset repository are structured:
* `common`: Game assets shared between all platforms, `common` is treated like a base directory (i.e. contains `maps/`, `gfx/`, etc.)
* `nx`, `psp`, `pc`, `vita`: These directories contain assets exclusive to their individual platforms, starting with the ['root' directory](https://en.wikipedia.org/wiki/Root_directory) for NZ:P data.
* `source`: Contains assets sources, structured in a similar manner to the compiled paths found in `nzp/*`. 
* `tools`: Script(s) to assist in assembling a complete archive of game assets.

## Downloading
It is recommended that if you do not know what you are doing to use the completely set up builds found [here](https://github.com/nzp-team/nzportable).

If you want to continue anyway, you can download a pre-assembled `.ZIP` archive of assets for your platform on the [Releases](https://github.com/nzp-team/assets/releases/tag/newest) page. Follow the instructions there for installation assistance.

It is also an option for people who may want to modify model sources to either [download](https://github.com/nzp-team/assets/archive/refs/heads/main.zip) this repository (easy) or [clone it](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) (for developers).

## Modifying Model Sources
[Blender](https://www.blender.org/) version 2.9X is used to create models, and as such the model sources are in `.blend` format.

Inside of the directory for a given asset is is mesh (`mesh.blend`) and a texture in PNG format (`texture.png`). Relative texture paths are already established so you can open the mesh in Blender 2.9X and begin modifying.

## Modifying Map Sources
Being a Quake-based game, NZ:P uses conventional Quake mapping tools and standards. It is recommended to use [Trenchbroom](https://trenchbroom.github.io/) to map, though [J.A.C.K.](https://jack.hlfx.ru/en/) is also an option.

If you are new to Quake mapping, check out `dumptruck_ds`'s ["Mapping for Quake" Trenchbroom YouTube tutorials](https://www.youtube.com/watch?v=gONePWocbqA&list=PLgDKRPte5Y0AZ_K_PZbWbgBAEt5xf74aE). If you are familiar with Trenchbroom and want to get started with NZ:P mapping, you can watch `BCDeshiG`'s [NZ:P Trenchbroom Set Up Guide](https://youtu.be/ATvpV7xyfhQ).

Note that we have .WAD3 textures ready for you to use in the `source/textures/wad` directory, and latest FGDs can be found in `source/maps/fgd` in this repository.

## Assembly
Assembling `.ZIP` archives from this asset repository requires a Linux system to run the automatic shell script. Simply navigate to `tools/` and execute `assemble-assets.sh`. If unfamiliar with executing shell (`.sh`) scripts on Linux systems, give this [itsFOSS article](https://itsfoss.com/run-shell-script-linux/) a read.
