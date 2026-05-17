#!/bin/bash
set -e
source "$(dirname "$0")/_lib.sh"

CONTAINERS=$(list_containers)

if [[ -z "$CONTAINERS" ]]; then
  echo "Aucun container trouvé dans main.tf."
  exit 1
fi

echo ""
echo "Containers disponibles :"
echo ""
i=1
declare -a LIST
while IFS= read -r name; do
  echo "  $i) $name"
  LIST+=("$name")
  ((i++))
done <<< "$CONTAINERS"

echo ""
read -p "Numéro du serveur à supprimer : " CHOIX

if ! [[ "$CHOIX" =~ ^[0-9]+$ ]]; then
  echo "Erreur : entrez un numéro, pas un nom."
  exit 1
fi

RESOURCE_NAME="${LIST[$((CHOIX-1))]}"

if [[ -z "$RESOURCE_NAME" ]]; then
  echo "Erreur : numéro hors limites (1-${#LIST[@]})."
  exit 1
fi

remove_container "$RESOURCE_NAME"
remove_from_ansible "$RESOURCE_NAME"

echo ""
update_outputs
echo "Lance 'terraform apply' pour appliquer la suppression."
