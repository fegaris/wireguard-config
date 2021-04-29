#!/bin/bash

#Exportamos el comando para poder usarlo con bash
PATH=$PATH:/bin:/usr/bin:wg
export PATH


DIR_BASE="/etc/wireguard/"
CLIENT_PATH="${DIR_BASE}clients/"





#//===========================================
#//                                           
#//  ###    ###  #####  ##     ##  ##   ##  
#//  ## #  # ##  ##     ####   ##  ##   ##  
#//  ##  ##  ##  #####  ##  ## ##  ##   ##  
#//  ##      ##  ##     ##    ###  ##   ##  
#//  ##      ##  #####  ##     ##   #####   
#//                                           
#//===========================================
echo "¿Que quieres hacer?"
echo "1 - Crear archivo de configuración para servidor"
echo "2 - Crear archivo de configuración para cliente"
echo "0 - Salir"
read option

case $option in
0)
    #salir
;;
1)
#//=================================================================================================================================================================================
#//                                                                                                                                                                                 
#//   ####   #####   ##     ##  #####  ##   ####    ##   ##  #####      ###     ####  ##   #####   ##     ##         ####  #####  #####    ##   ##  ##  ####     #####   #####    
#//  ##     ##   ##  ####   ##  ##     ##  ##       ##   ##  ##  ##    ## ##   ##     ##  ##   ##  ####   ##        ##     ##     ##  ##   ##   ##  ##  ##  ##  ##   ##  ##  ##   
#//  ##     ##   ##  ##  ## ##  #####  ##  ##  ###  ##   ##  #####    ##   ##  ##     ##  ##   ##  ##  ## ##         ###   #####  #####    ##   ##  ##  ##  ##  ##   ##  #####    
#//  ##     ##   ##  ##    ###  ##     ##  ##   ##  ##   ##  ##  ##   #######  ##     ##  ##   ##  ##    ###           ##  ##     ##  ##    ## ##   ##  ##  ##  ##   ##  ##  ##   
#//   ####   #####   ##     ##  ##     ##   ####     #####   ##   ##  ##   ##   ####  ##   #####   ##     ##        ####   #####  ##   ##    ###    ##  ####     #####   ##   ##  
#//                                                                                                                                                                                 
#//=================================================================================================================================================================================
    #Interfaz que modificaremos/crearemos
    echo "Introduce el nombre de la interfaz: [wg0]"
    read wg_interface_name

    if [ "$wg_interface_name" == "" ]; then
        wg_interface_name="wg0"
        echo $wg_interface_name
    fi

    #IP que tendra el servidor en la VPN
    echo "Introduce la IP que tendra el servidor en la VPN. Por defecto 10.0.0.1/24"
    read serverAddress
    if [ "$serverAddress" == "" ]; then
        serverAddress="10.0.0.1/24"
    fi

    #Generamos las claves publico/privada
    #umask 077
    wg genkey | tee "${DIR_BASE}privatekey" | wg pubkey > "${DIR_BASE}publickey"
    privateKey="$(cat ${DIR_BASE}privatekey)"


    file_name="${DIR_BASE}${wg_interface_name}.conf"
    echo "[Interface]" > $file_name
    echo "PrivateKey = $privateKey" >> $file_name
    echo "Address = $serverAddress" >> $file_name
    echo "ListenPort = 51820 #Puerto por defecto " >> $file_name
    echo "" >> $file_name
    echo "PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; " >> $file_name
    echo "PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE;" >> $file_name
    echo "" >> $file_name

    echo "El archivo ${file_name} se ha creado"

    echo "¿Activar el routing?[y/n]"
    read routing
    if [ "$routing" == "y" ]; then
        # Enable routing on the server
	    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
        sysctl -p
    fi

;;

