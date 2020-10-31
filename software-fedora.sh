#! /bin/bash

error_exit()
{
  echo "Error in $1 section. Exiting" 1>&2
  exit 1
}

update_repos() { 
  sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf install -y http://repo.linrunner.de/fedora/tlp/repos/releases/tlp-release.fc$(rpm -E %fedora).noarch.rpm 
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo ln -s $HOME/dotfiles/fedora/repos/vscode.repo /etc/yum.repos.d/vscode.repo
  sudo dnf update -y && sudo dnf upgrade -y
}

install_base_utilities() {
  #TODO: Exfat in kernel fix
  sudo dnf install -y ranger vifm strace curl wget tmux xclip jq fzf bat fuse-exfat exfat-utils
}

install_command_line_fun() {
  sudo dnf install -y cmatrix neofetch fortune-mod cowsay
}


install_security_utilities() {
  sudo dnf install -y gnupg1 gnupg2 pass openssh
  # TODO: fix gpg key generation to work without prompts
  # cat /etc/passwd | grep $USER | cut -d: -f5 #user real name
  gpg --full-gen-key
  read -p 'Enter email address associated with your GPG key' GPGEMAIL
  pass init $GPGEMAIL
}

create_ssh_key() {
  read -p "Enter the email address you want associated with your SSH key: " EMAILSSH 
  ln -s $HOME/dotfiles/ssh/config $HOME/.ssh/config
  if [ ! -d "$HOME/.ssh" ]; then
    ssh-keygen -t rsa -b 4096 -C $EMAILSSH
    eval "$(ssh-agent -s)"
    ssh-add $HOME/.ssh/id_rsa
  fi
}

install_acpi_tlp() {
  #TODO: F32 TLP for Thinkpads
  sudo dnf install -y tlp tlp-rdw smartmontools
  sudo dnf install -y kernel-devel akmod-acpi_call akmod-tp_smapi
  sudo tlp start
}

install_base_development_system() {
  sudo dnf groupinstall -y "Development Tools"
  sudo dnf groupinstall -y "C Development Tools and Libraries"
  sudo dnf install -y cmake
}

install_fedora_packaging() {
  sudo dnf install -y fedora-packager @development-tools
  sudo usermod -aG mock $USER
  rpmdev-setuptree
  # TODO: Refactor to use a separate user for packaging
}

install_fedora_releng() {
  echo "TODO: Install RelEng tooling for F31"
  #TODO: Install tooling for Fedora Release Engineering
}

install_node() {
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 
  nvm install --lts

  # Install Yarn for Node JS
  sudo dnf install -y yarnpkg

  # Install Node Utilities
  sudo yarn global add create-react-app @vue/cli eslint gatsby-cli @gridsome/cli jest
}

install_python() {
  sudo dnf install -y  python3-devel pipenv
}

install_go() {
  sudo dnf install -y golang
}

install_java() {
  sudo dnf install -y java-11-openjdk-devel java-1.8.0-openjdk-devel
  wget -O $HOME/Downloads/gradle-6.3-bin.zip https://services.gradle.org/distributions/gradle-6.3-bin.zip
  sudo unzip -d /opt/ $HOME/Downloads/gradle-6.3-bin.zip
  rm $HOME/Downloads/gradle-6.3-bin.zip
  export PATH=$PATH:/opt/gradle-6.3/bin
}

install_virt() {
  cat /proc/cpuinfo | egrep "vmx|svm" #TODO: error break
  sudo dnf group install --with-optional virtualization
  sudo systemctl enable libvirtd
}

install_docker() {
  #TODO: Install Podman in place of Docker and Docker Compose
  #sudo dnf remove -y docker docker-client docker-client-latest docker-common \
                  #docker-latest docker-latest-logrotate docker-logrotate \
                  #docker-selinux docker-engine-selinux docker-engine
  #sudo dnf install -y dnf-plugins-core
  #sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  #sudo dnf install -y docker-ce docker-ce-cli containerd.io
  sudo dnf install -y moby-engine moby-engine-vim
  sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
  sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
}

install_kubernetes_tools() {
  sudo dnf install -y kubernetes
  curl -Lo $HOME/Downloads/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 
  chmod +x $HOME/Downloads/minikube
  sudo install $HOME/Downloads/minikube /usr/local/bin/
}

install_config_mgmt() {
  sudo dnf install -y ansible
}

