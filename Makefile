dockerbuild:
	docker build -t dotfiles .

dockerrun:
	docker run -it dotfiles

dockerbuildrun: dockerbuild dockerrun

dockerclean:
	docker system prune --volumes

