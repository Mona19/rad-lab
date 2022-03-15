/**
 * Copyright 2021 Google LLC
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

data "google_compute_zones" "zones" {
  project = module.project.project_id
  region  = var.region

  depends_on = [module.project]
}

module "gke_cluster" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                    = "~> 19.0"
  project_id                 = module.project.project_id
  name                       = var.gke_cluster_name
  region                     = var.region
  network                    = module.elastic_search_network.name
  subnetwork                 = module.elastic_search_network.subnets["${var.region}/${var.subnet_name}"].name
  remove_default_node_pool   = true
  initial_node_count         = 1
  ip_range_pods              = var.pod_ip_range_name
  ip_range_services          = var.service_ip_range_name
  regional                   = true
  release_channel            = var.release_channel
  kubernetes_version         = var.gke_version
  issue_client_certificate   = false
  identity_namespace         = "${module.project.project_id}.svc.id.goog"
  create_service_account     = true
  enable_private_nodes       = true
  enable_private_endpoint    = false
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  horizontal_pod_autoscaling = true

  node_pools = [
    {
      name           = var.node_pool_name
      machine_type   = var.node_pool_machine_type
      node_locations = join(",", data.google_compute_zones.zones.names)
      min_count      = var.node_pool_min_count
      max_count      = var.node_pool_max_count
      image_type     = "COS"
      preemptible    = var.preemptible_nodes
      disk_size_gb   = var.disk_size_gb_nodes
      disk_type      = var.disk_type_nodes

    }
  ]

  node_pools_metadata = {
    all = {}

    "${var.node_pool_name}" = {
      workload-metadata = "GKE_METADATA"
    }
  }

  node_pools_oauth_scopes = {
    all = []

    "${var.node_pool_name}" = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  depends_on = [
    time_sleep.wait_120_seconds
  ]

}