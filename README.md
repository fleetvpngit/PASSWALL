# Instalação do PASSWALL + XRAY-CORE no OpenWrt 22.03.05

Este script instala o **PASSWALL** e o **XRAY-CORE** no OpenWrt.

Devido ao armazenamento insuficiente, a instalação do Xray-Core é feita na memória temporária do roteador, ou seja, ao reiniciar é necessário inserir novamente o arquivo xray na pasta /tmp.

---

## Detalhes do ambiente compatível

- **Versão do OpenWrt:** 22.03.05  
- **Modelo do roteador:** Xiaomi MI 4 A Gigabit  
- **Espaço de armazenamento necessário:** 8 MB+  
- **Memória RAM necessária:** 128 MB+

---

## Comando para instalação

Execute o comando abaixo no terminal do seu roteador para baixar e instalar o script:

```sh
cd / && wget -O passwall-install.sh https://raw.githubusercontent.com/fleetvpngit/PASSWALL/refs/heads/main/passwall-install.sh && chmod +x passwall-install.sh && sh passwall-install.sh
