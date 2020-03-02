provider "google" {
    version = "3.5.0"
    project = "${var.project}"
}

# FRONTEND

resource "google_storage_bucket" "frontend" {
    name     = "cah.maxrs.de"
    location = "europe-west3"
    labels   = {
        environment = "production"
    }

    website {
        main_page_suffix = "index.html"
    }
}

resource "google_storage_bucket_access_control" "frontend-public_rule" {
    bucket = "${google_storage_bucket.frontend.name}"
    role   = "READER"
    entity = "allUsers"
}

# BACKEND

resource "google_cloud_run_service" "backend" {
    name     = "cah-backend"
    location = "europe-north1"

    template {
        spec {
            containers {
                image = "gcr.io/cloudrun/hello"
            }
        }
    }

    traffic {
        percent         = 100
        latest_revision = true
    }
}

data "google_iam_policy" "backend-noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "backend-noauth" {
  location = "${google_cloud_run_service.backend.location}"
  project  = "${google_cloud_run_service.backend.project}"
  service  = "${google_cloud_run_service.backend.name}"

  policy_data = "${data.google_iam_policy.backend-noauth.policy_data}"
}

resource "google_cloud_run_domain_mapping" "backend-domain" {
  location = "${google_cloud_run_service.backend.location}"
  name     = "api.cah.maxrs.de"

  metadata {
    namespace = "${var.project}"
  }

  spec {
    route_name = "${google_cloud_run_service.backend.name}"
  }
}