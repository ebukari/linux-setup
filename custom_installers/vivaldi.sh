url=$(curl -s https://vivaldi.com/download/ | grep -oP 'href="\K[^"]*amd64\.deb' | head -n 1)
# Ensure the URL is absolute
if [[ $url == //* ]]; then url="https:$url"; fi

wget "$url" -O vivaldi.deb
sudo dpkg -i vivaldi.deb
sudo apt install -f  # Fix dependencies
