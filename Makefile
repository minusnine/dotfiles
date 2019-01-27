dockerbuild:
	docker build -t test .

dockerrun:
	docker run -it test

dockerbuildrun: dockerbuild dockerrun

dockerprune:
	docker system prune --volumes