2)
#//=======================================================================================================================================================================
#//                                                                                                                                                                       
#//   ####   #####   ##     ##  #####  ##   ####    ##   ##  #####      ###     ####  ##   #####   ##     ##         ####  ##      ##  #####  ##     ##  ######  #####  
#//  ##     ##   ##  ####   ##  ##     ##  ##       ##   ##  ##  ##    ## ##   ##     ##  ##   ##  ####   ##        ##     ##      ##  ##     ####   ##    ##    ##     
#//  ##     ##   ##  ##  ## ##  #####  ##  ##  ###  ##   ##  #####    ##   ##  ##     ##  ##   ##  ##  ## ##        ##     ##      ##  #####  ##  ## ##    ##    #####  
#//  ##     ##   ##  ##    ###  ##     ##  ##   ##  ##   ##  ##  ##   #######  ##     ##  ##   ##  ##    ###        ##     ##      ##  ##     ##    ###    ##    ##     
#//   ####   #####   ##     ##  ##     ##   ####     #####   ##   ##  ##   ##   ####  ##   #####   ##     ##         ####  ######  ##  #####  ##     ##    ##    #####  
#//                                                                                                                                                                       
#//=======================================================================================================================================================================
    #Interfaz que modificaremos/crearemos
    echo "Introduce el nombre de la interfaz: [wg-client0]"
    read wg_interface_name

    if [ "$wg_interface_name" == "" ]; then
        wg_interface_name="wg-client0"
        echo $wg_interface_name
    fi


    echo "Introduce la IP que tendra el servidor en la VPN. Por defecto 10.0.0.10/32"
    read clientAddress
    if [ "$clientAddress" == "" ]; then
        clientAddress="10.0.0.10/32"
    fi

    if [ ! -d $CLIENT_PATH ]; then
        mkdir $CLIENT_PATH
    fi

    if [ ! -d "${CLIENT_PATH}${wg_interface_name}" ]; then
        mkdir "${CLIENT_PATH}${wg_interface_name}"
    fi

    #Generamos las claves publico/privada
    #umask 077
    wg genkey | tee "${CLIENT_PATH}${wg_interface_name}/privatekey" | wg pubkey > "${CLIENT_PATH}${wg_interface_name}/publickey" 
    clientPrivateKey="$(cat ${CLIENT_PATH}${wg_interface_name}/privatekey)"
    clientPublicKey="$(cat ${CLIENT_PATH}${wg_interface_name}/publickey)"

    echo "Introduce clave publica del servidor: "
    read serverKey
    echo "Introduce la IP pública y el puerto del servidor [x.x.x.x:xxxxx]: "
    read serverIP

    ## Fichero de configuracion del cliente
    file_name="${CLIENT_PATH}${wg_interface_name}/${wg_interface_name}.conf"
    echo "[Interface]" > $file_name
    echo "PrivateKey = $clientPrivateKey" >> $file_name
    echo "Address = $clientAddress" >> $file_name
    echo "" >> $file_name
    echo "[Peer]" >> $file_name
    echo "PublicKey = $serverKey" >> $file_name
    echo "AllowedIPs = 0.0.0.0/0" >> $file_name
    echo "Endpoint = $serverIP" >> $file_name
    echo "PersistentKeepalive = 25" >> $file_name

    echo "El archivo ${file_name} se ha creado"

    echo "La siguiente opcion solo sirve si estás ejecutando el script en el servidor"
    echo "¿Añadir el cliente a la configuración del servidor?[y/n]"
    read addToServer

    #Añadir cliente al servidor
    if [ "$addToServer" == "y" ]; then
        echo "Introduce la interfaz del servidor: "
        read wg_server_interface

        file_name="${DIR_BASE}${wg_server_interface}.conf"

        if [ ! -f $file_name ]; then
            echo "La interfaz no existe"
            exit 1
        fi

        echo "" >> $file_name
        echo "[Peer]" >> $file_name
        echo "PublicKey = $clientPublicKey" >> $file_name
        echo "AllowedIPs = $clientAddress" >> $file_name

        echo "Peer añadido"
        echo "¿Reiniciar servidor? [y/n]"
        read restart
        if [ restart == "y" ]; then
            wg-quick down $wg_server_interface
            wg-quick up $wg_server_interface
        fi

        echo "Mostrar QR? [y/n]: "
        read showQR

        if [ "$showQR" == "y" ]; then
            qrencode -t ansiutf8 < "${CLIENT_PATH}${wg_interface_name}/${wg_interface_name}.conf"
        fi


    fi


esac


