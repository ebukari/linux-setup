cd /opt && f=Jackett.Binaries.LinuxAMDx64.tar.gz && sudo wget -Nc https://github.com/Jackett/Jackett/releases/latest/download/"$f" && sudo tar -xzf "$f" && sudo rm -f "$f" && cd Jackett* && sudo chown $(whoami):$(id -g) -R "/opt/Jackett" && sudo ./install_service_systemd.sh && systemctl status jackett.service && cd - && echo -e "\nVisit http://127.0.0.1:9117"

# TDO
# Visit http://127.0.0.1:9117
# extract api key
# edit jackett.json with api key before copy to new location

cp -f ../overwrites/jackett.json ~/.local/share/qBittorrent/nova3/engines/
