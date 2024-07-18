provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "main" {
  name                    = "main-vpc"
  auto_create_subnetworks = false
}

# Public Subnet
resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  network       = google_compute_network.main.id
  ip_cidr_range = "10.0.1.0/24"
}

# Private Subnet
resource "google_compute_subnetwork" "private" {
  name          = "private-subnet"
  network       = google_compute_network.main.id
  ip_cidr_range = "10.0.2.0/24"
}

# Internet Gateway (GCP uses default internet gateway)
resource "google_compute_router" "public" {
  name    = "public-router"
  network = google_compute_network.main.id
  region  = var.region
}

# Create a firewall rule to allow HTTP/HTTPS traffic
resource "google_compute_firewall" "http_https_firewall" {
  name    = "allow-http-https"
  network = google_compute_network.main.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Bastion Host
resource "google_compute_instance" "bastion" {
  name         = "web-server"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image_id
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = "sudo apt-get update && sudo apt-get install -y nginx"

  metadata = {
    sshKeys = "ubuntu:${file(var.public_key_path)}"
  }

  tags = ["web-server"]
}
