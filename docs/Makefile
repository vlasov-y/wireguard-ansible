.PHONY := build serve clean shell theme
.DEFAULT_GOAL := serve

IMAGE ?= klakegg/hugo:alpine
THEME_TARBALL ?= https://github.com/thegeeklab/hugo-geekdoc/releases/download/v0.13.4/hugo-geekdoc.tar.gz

theme:
	@mkdir -p themes/geekdocs
	@if command -v curl > /dev/null; then \
		curl -sSL '$(THEME_TARBALL)' | tar -C themes/geekdocs -xpzvf -; \
	elif command -v wget >/dev/null; then \
		wget -O- '$(THEME_TARBALL)' | tar -C themes/geekdocs -xpzvf -; \
	else \
		echo 'Neither curl nor wget was found.' >&2; \
		exit 1; \
	fi

shell:
	sudo docker run --rm -it \
		-v $(shell pwd):/src \
		-p 8080:8080 \
		--workdir /src \
		--entrypoint /bin/sh \
		'$(IMAGE)'

build:
	sudo docker run --rm -it \
		-v $(shell pwd):/src \
		-p 1313:1313 \
		--workdir /src \
		'$(IMAGE)' -D
	sudo chown -R 1000:1000 .

serve:
	sudo docker run --rm -it \
		-v $(shell pwd):/src \
		-p 8080:8080 \
		--workdir /src \
		--user 1000 \
		'$(IMAGE)' server --bind 0.0.0.0 --port 8080

clean:
	rm -rf resources/_gen public