install_provisioning() {
  wget -O $HOME/Downloads/terraform_0.12.24_linux_amd64.zip https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
  sudo unzip -d /usr/local/bin/ $HOME/Downloads/terraform_0.12.24_linux_amd64.zip
}

install_serverless_framework() {
  curl -o- -L https://slss.io/install | bash
}

install_cloud_cli_tools() {
  #TODO: Install Digital Ocean Tools
  # Install AWS and Boto3
  #TODO: boto3 error on install asking for dependency botocore
  sudo dnf install -y python3-boto3
  pip3 install --user awscli
  #TODO: Install Azure CLI
  #TODO: Install GCP CLI
}

# TODO: Use cypress.io to automate the firefox and chromium installations

install_firefox_dev() {
  firefox_dev_installed=false
  local skipper
  printf "%s\n" "Press any key to open Firefox and download Firefox Developer Edition. Close Firefox when finished"
  printf "%s\n" "This will close any open Firefox session, save work and continue or Ctrl-C now to exit"
  read -p "Enter s to skip: " skipper
  if [[ $skipper != 's' && $skipper != 'S' ]]; then
    killall firefox
    firefox "https://www.mozilla.org/en-US/firefox/developer/"
    if [[ -d "/opt/firefox" || -d "/opt/firefox-developer-edition" ]]; then
      sudo rm -rf /opt/firefox
      sudo rm -rf /opt/firefox-developer-edition
    fi
    sudo tar -xvf $HOME/Downloads/firefox* -C /opt/
    sudo mv /opt/firefox/ /opt/firefox-developer-edition/
    sudo chown adam /opt/firefox-developer-edition/
    if [ -L /usr/share/applications/firefox-developer-edition.desktop ]; then
      sudo rm /usr/share/applications/firefox-developer-edition.desktop
    elif [ -e /usr/share/applications/firefox-developer-edition.desktop ]; then
      sudo cp /usr/share/applications/firefox-developer-edition.desktop /usr/share/applications/firefox-developer-edition.desktop.old
    fi
    sudo ln -s $HOME/dotfiles/gnome/firefox-developer-edition.desktop /usr/share/applications/
    firefox_dev_installed=true
  fi
  if [ "$firefox_dev_installed" = true ]; then
    sync_firefox_dev
    add_ssh_to_gits
  fi 
}

# Turn On Sync for Firefox
sync_firefox_dev() {
  local skipper
  printf "%s\n" "Press any key to open Firefox Developer Edition and set up syncing. Close Firefox when finished"
  read -p "Enter s to skip: " skipper
  echo $skipper
  if [[ $skipper != 's' && $skipper != 'S' ]]; then
    killall firefox
    /opt/firefox-developer-edition/firefox 
  fi
}

# Add SSH to Github/GitLab using Firefox Developer Edition
add_ssh_to_gits() {
  local skipper
  printf "%s\n" "Press any key to open Firefox and set up Github and GitLab.  Close Firefox when finished"
  read -p "Enter s to skip: " skipper
  echo $skipper
  if [[ $skipper != 's' && $skipper != 'S' ]]; then
    killall firefox
    xclip -sel clip < $HOME/.ssh/id_rsa.pub
    /opt/firefox-developer-edition/firefox www.github.com www.gitlab.com
  fi
}

install_chromium() {
  sudo dnf install -y chromium
  printf "%s\n" "Press any key to open Chromium and set up syncing.  Close Chromium when finished"
  read -p "Enter s to skip: " SKIPPER
  if [[ $SKIPPER != 's' && $SKIPPER != 'S' ]]; then
    chromium-browser
  fi
}

install_qutebrowser() {
  sudo dnf install -y qutebrowser mpv youtube-dl
  #TODO: Install qutebrowser config
}

install_vscode() {
  sudo dnf install -y code
}

install_gui_tools() {
  sudo dnf install -y hexchat 
}

