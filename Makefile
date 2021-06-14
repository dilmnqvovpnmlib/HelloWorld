.PHONY: build
build:
	docker build -t helloworld .

.PHONY: up
up:
	docker run --rm -it -v `pwd`:/app helloworld
