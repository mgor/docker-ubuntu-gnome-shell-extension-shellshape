NAME = mgor/ubuntu-gnome-shell-extension-shellshape
HOSTNAME = shellshape-builder

.PHONY = all build run clean

USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)

all: build clean run

build:
	docker pull mgor/docker-ubuntu-pkg-builder:zesty
	docker build -t $(NAME) .

run:
	docker run --rm --name $(HOSTNAME) --hostname $(HOSTNAME) -v $(CURDIR)/packages:/usr/local/src --env USER_ID=$(USER_ID) --env GROUP_ID=$(GROUP_ID) -it $(NAME)

clean:
	rm -rf $(CURDIR)/packages/*
