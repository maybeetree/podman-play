#!/bin/sh

if ( realpath --help 2>&1 | grep BusyBox > /dev/null)
then
	alias realpath="coreutils --coreutils-prog=realpath"
fi

confname=".podman-play"
name=""
root=""

find_config() {
	if [ -r "$confname" ]
	then
		#printf '%s\n' "$(realpath "$confname")"
		printf '%s\n' "$PWD"
		return 0
	else
		if [ "$PWD" = "/" ]
		then
			return 1
		else
			cd ..
			find_config
		fi
	fi
}

sanitize() {
	cat | tr -cd 'a-zA-Z0-9-_'
}

source_config() {
	root="$(find_config)"
	if [ -z "$root" ]
	then
		echo "could not find .podman-play file" 1>&2
		return 1
	fi
	name=$(cat "$root/$confname" | head -n 1 | sanitize)
}

cmd_create() {
	if [ -z "$1" ]
	then
		echo "Specify base image" 1>&2
		return 1
	fi
	podman tag "$1" "$name"
}

cmd_down() {
	if [ -z "$1" ]
	then
		echo "Specify registry" 1>&2
		return 1
	fi
	podman pull "$1"/"$name"
	
}

cmd_up() {
	if [ -z "$1" ]
	then
		echo "Specify registry" 1>&2
		return 1
	fi
	podman push "$name" "$1"/"$name"
	
}

check_not_running() {
	if podman ps --format "{{.Names}}" | grep -qw '^'"$1"'$'; then
	    echo "Container is running"
	    exit 1
	fi
}

cmd_run() {
	check_not_running "$name"
	local root_sanitized=$(printf '%s' "$root" | sed 's/:/\\:/g')
	podman run \
		--init \
		--replace \
		-ti \
		--name "$name" \
		--hostname "$name" \
		`#-v "$root_sanitized:/play" `\
		--mount "type=bind,source=$root,target=/play" \
		--workdir "/play/$(realpath "$PWD" --relative-to "$root")" \
		"$name" \
		sh -l
}

cmd_run_gpu() {
	check_not_running "$name"
	local root_sanitized=$(printf '%s' "$root" | sed 's/:/\\:/g')
	podman run \
		--init \
		--replace \
		--gpus=all \
		-ti \
		--name "$name" \
		--hostname "$name" \
		`#-v "$root_sanitized:/play" `\
		--mount "type=bind,source=$root,target=/play" \
		--workdir "/play/$(realpath "$PWD" --relative-to "$root")" \
		"$name" \
		sh -l
}

cmd_run_xorg() {
	check_not_running "$name"
	local root_sanitized=$(printf '%s' "$root" | sed 's/:/\\:/g')
	podman run \
		--init \
		--replace \
		-ti \
		--name "$name" \
		`#-v "$root_sanitized:/play" `\
		--mount "type=bind,source=$root,target=/play" \
		--workdir "/play/$(realpath "$PWD" --relative-to "$root")" \
		-e DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v ~/.Xauthority:/root/.Xauthority:Z \
		--net=host \
		"$name" \
		sh -l
}

cmd_run_net() {
	check_not_running "$name"
	local root_sanitized=$(printf '%s' "$root" | sed 's/:/\\:/g')
	podman run \
		--init \
		--replace \
		-ti \
		--name "$name" \
		`#-v "$root_sanitized:/play" `\
		--mount "type=bind,source=$root,target=/play" \
		--workdir "/play/$(realpath "$PWD" --relative-to "$root")" \
		--net=host \
		"$name" \
		sh -l
}

cmd_exec() {
	podman exec -ti "$name" sh -l
}


cmd_commit() {
	podman commit "$name" "$name"
}

set -e

if [ -z "$1" ]
then
	echo "Specify action" 1>&2
	exit 1
fi

action="$1"

source_config || exit
shift

case "$action" in
	c* )
		cmd_create "$@"
		;;
	r* )
		cmd_run "$@"
		;;
	x* )
		cmd_run_xorg "$@"
		;;
	g* )
		cmd_run_gpu "$@"
		;;
	n* )
		cmd_run_net "$@"
		;;
	e* )
		cmd_exec "$@"
		;;
	m* )
		cmd_commit "$@"
		;;
	d* )
		cmd_down "$@"
		;;
	u* )
		cmd_up "$@"
		;;

esac

set +e


