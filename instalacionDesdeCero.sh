#!/bin/bash
############################################################
# Set variables
declare -r DESTINO='/media/homeUbuntu/luis'
declare -i N=1

############################################################
# CONTANTES                                                #
############################################################
#ANSI Code 	Description
#0 	Normal Characters
#1 	Bold Characters
#4 	Underlined Characters
#5 	Blinking Characters
#7 	Reverse video Characters
declare -r ALERTA="\e[1;37;4;42m"
declare -r RESET="\e[0m"


############################################################
# Help                                                     #
############################################################
_help() {
   # Display Help
   echo "Nuevo sistema... toca ponerlo a punto."
   echo
   echo "Syntax: $(basename $0) [-h|?|i|l]"
   echo "options:"
   echo -e "h|? \t Print this Help."
   echo -e "i \t Intala paquetes."
   echo -e "l \t Crea enlaces simbólicos."
   echo
}

############################################################
# _inst: actualiza e instala si es necesario               #
############################################################
function _inst {
    sudo apt-get update
    while [ "$*" ]; do
	echo -n "$1 -> "
        if  ! which $1 > /dev/null; then
	    sudo apt show $1 2> /dev/null | grep "Installed: yes" | grep "yes" >/dev/null
	    if [[ $? -eq 0 ]]; then shift; continue; fi
	    echo -e "-------------> El paquete ${ALERTA}${1}${RESET} no está instalado"
            sudo apt-get -y install "$@" 2> temp;
            break;
        fi ;
        shift ;
    done

    echo "----------------------------------------"
    echo "Han fallado:"
    cat temp
    rm temp
    
}


############################################################
# Pregunta                                                 #
############################################################
_opcional() {
    operation=$(dialog --stdout --title "Paso $N" \
                --backtitle "$0" \
                --yesno "$1" 7 60)
    if [[ $? -eq 0 ]]; then
        _inst ${2[*]}
    fi
    ((N++))
}

