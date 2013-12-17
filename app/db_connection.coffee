nodeRedis = require 'redis'

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------

# Connect to MySQL database
dbase.connect()

# Connect to Redis
redis = nodeRedis.createClient()


