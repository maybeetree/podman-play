#!/bin/sh

sanitize() {
	cat | tr -cd 'a-zA-Z0-9-_'
}

for n in $(find ~/proj/ -maxdepth 4 -type f -name '.podman-play')
do
	name=$(cat "$n" | head -n 1 | sanitize)
	podman push "$name" registry.bbox.home/"$name"
done

