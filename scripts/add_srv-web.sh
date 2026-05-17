#!/bin/bash
set -e
source "$(dirname "$0")/_lib.sh"

NEXT_IP1=$(next_ip 1)
NEXT_IP2=$(next_ip 2)

echo ""
echo "1) Ajouter un seul serveur web"
echo "2) Ajouter deux serveurs web en load balancing"
echo ""
read -p "Choix (1 ou 2) : " CHOIX

if [[ "$CHOIX" == "1" ]]; then

  read -p "Nom (ex: web-3)                  : " NAME
  read -p "IP  (ex: $NEXT_IP1) : " IP
  read -p "Node (pve1 ou pve2)              : " NODE

  [[ -z "$NAME" || -z "$IP" || -z "$NODE" ]] && echo "Erreur : tous les champs sont requis." && exit 1
  validate_node "$NODE"

  echo ""
  add_container "$NAME" "$IP" "$NODE" '"web", "terraform"'
  add_to_ansible "$NAME" "$IP" "webservers"

elif [[ "$CHOIX" == "2" ]]; then

  read -p "Nom web-1 (ex: web-3)            : " NAME1
  read -p "IP  web-1 (ex: $NEXT_IP1) : " IP1
  read -p "Node web-1 (pve1 ou pve2)        : " NODE1
  read -p "Nom web-2 (ex: web-4)            : " NAME2
  read -p "IP  web-2 (ex: $NEXT_IP2) : " IP2
  read -p "Node web-2 (pve1 ou pve2)        : " NODE2

  [[ -z "$NAME1" || -z "$IP1" || -z "$NODE1" || -z "$NAME2" || -z "$IP2" || -z "$NODE2" ]] && echo "Erreur : tous les champs sont requis." && exit 1
  validate_node "$NODE1"
  validate_node "$NODE2"

  echo ""
  add_container "$NAME1" "$IP1" "$NODE1" '"web", "terraform"'
  add_container "$NAME2" "$IP2" "$NODE2" '"web", "terraform"'
  add_to_ansible "$NAME1" "$IP1" "webservers"
  add_to_ansible "$NAME2" "$IP2" "webservers"

else
  echo "Erreur : choix invalide."
  exit 1
fi

echo ""
update_outputs
echo "Lance 'terraform apply' pour déployer."
