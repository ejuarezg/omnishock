# 🎮 Omnishock

[![Travis CI Build Status](https://travis-ci.org/ticky/omnishock.svg?branch=develop)](https://travis-ci.org/ticky/omnishock) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/9m0lyp0wy8djud7t/branch/develop?svg=true)](https://ci.appveyor.com/project/ticky/omnishock/branch/develop)

Something to do with game controllers!

## To do

- Update this crate to the latest version of Rust SDL2 bindings
    - Fewer dependencies
- Pull new commits from `cross` upstream

## Supported Hardware

Omnishock currently supports communicating with a [Teensy 2.0](https://www.pjrc.com/store/teensy.html), running either:

- **Aaron Clovsky's [`teensy-firmware` for PS2 Bluetooth Adapter](http://psx-scene.com/forums/f19/how-build-your-own-ps2-bluetooth-adapter-use-real-ps3-ps4-controllers-wirelessly-your-ps2-127728/)**  
  Supports analog button inputs and force feedback. Source available under GPL2 or later.
- **Johnny Chung Lee's [Teensy PS2 Controller Sim Firmware](https://procrastineering.blogspot.com/2010/12/simulated-ps2-controller-for.html)**  
  Fast & simple. Omnishock has been tested with v2. Source is public but unlicensed.

Support for more hardware, and more firmware variants, is planned for the future.

## Prerequisites

- [Rust](https://www.rust-lang.org/install.html)
- SDL2 (v2.0.9 or later)
- Controller emulator hardware (see above)

### Mac-specific

SDL2 has broad support for many types of USB and Bluetooth gamepads on macOS, however, for Xbox 360 controllers, and for better support for Xbox One controllers, you will likely want [the 360Controller driver](https://github.com/360Controller/360Controller).

### Linux-specific

The version of sdl2 currently in the Debian package library is quite old (it's version 2.0.5 as of writing), so if you have trouble using certain gamepads (like the Xbox Wireless Controller, for instance), you will need to [build sdl from source](https://wiki.libsdl.org/Installation#Linux.2FUnix).

You'll likely need either permissive `udev` rules for your USB gamepads, or to make sure your user is in the `input` group. You can add your user account to the `input` group with the command `sudo usermod --append --groups input $(whoami)`.

For more information specific to setting up gamepads on Linux, I recommend checking out [this article on the Arch Wiki](https://wiki.archlinux.org/index.php/Gamepad).

## Building for the Raspberry Pi 1 B+

Due to the older ARM SoC used on the B+, cross compiling to this platform was a bit of a nightmare to get working. However, I managed to figure it out. **Follow these special instructions only if you are cross-compiling omnishock to the B+. Otherwise, skip this section.**

**NOTE:** if you want to compile for ARMv7, take a look at the scripts in the `ci` folder of this project. It is much more straightforward than what we are about to do next.

### Creating an image of the toolchain

Cross compilation to the B+ is performed locally using the `cross` crate. We will install this crate in the following subsection. For now, begin by cloning my fork of the `cross` crate source code and changing into the `docker` subdirectory.

**NOTE:** Many of the following build commands use podman. If you are using Docker instead, simply change the command `podman` to `docker` anywhere an image is built.

Build the toolchain image using
```sh
podman build -t raspi1-bplus-gnueabihf-toolchain -f Dockerfile.raspi1-bplus-gnueabihf
```

### Building omnishock

Clone this repo and update to the latest revision of the SDL
game controller database with
```sh
git clone --recurse-submodules https://github.com/ejuarezg/omnishock.git omnishock && cd omnishock
git submodule foreach git checkout master 
git submodule foreach git pull origin master 
```

**NOTE:** If you want to know more about the above code used for git submodules, check out this [link](https://stackoverflow.com/questions/18770545/why-is-my-git-submodule-head-detached-from-master).

**NOTE:** You will need to install a recent version of SDL2 on your pi in order to support newer controllers. If your distribution does not have up-to-date packages, try out my SDL2 compilation guide over on [my "guides" repo.](https://github.com/ejuarezg/guides/blob/master/ps2_homebrew/raspi_controller_setup.md#install-sdl2)

You can now install the `cross` crate using cargo or through your package manager of choice.

Now, instead of getting the libraries from our own Raspberry Pi, as mentioned in [this post](https://stackoverflow.com/questions/19162072/how-to-install-the-raspberry-pi-cross-compiler-on-my-linux-host-machine/58559140#58559140), we will be downloading the raspi (short for Raspberry Pi) libraries required to compile omnishock from the official repos.

You may be wondering how we do this. Well, I'm glad you asked. When we installed the toolchain, we added the official repos to the list of package sources. All we need to do is create another image based off of the toolchain image and install the correct raspi libraries.

This is all taken care of in the `Dockerfile` provided in the root folder of this project. If you are curious to know how this is done, go ahead and inspect the Dockerfile. In essence, we are not really installing the raspi libraries to the system in the image. Rather, we are downloading the libraries and then telling the Rust linker and compiler where to look for them in the file `.cargo/config.toml`.

Create the omnishock builder image by changing into the root folder of this project and running the command
```sh
podman build -t raspi1-bplus-gnu-omnishock -f Dockerfile
```

Finally, run one of the following commands inside the root folder of this
project to build omnishock
```sh
# Simple build command
cross build --target arm-unknown-linux-gnueabihf--release

# Advanced build command. This will clean up the target directory before
# building and print out useful info during compilation.
cargo clean && cross build --target arm-unknown-linux-gnueabihf --verbose --release
```

You will find the compiled binary inside `target/arm-unknown-linux-gnueabihf/release/`.

## Building

- `git clone --recurse-submodules https://github.com/ticky/omnishock.git omnishock && cd omnishock`
- `cargo build --release`

## Running

`cargo run --release`

## Releasing

1. Make sure both `.travis.tml` and `appveyor.yml` are specifying the same Rust versions
2. Ensure that both files' deploy conditions are using that Rust version
3. Tag & sign a version with `git tag -a -s [version]`
4. Push the tag to GitHub, and watch Travis and AppVeyor cut a build
