// Configure the Google Cloud provider
provider "google" {
  credentials = file("credentials.json")
  project     = "terraform-test-278412"
  region      = "us-west1"
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
  byte_length = 8
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
  name         = "flask-vm-${random_id.instance_id.hex}"
  machine_type = "f1-micro"
  zone         = "us-west1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  // Make sure flask is installed on all new instances for later steps
  metadata_startup_script = "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash; export NVM_DIR=$HOME/.nvm; source $NVM_DIR/nvm.sh;nvm install 10; git clone https://github.com/Fender123/nodejs-hello.git; cd nodejs-hello; npm install -g forever; forever start index.js;"

  metadata = {
    ssh-keys = "mm:${file("~/.ssh/id_rsa.pub")}"
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}

resource "google_compute_firewall" "default" {
  name    = "flask-app-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }
}

// A variable for extracting the external ip of the instance
output "ip" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}
