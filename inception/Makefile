COMPOSE_FILE := srcs/docker-compose.yml
DATA_DIR := /home/numancan/data
WORDPRESS_DIR := $(DATA_DIR)/wordpress
MARIADB_DIR := $(DATA_DIR)/mariadb

all: up

up:
	sudo mkdir -p $(WORDPRESS_DIR)
	sudo mkdir -p $(MARIADB_DIR)
	docker compose -f $(COMPOSE_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) down 

clean:
	docker compose -f $(COMPOSE_FILE) down -v --remove-orphans
	docker system prune -af --volumes

fclean: clean
	@if [ -n "$$(docker images -q)" ]; then \
		docker rmi -f $$(docker images -q); \
	else \
		echo "No Docker images to remove."; \
	fi
	sudo rm -rf $(WORDPRESS_DIR) $(MARIADB_DIR)

DOMAIN_NAME := $(shell grep ^DOMAIN_NAME= ./srcs/.env | cut -d '=' -f2)

addhost:
	@echo "Adding host entry for $(DOMAIN_NAME) -> 127.0.0.1"
	@sudo sed -i.bak "/\s$(DOMAIN_NAME)$$/d" /etc/hosts; \
	echo "127.0.0.1 $(DOMAIN_NAME)" | sudo tee -a /etc/hosts > /dev/null; \
	echo "Host entry added: 127.0.0.1 $(DOMAIN_NAME)"


re: fclean all

.PHONY: all up down clean fclean re