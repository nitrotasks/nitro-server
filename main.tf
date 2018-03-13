provider "docker" {
  host = "tcp://127.0.0.1:2375"
}

resource "docker_container" "nitro-server" {
  image = "${docker_image.nitro-server.latest}"
  name = "nitro-server"
  networks = ["nitro_private_network"]
  depends_on = ["docker_container.postgres"]
  env = [
    "NODE_ENV=production",
    "DATABASE_HOST=psql-server",
    "DATABASE_PORT=5432",
    "DATABASE_URL=postgres://${var.sql_username}:${var.sql_password}@psql-server/${var.sql_database}"
  ]
  ports {
    internal = 8040
    external = 8040
  }
}

resource "docker_container" "postgres" {
  image = "${docker_image.postgres.latest}"
  name = "psql-server"
  networks = ["nitro_private_network"]
  env = [
    "POSTGRES_USER=${var.sql_username}",
    "POSTGRES_PASSWORD=${var.sql_password}"
  ]
  volumes {
    volume_name = "nitro_database"
    container_path = "/var/lib/postgresql/data"
  }
}

resource "docker_image" "postgres" {
  name = "postgres:10.3"  
}
data "docker_registry_image" "nitro-server" {
  name = "dymajo/nitro-server:latest"
}
resource "docker_image" "nitro-server" {
  name          = "${data.docker_registry_image.nitro-server.name}"
  pull_triggers = ["${data.docker_registry_image.nitro-server.sha256_digest}"]
}
resource "docker_network" "nitro_private_network" {
  name = "nitro_private_network"
}

resource "docker_volume" "nitro_database" {
  name = "nitro_database"
}