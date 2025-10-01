# Makefile pour le projet Dog Breed Identifier

# Variables
DOCKER_IMAGE = dog-breed-identifier
DOCKER_HUB_REPO = mackly45/dog-breed-identifier

# Commandes de base
.PHONY: help build run dev stop clean test deploy

help:
	@echo "Commandes disponibles:"
	@echo "  make build     - Construire l'image Docker"
	@echo "  make run       - Lancer l'application en production"
	@echo "  make dev       - Lancer l'application en développement"
	@echo "  make stop      - Arrêter les conteneurs"
	@echo "  make clean     - Nettoyer les conteneurs et images"
	@echo "  make test      - Exécuter les tests"
	@echo "  make deploy    - Déployer sur Docker Hub"

build:
	docker build -t $(DOCKER_IMAGE) .

run:
	docker run -p 8000:8000 $(DOCKER_IMAGE)

dev:
	docker-compose up

stop:
	docker-compose down

clean:
	docker-compose down -v
	docker rmi $(DOCKER_IMAGE) || true

test:
	docker build -t $(DOCKER_IMAGE)-test -f Dockerfile.test .
	docker run --rm $(DOCKER_IMAGE)-test

deploy:
	./deploy.sh -Auto

# Commandes de développement
.PHONY: shell logs db-migrate db-shell

shell:
	docker-compose exec web bash

logs:
	docker-compose logs -f web

db-migrate:
	docker-compose exec web python manage.py migrate

db-shell:
	docker-compose exec web python manage.py dbshell