#!/bin/sh
echo "🛠️ Este script foi feito para funcionar no OpenWrt 22.03.5 (arquitetura mipsel_24kc)."
echo "- Instala o PassWall e pacotes no armazenamento interno do OpenWrt"
echo "- Instala o Xray-core na memória temporária (/tmp)"
echo

read -p "❓ Você quer instalar o PassWall e Xray? (S/N): " resposta

# Converte a resposta para minúscula
resposta=$(echo "$resposta" | tr '[:upper:]' '[:lower:]')

if [ "$resposta" != "s" ]; then
    echo "❌ Instalação cancelada pelo usuário."
    exit 0
fi

echo "🕓 Configurando fuso horário para America/Sao_Paulo..."
uci set system.@system[0].timezone='America/Sao_Paulo'
uci set system.@system[0].zonename='America/Sao_Paulo'
uci commit system
/etc/init.d/system reload

echo "🌍 Ajustando fuso horário no arquivo /etc/config/system..."

# Atualiza apenas a linha da opção 'zonename'
sed -i "s|^\(\s*option zonename\).*|\1 'America/Sao Paulo'|" /etc/config/system

# Atualiza apenas a linha da opção 'timezone'
sed -i "s|^\(\s*option timezone\).*|\1 '<-03>3'|" /etc/config/system

echo "✅ Fuso horário atualizado no arquivo de configuração."
/etc/init.d/system reload || echo "ℹ️ Reinicie o sistema para aplicar o fuso horário."

echo "⏰ Sincronizando hora com NTP..."
/etc/init.d/sysntpd enable
/etc/init.d/sysntpd restart
sleep 3
date

echo "📝 Desativando verificação de assinatura em opkg.conf..."
sed -i 's/^option check_signature/#option check_signature/' /etc/opkg.conf

echo "➕ Adicionando repositórios do PassWall..."
cat <<EOF >> /etc/opkg/customfeeds.conf

# Repositórios PassWall (mipsel_24kc para OpenWrt 22.03)
src/gz passwall_luci http://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-22.03/mipsel_24kc/passwall_luci
src/gz passwall_packages http://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-22.03/mipsel_24kc/passwall_packages
src/gz passwall2 http://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-22.03/mipsel_24kc/passwall2
EOF

echo "🔄 Atualizando lista de pacotes..."
opkg update

echo "🧹 Removendo dnsmasq padrão..."
opkg remove dnsmasq

echo "⬇️ Instalando pacotes base..."
opkg install ipset ipt2socks iptables iptables-legacy

echo "🔧 Instalando módulos extras para iptables (jogos/TPROXY)..."
opkg install iptables-mod-conntrack-extra
opkg install iptables-mod-iprange
opkg install iptables-mod-socket
opkg install iptables-mod-tproxy

echo "🌐 Instalando NAT e DNS completo..."
opkg install kmod-ipt-nat
opkg install dnsmasq-full

echo "🔗 Instalando módulos de rede para tunelamento..."
opkg install kmod-tun

echo "🎮 Instalando PassWall e interface LuCI..."
opkg install luci-app-passwall

rm -f /passwall-install.sh

echo "📥 Baixando xray-core para /tmp..."
wget -O /tmp/xray https://github.com/fleetvpngit/PASSWALL/raw/refs/heads/main/xray-core/xray
chmod +x /tmp/xray

sed -i "s|option xray_file '/usr/bin/xray'|option xray_file '/tmp/xray'|" /etc/config/passwall

echo "🧹 ATUALIZANDO ARQUIVO DE CONFIGURACAO DO PASSWALL..."
rm -f /etc/config/passwall
wget -O /etc/config/passwall https://raw.githubusercontent.com/fleetvpngit/PASSWALL/refs/heads/main/config/passwall
chmod +x /etc/config/passwall

echo "🔁 Reiniciando o PassWall..."
/etc/init.d/passwall restart

echo "🔁 Ativando inicio automatico..."
/etc/init.d/passwall enable


echo "✅ Instalação finalizada com sucesso! Agora vá em LuCI → Serviços → PassWall para configurar."