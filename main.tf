/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

terraform {
  required_version = "~> 0.11.0"
}

locals {
  keys_by_name = "${zipmap(var.keys, google_kms_crypto_key.key.*.self_link)}"
}

resource "google_kms_key_ring" "key_ring" {
  name     = "${var.keyring}"
  project  = "${var.project_id}"
  location = "${var.location}"
}

resource "google_kms_crypto_key" "key" {
  count           = "${length(var.keys)}"
  name            = "${element(var.keys, count.index)}"
  key_ring        = "${google_kms_key_ring.key_ring.self_link}"
  rotation_period = "${var.key_rotation_period}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "owners" {
  count = "${length(var.set_owners_for)}"
  role  = "roles/owner"

  crypto_key_id = "${lookup(
    local.keys_by_name,
    element(var.set_owners_for, count.index)
  )}"

  members = [
    "${compact(split(",", element(var.owners, count.index)))}",
  ]
}

resource "google_kms_crypto_key_iam_binding" "decrypters" {
  count = "${length(var.set_decrypters_for)}"
  role  = "roles/cloudkms.cryptoKeyDecrypter"

  crypto_key_id = "${lookup(
    local.keys_by_name,
    element(var.set_decrypters_for, count.index)
  )}"

  members = [
    "${compact(split(",", element(var.decrypters, count.index)))}",
  ]
}

resource "google_kms_crypto_key_iam_binding" "encrypters" {
  count = "${length(var.set_encrypters_for)}"
  role  = "roles/cloudkms.cryptoKeyEncrypter"

  crypto_key_id = "${lookup(
    local.keys_by_name,
    element(var.set_encrypters_for, count.index)
  )}"

  members = [
    "${compact(split(",", element(var.encrypters, count.index)))}",
  ]
}
