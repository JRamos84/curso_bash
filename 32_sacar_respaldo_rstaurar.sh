#!/bin/bash
# Programa que permite manejar utilidades de Postgres
# Autor: José Ramos - joseph0001@gmail.com

opcion=0
fechaActual=$(date +%y%m%d)

instalar_postgres () {
    echo -e "\nVerificar instalación de Postgres..."
    verifyInstall=$(which psql)

    if [ $? -eq 0 ]; then
        echo -e "\nPostgres ya se encuentra instalado en el equipo"
    else
        read -s -p "Ingresar contraseña: " password
        echo
        read -s -p "Utilizar contraseña a utilizar en Postgres: " passwordPostgres
        echo

        echo "$password" | sudo -S apt update
        echo "$password" | sudo -S apt-get -y install postgresql postgresql-contrib
        sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$passwordPostgres'"
        echo "$password" | sudo -S systemctl enable postgresql.service
        echo "$password" | sudo -S systemctl start postgresql.service
    fi

    read -n 1 -s -r -p "Presione [ENTER] para continuar..."
}

# Función para desinstalar Postgres
desinstalar_postgres () {
    read -s -p "Ingresar contraseña: " password
    echo

    echo "$password" | sudo -S systemctl stop postgresql.service
    echo "$password" | sudo -S apt-get -y --purge remove postgresql\*
    echo "$password" | sudo -S rm -r /etc/postgresql
    echo "$password" | sudo -S rm -r /etc/postgresql-common
    echo "$password" | sudo -S rm -r /var/lib/postgresql
    echo "$password" | sudo -S userdel -r postgres
    echo "$password" | sudo -S groupdel postgres

    read -n 1 -s -r -p "Presione [ENTER] para continuar..."
}

# Función para sacar un respaldo
sacar_respaldo () {
    echo "Listar las bases de datos"
    echo "$password" | sudo -S -u postgres psql -c "\l"
    read -p "Elegir la base de datos a respaldar: " bddRespaldo
    echo -e "\n"
    if [ -d "$1" ]; then
        echo "Establecer permisos directorio"
        echo "$password" | sudo -S chmod 755 $1
        echo "Realizando respaldo..."
        sudo -u postgres pg_dump -Fc $bddRespaldo > "$1/bddRespaldo$fechaActual.bak"
        echo "Respaldo realizado correctamente en la ubicación: $1/bddRespaldo$fechaActual.bak"
    else
        echo "El directorio $1 no existe"
    fi

    read -n 1 -s -r -p "Presione [ENTER] para continuar..."
}

# Función para restaurar un respaldo
restaurar_respaldo () {
    echo "Listar respaldos"
    read -p "Ingresar el directorio donde están los respaldos: " directorBackup
    ls -la $directorioBackup
    read -p "Elegir el respaldo a restaurar: " respaldoRestaurar
    echo -e "\n"
    read -p "Ingrese el nombre de la base destino: " bddDestino
    # Verificar si la base de datos existe
    verifyBdd=$(sudo -u postgres psql -lqt | cut -d '|' -f1 | grep -wq "$bddDestino")
    if [ $? -eq 0 ]; then
        echo "Restaurando en la base de datos destino: $bddDestino"
    else
        sudo -u postgres psql -c "CREATE DATABASE $bddDestino"
    fi
    if [ -f "$respaldoRestaurar" ]; then
        echo "Restaurando respaldo..."
        sudo -u postgres pg_restore -Fc -d "$bddDestino" "$directorioBackup/$respaldoRestaurar"
        echo "Listar la base de datos"
        sudo -u postgres psql -c "\l"
    else
        echo "El respaldo $respaldoRestaurar no existe"
    fi 

    read -n 1 -s -r -p "Presione [ENTER] para continuar..."
}

# Bucle principal del menú
while true; do
    # Limpiar la pantalla
    clear

    # Desplegar el menú de opciones
    echo "------------------------------------------"
    echo "PGUTIL - Programa de Utilidad de Postgres"
    echo "------------------------------------------"
    echo "                Menú Principal            "
    echo "------------------------------------------"
    echo "1. Instalar Postgres"
    echo "2. Desinstalar Postgres"
    echo "3. Sacar un respaldo"
    echo "4. Restaurar respaldo"
    echo "5. Salir"
    echo "------------------------------------------"

    # Leer los datos del usuario
    read -n 1 -p "Ingrese una opción [1-5]: " opcion
    echo -e "\n"

    # Validar la opción ingresada
    case $opcion in
        1)
            instalar_postgres
            sleep 3
            ;;
        2)
            desinstalar_postgres
            sleep 3
            ;;
        3)
            read -p "Ingrese el directorio de backup: " directorioBackup
            sacar_respaldo "$directorioBackup"
            sleep 3
            ;;
        4)
            read -p "Ingrese el directorio de respaldo: " directorioRespaldos
            restaurar_respaldo "$directorioRespaldos"
            sleep 3
            ;;
        5)
            echo -e "\nSaliendo del programa..."
            exit 0
            ;;
        *)
            echo -e "\nOpción no válida. Intente nuevamente."
            sleep 2
            ;;
    esac
done

