# Copyright 2024 Google LLC
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

variable "project_id" {
  description = "Google Cloud Project ID to use"
  type        = string
}

variable "bucket_location" {
  description = "Location to create Cloud Storage buckets"
  type        = string
}

variable "region" {
  description = "Region name for creation of resources"
  type        = string
}

variable "service_name" {
  default = "malware-scanner"
  type    = string
}

variable "config_json" {
  description = "String containing JSON encoded configuration to pass to the cloud run service as environment variable CONFIG_JSON"
  type        = string
}

variable "enable_apis" {
  description = "Automatically enable required APIs (requires that cloudresourcemanager.googleapis.com and serviceusage.googleapis.com are already enabled)"
  default     = true
  type        = bool
}

variable "create_buckets" {
  description = "Creates all the unscanned, clean, and quarantined buckets defined in the config. "
  default     = true
  type        = bool
}

variable "uniform_bucket_level_access" {
  description = "When creating cloud storage buckets, the parameter uniform_bucket_level_access is set to this value"
  default     = true
  type        = bool
}
