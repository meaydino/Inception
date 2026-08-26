name = inception

all:
	@mkdir -p /home/meaydino/data/wordpress
	@mkdir -p /home/meaydino/data/mariadb
	@docker compose -f ./srcs/docker-compose.yml up -d --build

build:
	@docker compose -f ./srcs/docker-compose.yml build

down:
	@docker compose -f ./srcs/docker-compose.yml down

re:
	@docker compose -f ./srcs/docker-compose.yml down -v
	@sudo rm -rf /home/meaydino/data
	@mkdir -p /home/meaydino/data/wordpress
	@mkdir -p /home/meaydino/data/mariadb
	@docker compose -f ./srcs/docker-compose.yml up -d --build

clean:
	@docker compose -f ./srcs/docker-compose.yml down --rmi all -v
	@sudo rm -rf /home/meaydino/data

.PHONY: all build down re clean
