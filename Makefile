name = inception

all:
	@mkdir -p /home/meaydino/data/wordpress
	@mkdir -p /home/meaydino/data/mariadb
	@docker compose -f ./srcs/docker-compose.yml up -d --build

build:
	@docker compose -f ./srcs/docker-compose.yml build

down:
	@docker compose -f ./srcs/docker-compose.yml down

clean:
	@docker compose -f ./srcs/docker-compose.yml down

fclean:
	@docker compose -f ./srcs/docker-compose.yml down --rmi all -v
	@sudo rm -rf /home/meaydino/data

re: fclean all

.PHONY: all build down clean fclean re
