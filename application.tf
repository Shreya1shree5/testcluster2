provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1" # Align with returned version
    command     = "gke-gcloud-auth-plugin"
    env         = {
      USE_GKE_GCLOUD_AUTH_PLUGIN = "true"
    }
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx-deployment"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.17.10"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-service"
  }

  spec {
    selector = {
      app = "nginx"
    }

    type = "LoadBalancer"

    port {
      port        = 80
      target_port = 80
    }
  }
}

gcloud components install gke-gcloud-auth-plugin
export USE_GKE_GCLOUD_AUTH_PLUGIN=True


kubectl run load-generator --image=busybox --restart=Never -- \
    sh -c "while true; do wget -q -O- http://34.170.108.157:80; done"

gcloud container clusters describe my-gke-cluster --region us-central1 --format="value(currentNodeCount)"

kubectl get pods -o wide

gcloud logging read "resource.type=k8s_node AND textPayload:scaling" --limit 10 --format json

kubectl delete pod load-generator

Cluster is scaling up: adding 2 nodes.
Cluster is scaling down: removing 1 node.


