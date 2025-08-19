# podman-play

This is my script for using podman containers for development.
The reason is a desire for a dev environment that:

- Works the same on all my machines
- Limits the damage that can be caused by malicious dependencies
- Is easy to use

## Installation:

```
ln -sf ./podman-play.sh /somewhere/in/your/path/pod
```

## Usage

- create a file `.podman-play` at the root of your project
    which contains a single
    line, which is the name of the image and container
    used for this project

- `pod c <IMAGE NAME>`: create image for this project from existing image
- `pod r`: run container
    - The project root is mounted into `/play` in the container
- `pod n`: run container with host networking
- `pod x`: run container with host networking and X11 forwarding
- `pod m`: commit container changes
    - Run this while the container is still running!
        `pod r` runs containers with `--rm`!
- `pod e`: spawn new shell into running container
- `pod u <REGISTRY>`: upload image to registry
- `pod d <REGISTRY>`: download image from registry

## See also

My [dotfiles repo](https://github.com/maybeetree/treeup)
has scripts for setting up containers meant for interactive use