add_flatpak_repos() {
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

install_postman() {
  sudo flatpak install -y postman
}

install_bitwarden() {
  sudo flatpak install -y bitwarden
}

install_chats() {
  sudo flatpak install -y slack
  sudo flatpak install -y discord
  # TODO: matrix
}

install_fonts() {
  sudo dnf install -y fontawesome-fonts fontawesome-fonts-web powerline-fonts fira-code-fonts
  # TODO: web-fonts, ms and mac standard fonts, hack font, anonymous pro
}

install_graphics_apps() {
  sudo dnf install -y inkscape gimp
  # TODO: darktable, shotwell, pdfsam, libre-office
}

install_i3wm() {
  echo "TODO: Install i3wm or sway"
  #TODO: Install i3wm
  #sudo dnf it -y i3 rofi xbacklight feh
}

install_rice() {
  echo "TODO: Rice"
}

install_powerline() {
  pip3 install --user powerline-status
  #TODO: Vim powerline not working
}

clone_dotfiles() {
  echo "TODO: Determine the best place for cloning dotfile"
  #TODO: Clone dotfiles repo - this is only neccessary if I'm going to curl the script down
  #git clone https://github.com/adamayd/dotfiles.git $HOME/dotfiles
}

link_dotfiles() {
  echo "source $HOME/dotfiles/shellsrc" >> $HOME/.bashrc
  if [ -L $HOME/.vimrc ]; then
    rm $HOME/.vimrc
  elif [ -e $HOME/.vimrc ]; then
    cp $HOME/.vimrc $HOME/.vimrc_old
  fi
  ln -s $HOME/dotfiles/vimrc $HOME/.vimrc
  ln -s $HOME/dotfiles/tmux.conf $HOME/.tmux.conf
  ln -s $HOME/dotfiles/gitconfig $HOME/.gitconfig
  sudo ln -s $HOME/dotfiles/gnome/firefox-developer-edition.desktop /usr/share/applications/
}

install_vim() {
  sudo dnf install -y vim 
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  vim +PlugInstall +qall
  python3 $HOME/.vim/plugged/YouCompleteMe/install.py --clangd-completer --go-completer --ts-completer --java-complete
  cd $HOME
  mkdir -p $HOME/.vim/spell $HOME/.vim/undodir
  ln -s $HOME/dotfiles/vim/spell/en.utf-8.add $HOME/.vim/spell/en.utf-8.add
}

install_oh_my_bash() {
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
}

#update_repos || error_exit "Update Repos"
#install_base_utilities || error_exit "Base Utilites" #TODO: Exfat in kernel
#install_command_line_fun || error_exit "Command Line Fun"
#install_security_utilities || error_exit "" #TODO: GPG command arguments build out
#create_ssh_key || error_exit "" #TODO: - refactor for email input
#install_acpi_tlp || error_exit "" #TODO: - F32 TLP manual install for thinkpads
#install_base_development_system || error_exit ""
#install_fedora_packaging || error_exit ""
#TODO: install_fedora_releng || error_exit ""
#install_node || error_exit ""
#install_python || error_exit ""
#install_go || error_exit ""
#install_java || error_exit "" #TODO: - combine with gradle/build tools below
#install_virt || error_exit "Virtual Machine" #TODO: error break for virt bios detection
#install_docker || error_exit "" # docker-ce and cgroups v1
#install_kubernetes_tools || error_exit "" #TODO: - finish install
#install_config_mgmt || error_exit ""
#install_provisioning || error_exit ""
#install_cloud_cli_tools || error_exit "" #TODO: - finish all of them
#install_serverless_framework || error_exit ""
#install_firefox_dev || error_exit "" #TODO: - update to latest logic and create failsafe for browser opening
#install_chromium || error_exit "" #TODO: 
#install_qutebrowser || error_exit "" #TODO: - config and extras setup
#install_vscode || error_exit "" #TODO: - create and copy over config files
#install_gui_tools || error_exit "" #TODO: - get all GUI tools
#add_flatpak_repos || error_exit ""
#install_postman || error_exit ""
#install_bitwarden || error_exit ""
#install_chats || error_exit "" #TODO: matrix
#install_fonts || error_exit "" #TODO: - hack font for fedora
#TODO: install_i3wm || error_exit ""
#TODO: install_graphics_apps || error_exit "" # darktable, shotwell??
#TODO: install_rice || error_exit "" - no rice set
#install_powerline || error_exit ""
#TODO: clone_dotfiles || error_exit "" - proper location for script running from web
#link_dotfiles || error_exit "" - #TODO: Link dotfiles with appropriate installs instead of at once
#install_vim || error_exit "" #TODO: - gruvbox error on initial load for plugin install
#install_oh_my_bash || error_exit "" #TODO: #- link .bashrc correctly and choose powerline-multiline
#TODO: vifm to look and operate more like ranger with previews.