############################################################
# Intalaciones                                             #
############################################################
_install() {
    #sudo apt-get update && sudo apt-get dist-upgrade

    echo "-----------------------------------------"
    PAQ=(aptitude htop neofetch grsync tldr emacs nemo curl jq libfuse2 \
                trash-cli davfs2 rclone rclone-browser meld \
                xclip libreoffice pandoc encfs davfs2 \
                feh net-tools \
                )
    _opcional "¿Instalar paquetes básicos?" $PAQ 
    

    PAQ=(texlive-latex-base \texlive-extra-utils texlive-fonts-extra \
                texlive-fonts-extra-links texlive-fonts-recommended \
                texlive-lang-spanish ispanish \
                )
    _opcional "¿Instalar paquetes LaTeX COMPLETO?" $PAQ 

    
    PAQ=(virtualbox virtualbox-guest-additions-iso virtualbox-guest-utils virtualbox-ext-pack vagrant)
    _opcional "¿Instalar paquetes Virtualbox y Vagrant?" $PAQ 
    
    
    PAQ=(git gitg giggle)
    _opcional "¿Instalar paquetes git, gitg y giggle?" $PAQ 
    # PAQ+=(miniupnpc)

    # Dependiente del S.O. base
    DIST=$(lsb_release -i  | awk '{print $3}')
    if [[ $DIST == 'Ubuntu' ]]; then 
	echo -e "---> Estamos en ${ALERTA}Ubuntu${RESET}"
        PAQ=(ubuntu-restricted-extras gnome-shell-extensions gir1.2-gst-plugins-base-1.0 \
              chrome-gnome-shell bat tilix )
        _opcional "¿Instalar paquetes Extras y Tilix?" $PAQ 
              # conky-all
        #PAQ+=(gsconnect gnome-browser-connector gnome-tweak-tool)
    elif [[ $DIST == 'Debian' ]]; then 
        PAQ=(firefox chromium batcat)
        _opcional "¿Instalar paquetes firefox, chromium y batcat?" $PAQ 
    # else PAQ+=(tilix conky-all batcat)
    fi

    # openjdk-17-jdk
    # baobab -> Analizador de uso de disco (Filelight en KDE)
    # kdeconnect -> gsconnect
    # redshift, sticky
    # nala screenkey
    # batcat se instala con bat
    # BBDD -> sudo snap install redis-desktop-manager
    # Plugins cinnamon:
    #  21   │ Stevedor - Docker controller (stevedore@centurix)
    #  22   │ WireGuard (wireguard@nicoulaj.net)
    #  23   │ Desactivación (inhibit@cinnamon.org)
    #  24   │ Radio++ (radio@driglu4it)


    #echo "Se van a instalar los paquetes: ${PAQ[*]}"
    #_inst ${PAQ[*]}
    sudo apt-get autoremove


# Instalacion de snap y paquetes asociados
    if [[ $DIST = 'Ubuntu' ]]; then
        # SNAP
        echo "-----------------------------------------"
        PAQ=(firefox chromium gnome-browser-connector)
        echo "Se van a instalar los paquetes: ${PAQ[*]}"
        for i in "${PAQ[@]}"; do
		echo "$i"
		sudo snap install "$i"
        	#sudo snap install ${PAQ[*]}
        done
    else
        sudo service snapd status
        if [[ ! $? ]]; then _inst snap;	fi
    fi

    
    # Intellij
    #----------
    operation=$(dialog --stdout --title "¿Intalar Intellij-idea-ultimate snapd?" \
                --backtitle "$0" \
                --yesno "Sí - No" 7 60)
    if [[ $? -eq 0 ]]; then
        sudo snap install intellij-idea-ultimate --classic
    fi
    ((N++))
    

    # sudo update-alternatives --config x-terminal-emulator	# cambiamos la terminal

    
    # Docker
    #--------
    operation=$(dialog --stdout --title "Paso $N" \
                --backtitle "$0" \
                --yesno "¿Instalar docker y Compose(v2)?" 7 60)
    if [[ $? -eq 0 ]]; then
        docker -v 2>/dev/null; [[ $? -eq 0 ]] && echo "Docker ya está instalado" ||  ( curl https://get.docker.com/ -o get_docker.sh && chmod +x get_docker.sh && sudo ./get_docker.sh )
        cat /etc/group | grep docker >/dev/null; [[ ! $? -eq 0 ]] && sudo groupadd docker
        id | grep docker >/dev/null
        if [[ ! $? -eq 0 ]]; then 
            sudo usermod -aG docker $USER
            newgrp docker
        fi
    fi
    ((N++))
    # No necesario en compose v2
    #docker-compose -v 2>/dev/null
    #[[ $? -eq 0 ]] && echo "Docker-compose ya está instalado" ||  ( sudo apt install docker-compose )
    #_inst docker-compose

    
    # fuentes para LaTeX
    #----------------------
    operation=$(dialog --stdout --title "Paso $N" \
                --backtitle "$0" \
                --yesno "¿Instalar fuentes de LaTeX?" 7 60)
    if [[ $? -eq 0 ]]; then
        wget -q https://www.tug.org/fonts/getnonfreefonts/install-getnonfreefonts
        sudo texlua ./install-getnonfreefonts
        sudo getnonfreefonts --sys -a
        sudo mktexlsr
        sudo updmap --sys
    fi
    ((N++))
    


    echo "-----------------------------------------"
    echo "Faltan por instalar:"
    echo "dropbox "
    echo "emacs -> config dentro de dotfiles o mejor todos los paquetes"
    echo "autofirma y fichero config"
    echo "trash-put requiere eliminar ~/.local/share/Trash y sudo mkdir .Trash-$UID && sudo chown $USER:$USER .Trash-$UID"

    cat /usr/bin/x-terminal-emulator | grep tilix
    [[ ! $? -eq 0 ]] && sudo update-alternatives --config x-terminal-emulator

    sudo cat /etc/sysctl.conf | grep 'vm.swappiness'
    if [[ ! $? -eq 0 ]];then
      sudo cp /etc/sysctl.conf /etc/sysctl.conf.old # backup 
      sudo echo 'vm.swappiness=10' >> /etc/sysctl.conf
      echo "--- Swap configurada al 10% de uso ---"
    fi
    #sudo sysctl -w vm.swappiness=10 # por defecto a 60

} # _install()

############################################################
# Enlaces simbólicos                                       #
############################################################
_crearEnlace(){
    while [ "$*" ]; do
    	if [[ ! -L $1 ]]; then
		ln -s $1 $2
		shift 2
	fi
    done
}

_links(){
    # Enlaces a particion de datos
    #BASE='/media/homeUbuntu/luis'
    BASE=$DESTINO
    DIR=(Documentos 'Imágenes' Dropbox Descargas 'Música' Plantillas)
    if [[ -d 'Documentos' ]]; then DIR_ORIGEN=(Documentos 'Imágenes' Dropbox Descargas 'Música' Plantillas)
    else DIR_ORIGEN=(Documents Pictures Dropbox Downloads Music Templates); fi

    echo "-----------------------------------------"
    echo "Restaurar enlaces"
    echo "    Tienes que eliminar los antiguos (old.)"
    length=${#DIR_ORIGEN[@]}
    for (( j=0; j<${length}; j++ )); do
        printf "Current index %d with value %s a %s\n" $j "${DIR_ORIGEN[$j]}" "${DIR[$j]}"
        D="${DIR_ORIGEN[$j]}"
        D_NEW="${DIR[$j]}"
        if [[ -L "$D" ]]; then
            echo "$D ya es un enlace simbóico... eliminando";
            #mv -f "$D" "$D.old"
        else
            echo "$D hay que hacer backup y crear enlace simbólico";
            echo "De $HOME/$D a $HOME/old.$D y ln -s $BASE/$D"
            mv -f "$HOME/$D" "$HOME/old.$D"
        fi
        ln -s "$BASE/$D_NEW" "$D"
    done

    echo
    echo "Ahora vamos a por los dotfiles"
    mkdir temp2
    mv .bash_history temp2/bash_history
    ln -s "$DESTINO/Documentos/dotfiles/.bash_history"
    #_crearEnlace "$DESTINO/Documentos/dotfiles/.bash_history" .bash_history

    mv .bashrc temp2/bashrc
    if [[ -f $HOME/.config/bash-config/bashrc.bash ]]; then ln -s "$DESTINO/Documentos/dotfiles/.bashrc_fancy" .bashrc
    else ln -s "$DESTINO/Documentos/dotfiles/.bashrc"; fi
    ln -s "$DESTINO/Documentos/dotfiles/.davfs2"

    echo
    echo "Ahora vamos a crear la estructura deseada"
    ln -s "$DESTINO/Documentos/docker/docker-compose" compose
    ln -s "$DESTINO/Documentos/curso22-23" curso
    ln -s "$DESTINO/Dropbox"
    mkdir Dropbox-seguro
    ln -s "$DESTINO/media"
    ln -s "$DESTINO/Documentos/REPOSITORIOS" repos
    mkdir webdav

    mv -f .ssh ssh.old
    ln -s "$DESTINO/Documentos/dotfiles/ssh-keys/UbuntuX1-Otonho22/.ssh" 

    sudo cp ~/Documentos/dotfiles/docker/etc/daemon.json /etc/docker/

    return 0;
    exit;
    for D in "${DIR_ORIGEN[@]}"; do
        if [[ -L "$D" ]]; then
            echo "$D ya es un enlace simbóico... eliminando";
            mv -f "$D" "$D.old"
        else
            echo "$D hay que hacer backup y crear enlace simbólico";
            echo "De $HOME/$D a $HOME/old.$D y ln -s $BASE/$D"
            mv -f "$HOME/$D" "$HOME/old.$D"
        fi
        ln -s "$BASE/$D"
    done

    for D in `ls *old*`; do
        echo "$D contine:"
        ls $D
        echo "Desea borrarlo? [y/N]"
        read R
        if [[ $R = 'y' ]]; then rm -rf $D; fi
    done
 
} #_links()

############################################################
# AppImage                                                 #
############################################################
_appImage() {
# AppImage
BASE='/media/homeUbuntu/luis/Documentos/AppImage'
echo "-----------------------------------------"
ls $BASE
# query the latest Linux release from the QOwnNotes API, parse the JSON for the URL and download it
#curl -L https://api.qownnotes.org/latest_releases/linux | jq .url | xargs curl -Lo QOwnNotes-x86_64.AppImage
#chmod a+x QOwnNotes-*.AppImage
#mv QOwnNotes-x86_64.AppImage "$BASE/"
} # _appImage()

############################################################
############################################################
# Main program                                             #
############################################################

############################################################
# Process the input options. Add options as needed.        #
############################################################
cd $PWD
if [[ $# -eq 0 ]]; then _help; fi
# Get the options
while getopts ":hila:" option; do
   case $option in
      h) # display Help
         _help
         exit;;
      i) # install packages
         _install;;
         #Name=$OPTARG;;
      l) # create links
         _links;;
      a) # AppImage
         _appImage;;
      *) echo "Error: Invalid option";;
   esac
done
