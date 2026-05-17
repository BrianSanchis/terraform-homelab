#!/bin/bash
set -e
source "$(dirname "$0")/_lib.sh"

NEXT_IP=$(next_ip 1)

echo ""
echo "Type de base de données :"
echo "  1) MariaDB"
echo "  2) PostgreSQL"
echo "  3) Redis"
echo "  4) MongoDB"
echo ""
read -p "Choix (1-4) : " DB_CHOIX

case "$DB_CHOIX" in
  1) DB_TYPE="mariadb" ;;
  2) DB_TYPE="postgresql" ;;
  3) DB_TYPE="redis" ;;
  4) DB_TYPE="mongodb" ;;
  *) echo "Erreur : choix invalide." && exit 1 ;;
esac

echo ""
read -p "Nom du serveur (ex: db-1)        : " NAME
read -p "IP  (ex: $NEXT_IP) : " IP
read -p "Node (pve1 ou pve2)              : " NODE

[[ -z "$NAME" || -z "$IP" || -z "$NODE" ]] && echo "Erreur : tous les champs sont requis." && exit 1
validate_node "$NODE"

echo ""
add_container "$NAME" "$IP" "$NODE" "\"db\", \"$DB_TYPE\", \"terraform\""
add_to_ansible "$NAME" "$IP" "databases"

echo ""
update_outputs
echo "Lance 'terraform apply' pour déployer."
