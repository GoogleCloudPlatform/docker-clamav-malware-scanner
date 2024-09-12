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

variable "bucket_location" {
  description = "Location to create Cloud Storage buckets"
  type        = string
}

variable "uniform_bucket_level_access" {
  description = "When creating cloud storage buckets, the parameter uniform_bucket_level_access is set to this value"
  default     = true
  type        = bool
}

variable "bucket_names" {
  description = "The set of bucket names to create"
  type        = set(string)
}
