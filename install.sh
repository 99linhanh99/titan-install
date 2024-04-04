#!/bin/bash

# Lấy giá trị hash từ terminal
echo "Nhap ma Hash cua ban (Identity code): "
read hash_value

# Kiểm tra nếu hash_value là chuỗi rỗng (người dùng chỉ nhấn Enter) thì dừng chương trình
if [ -z "$hash_value" ]; then
    echo "Không có giá trị hash được nhập. Dừng chương trình."
    exit 1
fi

storage_size="72"
memory_size="4"
cpu_core="2"

service_content="
[Unit]
Description=Titan Node
After=network.target
StartLimitIntervalSec=0

[Service]
User=root
ExecStart=/usr/local/titan/titan-edge daemon start
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
"

sudo apt-get update
sudo apt-get install -y nano

wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.16/titan_v0.1.16_linux_amd64.tar.gz

sudo tar -xf titan_v0.1.16_linux_amd64.tar.gz -C /usr/local

sudo mv /usr/local/titan_v0.1.16_linux_amd64 /usr/local/titan

rm titan_v0.1.16_linux_amd64.tar.gz

touch ~/.bash_profile


echo 'export PATH=$PATH:/usr/local/titan' >> ~/.bash_profile

source ~/.bash_profile


titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0 &
daemon_pid=$!

echo "PID của titan-edge daemon: $daemon_pid"

sleep 30

titan-edge bind --hash="$hash_value" https://api-test1.container1.titannet.io/api/v2/device/binding &
bind_pid=$!

echo "PID của titan-edge bind: $bind_pid"

wait $bind_pid


config_file="/root/.titanedge/config.toml"
if [ -f "$config_file" ]; then
    sed -i "s/#StorageGB = 2/StorageGB = $storage_size/" "$config_file"
    echo "Đã thay đổi kích thước lưu trữ cơ sở dữ liệu thành $storage_size GB."
    sed -i "s/#MemoryGB = 1/MemoryGB = $memory_size/" "$config_file"
    echo "Đã thay đổi kích thước memory liệu thành $memory_size GB."
    sed -i "s/#Cores = 1/Cores = $cpu_core/" "$config_file"
    echo "Đã thay đổi core cpu liệu thành $cpu_core GB."
else
    echo "Lỗi: Tệp cấu hình $config_file không tồn tại."
fi

echo "$service_content" | sudo tee /etc/systemd/system/titand.service > /dev/null

kill $daemon_pid

sudo systemctl daemon-reload

sudo systemctl enable titand.service

sudo systemctl start titand.service

titan-edge info && titan-edge config show
