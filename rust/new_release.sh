#!/usr/bin/sh

cargo build --release
cp target/release/libfootsies_sim.so ../godot/bin