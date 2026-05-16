# 1. Khai báo kết nối tới Docker Desktop trên Windows
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# 2. Tạo mạng ảo nội bộ doanh nghiệp (Giả lập mạng Core Switch / VLAN 10)
resource "docker_network" "vlan_10" {
  name   = "Enterprise_VLAN_10"
  driver = "bridge"
  ipam_config {
    subnet  = "10.10.10.0/24"
    gateway = "10.10.10.254" # IP của Firewall lõi
  }
}

# 3. Khởi tạo Thiết bị Firewall / Router lõi (Dùng FRRouting)
resource "docker_container" "core_firewall" {
  name  = "Core_Firewall_Fortinet_Gen"
  image = "frrouting/frr:latest"
  restart = "always"

  networks_advanced {
    name         = docker_network.vlan_10.name
    ipv4_address = "10.10.10.1"
  }

  # Mở các cổng quản trị SSH và Web để sau này Ansible nhảy vào cấu hình
  ports {
    internal = 22
    external = 2222
  }
}

# 4. Khởi tạo Ubiquiti Unifi Controller (Quản lý Access Point)
resource "docker_container" "unifi_controller" {
  name  = "Ubiquiti_Unifi_Controller"
  image = "jacobalberty/unifi:latest" # Image Unifi Controller chuẩn cộng đồng
  restart = "always"

  networks_advanced {
    name         = docker_network.vlan_10.name
    ipv4_address = "10.10.10.5" # Cấp IP cố định cho Controller
  }

  # Mở cổng 8443 để bạn vào giao diện Web UI của Unifi trên Windows
  ports {
    internal = 8443
    external = 8443
  }
}
