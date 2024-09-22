#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Проект 'BetterPtero установщик'                                                    #
#                                                                                    #
# Copyright (C) 2024, Wixely, <support@wixely.ru> Oh yeah!                           #
#                                                                                    #
#   Данный скрипт абсолютно бесплатен для каждого, что делает его уникальным.        #
#   Если права не соответствуют GNU General Public License как указано               #
#   Free Software Foundation, ниже 3 версии лицензии, ну или же                      #
#   самой последней версии (на Ваш выбор).                                           #
#                                                                                    #
# Этот скрипт никак НЕ СВЯЗАН с проектом Pterodactyl Panel.                          #
# https://github.com/pterodactyl-installer/pterodactyl-installer                     #
#                                                                                    #
# © COPYRIGHT - WIXELY 2024 | DSC.WIXELY.RU | BETTER-PTERO BY @RAIZZOR_OFFICIAL      #
#                                                                                    #
######################################################################################

export GITHUB_SOURCE="v1.1.0"
export SCRIPT_RELEASE="v1.1.0"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer"

LOG_PATH="/var/log/pterodactyl-installer.log"

# check for curl
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

# Always remove lib.sh, before downloading it
[ -f /tmp/lib.sh ] && rm -rf /tmp/lib.sh
curl -sSL -o /tmp/lib.sh "$GITHUB_BASE_URL"/master/lib/lib.sh
# shellcheck source=lib/lib.sh
source /tmp/lib.sh

execute() {
  echo -e "\n\n* pterodactyl-installer $(date) \n\n" >>$LOG_PATH

  [[ "$1" == *"canary"* ]] && export GITHUB_SOURCE="master" && export SCRIPT_RELEASE="canary"
  update_lib_source
  run_ui "${1//_canary/}" |& tee -a $LOG_PATH

  if [[ -n $2 ]]; then
    echo -e -n "* Установка $1 успешно завершена. Вы готовы к установке $2? (y/N): "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ [Yy] ]]; then
      execute "$2"
    else
      error "Установка $2 отменена."
      exit 1
    fi
  fi
}

welcome ""

done=false
while [ "$done" == false ]; do
  options=(
    "Установить панель (LATEST)"
    "Установить крылья (WINGS - LATEST)"
    "Установить [0] и [1] на текущюю машину (установка Wings будет после окончания установки панели)"
    # "Uninstall panel or wings\n"

    "Установить панель, но с новой версией скрипта"
    "Install Wings with canary version of the script (the versions that lives in master, may be broken!)"
    "Install both [3] and [4] on the same machine (wings script runs after panel)"
    "Uninstall panel or wings with canary version of the script (the versions that lives in master, may be broken!)"
  )

  actions=(
    "panel"
    "wings"
    "panel;wings"
    # "uninstall"

    "panel_canary"
    "wings_canary"
    "panel_canary;wings_canary"
    "uninstall_canary"
  )

  output "Что Вы хотите установить?"

  for i in "${!options[@]}"; do
    output "[$i] ${options[$i]}"
  done

  echo -n "* Input 0-$((${#actions[@]} - 1)): "
  read -r action

  [ -z "$action" ] && error "Эмм, пустое поле? Нет уж! Сначала выберите!" && continue

  valid_input=("$(for ((i = 0; i <= ${#actions[@]} - 1; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "Invalid option"
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && IFS=";" read -r i1 i2 <<<"${actions[$action]}" && execute "$i1" "$i2"
done

# Remove lib.sh, so next time the script is run the, newest version is downloaded.
rm -rf /tmp/lib.sh
