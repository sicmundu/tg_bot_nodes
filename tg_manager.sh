#!/bin/bash

# Цветовая палитра
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщения с рамкой
function box_msg() {
    local msg="$1"
    local len=${#msg}
    printf "\n%0.s*" $(seq 1 $((len+8)))
    echo -e "\n*  ${YELLOW}$msg${NC}  *"
    printf "%0.s*" $(seq 1 $((len+8)))
    echo -e "\n"
}

# Функция анимации
function animate() {
    echo -n "$1 "
    for i in $(seq 1 3); do
        echo -n "."
        sleep 0.5
    done
    echo -e "\n"
}



#!/bin/bash

# Цветовая палитра
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщения с рамкой
function box_msg() {
    local msg="$1"
    local len=${#msg}
    printf "\n%0.s*" $(seq 1 $((len+8)))
    echo -e "\n*  ${YELLOW}$msg${NC}  *"
    printf "%0.s*" $(seq 1 $((len+8)))
    echo -e "\n"
}

# Функция анимации
function animate() {
    echo -n "$1 "
    for i in $(seq 1 3); do
        echo -n "."
        sleep 0.5
    done
    echo -e "\n"
}

# Функция установки
function install() {
    # Проверка и установка Node.js и NPM
if ! command -v node > /dev/null; then
    box_msg "Установка Node.js и NPM"
    animate "Установка"
    curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
    sudo apt-get install -y nodejs
    echo -e "${GREEN}Node.js и NPM успешно установлены.${NC}\n"
fi

# Проверка и установка Docker
if ! command -v docker > /dev/null; then
    box_msg "Установка Docker"
    animate "Установка"
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    echo -e "${GREEN}Docker успешно установлен.${NC}\n"
fi

# Создание каталога проекта
box_msg "Создание каталога проекта"
animate "Создание"
mkdir -p ~/.tg_bot_manager
cd ~/.tg_bot_manager
echo -e "${GREEN}Каталог создан.${NC}\n"

# Скачивание файла server.js с Github
box_msg "Загрузка server.js"
animate "Загрузка"
curl -LJO https://github.com/sicmundu/tg_bot_nodes/raw/main/server.js
echo -e "${GREEN}server.js успешно загружен.${NC}\n"

# Запрос токена у пользователя и сохранение его в файл .env
box_msg "Ввод токена"
echo "Пожалуйста, введите ваш токен:"
read -r TOKEN
echo "TOKEN=$TOKEN" > .env
echo -e "${GREEN}Токен сохранен.${NC}\n"

# Установка зависимостей
box_msg "Установка зависимостей"
animate "Установка"
npm init -y
npm install express dotenv
echo -e "${GREEN}Зависимости успешно установлены.${NC}\n"

# Создание и запуск службы
box_msg "Создание и запуск службы"
animate "Создание"
cat <<EOL | sudo tee /etc/systemd/system/tg_bot_manager.service > /dev/null
[Unit]
Description=TG Bot Manager Service
After=network.target

[Service]
ExecStart=$(which node) $(realpath server.js)
WorkingDirectory=$(realpath .)
User=$(whoami)
Restart=always

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable tg_bot_manager
sudo systemctl start tg_bot_manager
echo -e "${GREEN}Сервер успешно установлен и запущен.${NC}\n"
}

# Функция удаления
function uninstall() {
    # Остановка и удаление службы
    box_msg "Остановка и удаление службы"
    animate "Остановка"
    sudo systemctl stop tg_bot_manager
    sudo systemctl disable tg_bot_manager
    sudo rm /etc/systemd/system/tg_bot_manager.service
    sudo systemctl daemon-reload
    sudo systemctl reset-failed
    echo -e "${GREEN}Служба остановлена и удалена.${NC}\n"

    sleep 1

    # Удаление каталога проекта
    box_msg "Удаление каталога проекта"
    animate "Удаление"
    sudo rm -rf $HOME/.tg_bot_manager
    echo -e "${GREEN}Каталог проекта удален.${NC}\n"

    sleep 1
}

# Функция обновления токена
function update_token() {
    box_msg "Обновление токена"
    echo "Пожалуйста, введите ваш новый токен:"
    read -r new_token
    echo "TOKEN=$new_token" > $HOME/.tg_bot_manager/.env
    sudo systemctl restart tg_bot_manager
    echo -e "${GREEN}Токен успешно обновлен.${NC}\n"
}



if [ "$1" == "install" ]; then
    install
elif [ "$1" == "uninstall" ]; then
    uninstall
elif [ "$1" == "token" ]; then
    update_token $2
else
    echo -e "${RED}Ошибка: Неверный аргумент. Используйте 'install', 'uninstall' или 'token'.${NC}"
    exit 1
fi
