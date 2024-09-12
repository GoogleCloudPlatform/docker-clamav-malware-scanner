# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  repo_root = abspath("${path.module}/../..")
  src_root  = abspath("${local.repo_root}/cloudrun-malware-scanner")

  ## Read config and extract bucket names
  config_json              = jsondecode(var.config_json)
  cvd_mirror_bucket        = local.config_json.ClamCvdMirrorBucket
  unscanned_bucket_names   = local.config_json.buckets[*].unscanned
  clean_bucket_names       = local.config_json.buckets[*].clean
  quarantined_bucket_names = local.config_json.buckets[*].quarantined
  all_buckets              = toset(concat(local.clean_bucket_names, local.unscanned_bucket_names, local.quarantined_bucket_names))
}

## Enable the APIs
module "apis" {
  source     = "./apis"
  count      = var.enable_apis ? 1 : 0
  depends_on = [data.google_project.project]
}

## Create the service accounts for scanner and builder, and add roles
#
resource "google_service_account" "malware_scanner_sa" {
  account_id   = var.service_name
  display_name = "Service Account for malware scanner cloud run service"
  depends_on   = [module.apis]
}

resource "google_project_iam_member" "malware_scanner_iam" {
  for_each = toset(["roles/monitoring.metricWriter", "roles/run.invoker", "roles/eventarc.eventReceiver"])
  project  = data.google_project.project.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.malware_scanner_sa.email}"
}

resource "google_service_account" "build_service_account" {
  account_id   = "${var.service_name}-build"
  display_name = "Service Account for malware scanner cloud run service"
  depends_on   = [module.apis]
}

resource "google_project_iam_binding" "build_iam" {
  for_each = toset(["roles/storage.objectViewer", "roles/logging.logWriter", "roles/artifactregistry.writer"])
  project  = data.google_project.project.project_id
  role     = each.value
  members  = ["serviceAccount:${google_service_account.build_service_account.email}"]
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.service_name
  description   = "Image registry for Malware Scanner"
  format        = "DOCKER"
  depends_on    = [module.apis]
}

## Allow GCS to publish to pubsub
#
data "google_storage_project_service_account" "gcs_account" {
  depends_on = [module.apis]
}
resource "google_project_iam_binding" "gcs_sa_pubsub_publish" {
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

## Create configured scanner buckets if requested.
#
module "create_buckets" {
  source                      = "./create_buckets"
  count                       = var.create_buckets ? 1 : 0
  bucket_location             = var.bucket_location
  uniform_bucket_level_access = var.uniform_bucket_level_access
  bucket_names                = local.all_buckets
  depends_on                  = [module.apis]
}

## Allow service account to admin the scanner buckets.
#
# They may not have been created by TF, so use a data resource
# to verify their existence.
#
data "google_storage_bucket" "scanner-buckets" {
  for_each   = local.all_buckets
  name       = each.value
  depends_on = [module.create_buckets]
}
resource "google_storage_bucket_iam_binding" "buckets_sa_binding" {
  for_each = local.all_buckets
  bucket   = data.google_storage_bucket.scanner-buckets[each.key].name
  role     = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.malware_scanner_sa.email}",
  ]
}

## Create the CVD Mirror bucket and allow service account admin access.
#
resource "google_storage_bucket" "cvd_mirror_bucket" {
  name                        = local.cvd_mirror_bucket
  location                    = var.bucket_location
  uniform_bucket_level_access = var.uniform_bucket_level_access
  depends_on                  = [module.apis]
}
resource "google_storage_bucket_iam_binding" "cvd_mirror_bucket_sa_binding" {
  bucket = google_storage_bucket.cvd_mirror_bucket.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.malware_scanner_sa.email}",
  ]
}

## Perform an update/initial load of mirror bucket.
#
resource "null_resource" "populate_cvd_mirror" {
  provisioner "local-exec" {
    command = join(" ; ", [
      "echo '\n\nPopulating CVD Mirror bucket ${google_storage_bucket.cvd_mirror_bucket.name}\n\n'",
      "python3 -m venv pyenv",
      ". pyenv/bin/activate",
      "pip3 install crcmod cvdupdate",
      "./updateCvdMirror.sh '${google_storage_bucket.cvd_mirror_bucket.name}'",
      "echo '\n\nPopulating CVD Mirror bucket successful\n\n'",
    ])
    interpreter = ["bash", "-x", "-e", "-c"]
    working_dir = local.src_root
  }
}
