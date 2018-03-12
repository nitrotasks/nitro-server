provider "docker" {
  host = "tcp://127.0.0.1:2375"
}

resource "docker_container" "nitro" {
  image = "nitro"
  name = "nitro"
  networks = ["private_network"]
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
  networks = ["private_network"]
  env = [
    "POSTGRES_USER=${var.sql_username}",
    "POSTGRES_PASSWORD=${var.sql_password}"
  ]
}

resource "docker_image" "postgres" {
  name = "postgres:10.3"  
}

resource "docker_network" "private_network" {
  name = "private_network"
}