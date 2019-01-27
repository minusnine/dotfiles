dockerbuild:
	docker build -t dotfiles .

dockerrun:
	docker run -it dotfiles

dockerbuildrun: dockerbuild dockerrun

dockerprune:
	docker system prune --volumes

