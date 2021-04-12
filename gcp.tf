
resource "google_compute_instance_template" "gcptemplate" {
  name = "gcp-template"
  machine_type = "n1-standard-1"
  tags = ["apache"]
  metadata_startup_script = "sudo apt-get install -y apache2 && sudo service apache2 start && echo '<!doctype html><html><body><h1>CONGRATULATIONS!!..You are on your way to become a Terraform expert!</h1></body></html>' | sudo tee /var/www/html/index.html"

  disk {
    source_image = "debian-cloud/debian-9"
  }

  network_interface {
    network = google_compute_network.webnetwork.name
    subnetwork = google_compute_subnetwork.websubnet.name
    access_config {

    }
  }
}


resource "google_compute_firewall" "gcpfw" {
  name = "gcp-fw"
  network = google_compute_network.webnetwork.name
  source_ranges = ["0.0.0.0/0"]
  target_tags = google_compute_instance_template.gcptemplate.tags

  allow {
    protocol = "tcp"
    ports = ["80","22"]
  }
}

resource "google_compute_instance_group_manager" "mig1" {
  name= "tf-mig"
  base_instance_name = "tf-gcpinstance"
  target_pools = [google_compute_target_pool.lbpool.id]
  target_size = "2"

  version {
    instance_template = google_compute_instance_template.gcptemplate.id
  }
}

resource "google_compute_autoscaler" "gcpscale" {
  name = "gcp-autoscale"
  target = google_compute_instance_group_manager.mig1.id

  autoscaling_policy {
    max_replicas = 4
    min_replicas = 2
  }
}

resource "google_compute_forwarding_rule" "gcplbfont" {
  name = "gcp-lbfront"
  port_range = "80"
  ip_protocol = "TCP"
  target = google_compute_target_pool.lbpool.id
}

resource "google_compute_target_pool" "lbpool" {
  name= "lb-pool"
}

resource "google_compute_network" "webnetwork" {
  name = "gcp-webnetwork"
  auto_create_subnetworks = false
  routing_mode = "REGIONAL"
}

resource "google_compute_subnetwork" "websubnet" {
  name = "webapp"
  ip_cidr_range = "10.120.10.0/24"
  network = google_compute_network.webnetwork.id
  region = "us-east4"

}

resource "google_compute_router" "internet" {
  name = "internetaccess"
  network = google_compute_network.webnetwork.name
  region = "us-east4"
  depends_on = [google_compute_subnetwork.websubnet]
}
