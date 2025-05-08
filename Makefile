.PHONY: all clean up

FILES = $(wildcard files/*)
ARCH = x86_64
COREOS_IMAGE = fedora-coreos-live.$(ARCH).iso
MODIFIED_IMAGE = fedora-coreos-jellyfin.$(ARCH).iso

all: config.ign $(MODIFIED_IMAGE)

up: $(MODIFIED_IMAGE)
	rsync \
		--partial \
		--progress \
		--inplace \
		"$<" \
		clemens@nas.lcl.neverpanic.de:

config.ign: butane.yml $(FILES)
	podman run \
		--rm \
		--interactive \
		--volume "$$PWD:/work" \
		--workdir /work \
		quay.io/coreos/butane:release \
			--pretty \
			--strict \
			"$<" \
			--files-dir files \
			>"$@"

$(COREOS_IMAGE):
	podman pull \
		quay.io/coreos/coreos-installer:release
	podman run \
		--rm \
		-it \
		--volume "$$PWD:/work" \
		--workdir /work \
		quay.io/coreos/coreos-installer:release \
		download \
			-s stable \
			-a $(ARCH) \
			-f iso \
			-d
	mv fedora-coreos-*.*-live-iso.$(ARCH).iso \
		"$@"

$(MODIFIED_IMAGE): config.ign $(COREOS_IMAGE)
	rm -f "$@"
	podman run \
		--pull=newer \
		--rm \
		--volume "$$PWD:/data" \
		--workdir "/data" \
		quay.io/coreos/coreos-installer:release \
		iso customize \
			--dest-device /dev/vda \
			--dest-ignition config.ign \
			--dest-console ttyS0,115200n8 \
			--dest-console tty0 \
			--force \
			-o "$@" \
			"$(COREOS_IMAGE)"

clean:
	$(RM) config.ign $(COREOS_IMAGE) $(MODIFIED_IMAGE)
