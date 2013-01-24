# Merge Array Order with Timestamps
Log = require "./log"

ArrayDiff = (a, b) ->
  a.filter (i) ->
    not (b.indexOf(i) > -1)

merge = (client, server) ->
  # client and server are objects with time and order

  # Find diff
  serverDiff = ArrayDiff server.order, client.order
  clientDiff = ArrayDiff client.order, server.order

  # Check if only order has been changed
  sameKeys = not serverDiff.length and not clientDiff.length

  # Only order has been changed
  if sameKeys

    # Use newer timestamp
    if client.time > server.time
      Log "List order: Same keys so going with latest version - Client"
      return [client.order, client.time]

    else
      Log "List order: Same keys so going with latest version - Server"
      return [server.order, server.time]

  # Use algorithm if keys are different
  else

    # Crazy merging code
    Log "List order: Merging with algorithm"

    # Remove all keys that aren't in the server
    client.order = ArrayDiff(client.order, cD)

    for i in [0..serverDiff.length] by 1

      # Get the index of each key in the ServerDiff
      index = server.order.indexOf(serverDiff[i])

      # Inject the key into the client
      client.order.splice index, 0, serverDiff[i]

    return [client.order, client.time]

module.exports = merge

###
# Merge Task Order (Uses same algorithm)
for list of client.lists.items
  if not server.lists.items[list].hasOwnProperty("deleted") and not client.lists.items[list].hasOwnProperty("deleted")
    mlo.client =
      order: client.lists.items[list].order
      time: client.lists.items[list].time.order

    mlo.server =
      order: server.lists.items[list].order
      time: server.lists.items[list].time.order

    mlo.result = mlo.run(mlo.client, mlo.server)
    server.lists.items[list].order = mlo.result[0]
    server.lists.items[list].time.order = mlo.result[1]
