.PHONY: all clean run

FILES = $(wildcard files/*)
PLATFORM = applehv
FORMAT = raw.gz
ARCH = aarch64
COREOS_IMAGE = fedora-coreos-$(PLATFORM).$(ARCH).raw
MODIFIED_IMAGE = fedora-coreos-jellyfin-$(PLATFORM).$(ARCH).raw

all: config.ign $(COREOS_IMAGE)

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
			-a "$(ARCH)" \
			-p "$(PLATFORM)" \
			-f "$(FORMAT)" \
			-d
	mv fedora-coreos-*-"$(PLATFORM)"."$(ARCH)".raw \
		$(COREOS_IMAGE)

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

run: config.ign $(COREOS_IMAGE)
	cp -c "$(COREOS_IMAGE)" "$(MODIFIED_IMAGE)"
	vfkit \
		--cpus 4 \
		--memory 4096 \
		--bootloader efi,variable-store="$(MODIFIED_IMAGE).efivars",create \
		--device virtio-blk,path="$(MODIFIED_IMAGE)" \
		--device virtio-net,nat \
		--ignition config.ign \
		--device virtio-input,keyboard \
		--device virtio-input,pointing \
		--device virtio-gpu,width=1920,height=1200 \
		--gui
	rm -f "$(MODIFIED_IMAGE)" "$(MODIFIED_IMAGE).efivars"

clean:
	$(RM) config.ign "$(COREOS_IMAGE)" "$(MODIFIED_IMAGE)" "$(MODIFIED_IMAGE).efivars"

butane-example.png: butane-example.yml
	pygmentize-3.12 \
		-l yaml \
		-o $@ \
		-O style=monokai,font_name="RedHatMono-Medium",font_size=22,line_numbers=False \
		-f png \
		$<

jellyfin-quadlet.png: files/jellyfin.container
	pygmentize-3.12 \
		-l systemd \
		-o $@ \
		-O style=monokai,font_name="RedHatMono-Medium",font_size=22,line_numbers=False \
		-f png \
		$<
