curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >> /home/$(whoami)/.bashrc

source /home/$(whoami)/.bashrc
mkdir -p ~/.config && touch ~/.config/starship.toml
starship preset pastel-powerline -o ~/.config/starship.toml
