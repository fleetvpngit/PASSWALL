#!/bin/sh

# Definição de cores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # Sem cor (reset)

echo -e "${CYAN}🕓 Configurando fuso horário para America/Sao_Paulo...${NC}"
uci set system.@system[0].timezone='America/Sao_Paulo'
uci set system.@system[0].zonename='America/Sao_Paulo'
uci commit system

echo -e "${BLUE}🌍 Ajustando fuso horário no arquivo /etc/config/system...${NC}"
sed -i "s|^\(\s*option zonename\).*|\1 'America/Sao Paulo'|" /etc/config/system
sed -i "s|^\(\s*option timezone\).*|\1 '<-03>3'|" /etc/config/system

echo -e "${GREEN}✅ Fuso horário atualizado no arquivo de configuração.${NC}"
/etc/init.d/system reload || echo -e "${YELLOW}ℹ️ Reinicie o sistema para aplicar o fuso horário.${NC}"

echo -e "${CYAN}⏰ Sincronizando hora com NTP...${NC}"
/etc/init.d/sysntpd enable
/etc/init.d/sysntpd restart
sleep 3

echo -e "${MAGENTA}🛠️ ESTE SCRITP FOI FEITO PARA OPENWRT 22.03.03 (mipsel_24kc)${NC}"
echo -e "${MAGENTA}- INSTALA O PASSWALL E PACOTES"
echo -e "${MAGENTA}- INSTALA O XRAY NA MEMÓRIA TEMPORÁRIA(/tmp)${NC}"
echo

# Pergunta ao usuário
while true; do
  read -rp "$(echo -e "${YELLOW}❓ VOCÊ QUER INSTALAR O PASSWALL E XRAY? (S/N): ${NC}")" resposta
  resposta=$(echo "$resposta" | tr '[:upper:]' '[:lower:]')
  case "$resposta" in
    s) break ;;
    n) echo -e "${RED}❌ Instalação cancelada pelo usuário.${NC}" ; exit 0 ;;
    *) echo -e "${RED}Por favor, responda com 'S' ou 'N'.${NC}" ;;
  esac
done

echo -e "${CYAN}📝 Desativando verificação de assinatura em opkg.conf...${NC}"
sed -i 's/^option check_signature/#option check_signature/' /etc/opkg.conf

echo -e "${BLUE}➕ Adicionando repositórios do PassWall...${NC}"
cat <<EOF >> /etc/opkg/customfeeds.conf

# Repositórios PassWall (mipsel_24kc para OpenWrt 22.03)
src/gz passwall_luci http://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-22.03/mipsel_24kc/passwall_luci
src/gz passwall_packages http://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-22.03/mipsel_24kc/passwall_packages
src/gz passwall2 http://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-22.03/mipsel_24kc/passwall2
EOF

echo -e "${CYAN}🔄 Atualizando lista de pacotes...${NC}"
opkg update

echo -e "${YELLOW}🧹 Removendo dnsmasq padrão...${NC}"
opkg remove dnsmasq
opkg install dnsmasq-full

echo -e "${GREEN}⬇️ Instalando pacotes base...${NC}"
opkg install ipset ipt2socks iptables iptables-legacy

echo -e "${GREEN}🌐 Instalando NAT e DNS completo...${NC}"
opkg install kmod-ipt-nat

echo -e "${GREEN}🔗 Instalando módulos de rede para tunelamento...${NC}"
opkg install kmod-tun

echo -e "${GREEN}🔧 Instalando módulos extras para iptables (jogos/TPROXY)...${NC}"
opkg install iptables-mod-conntrack-extra
opkg install iptables-mod-iprange
opkg install iptables-mod-socket
opkg install iptables-mod-tproxy

echo -e "${MAGENTA}🎮 Instalando PassWall e interface LuCI...${NC}"
opkg install luci-app-passwall

echo -e "${MAGENTA}📦 Instalando openssh-sftp-server...${NC}"
opkg install openssh-sftp-server

echo -e "${YELLOW}🧹 Atualizando arquivo de configuração do PassWall...${NC}"
rm -f /etc/config/passwall
wget -O /etc/config/passwall https://raw.githubusercontent.com/fleetvpngit/PASSWALL/refs/heads/main/config/passwall
chmod +x /etc/config/passwall

echo -e "${CYAN}🔁 Ativando início automático do PassWall...${NC}"
/etc/init.d/passwall enable

echo -e "${CYAN}📥 Baixando xray-core para /tmp...${NC}"
wget -O /tmp/xray https://github.com/fleetvpngit/PASSWALL/raw/refs/heads/main/xray-core/xray
chmod +x /tmp/xray

rm -f /passwall-install.sh

echo -e "${GREEN}✅ INSTALAÇÃO FINALIZADA COM SUCESSO!${NC}"
echo -e "Agora vá em ${BLUE}LuCI → Serviços → PassWall${NC} para configurar."