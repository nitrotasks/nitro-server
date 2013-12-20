# ---------------
# Private Methods
# ---------------



# To be replaced with an SQL database
File =

  # Write user object to file
  write: (user) ->
    deferred = Q.defer()
    obj =
      id: parseInt(user.id, 10)
      name: user.name
      email: user.email
      password: user.password
      pro: user.pro
      data_Task: user.data_Task or {}
      data_List: user.data_List or {}
      data_Time: user.data_Time or {}
      index_Task: user.index_Task or 0
      index_List: user.index_List or 0
      created_at: parseInt(user.created_at, 10)
      updated_at: Date.now()
    [path, folder] = User.filename(obj.id)
    # Compress object
    data = msgpack.pack shrink.compress(obj)
    # Make sure folder exists
    if obj.id % 100 is 0
      fs.mkdir folder, ->
        # Save file
        fs.writeFile(path, data, deferred.resolve)
    else
      # Save file
      fs.writeFile(path, data, deferred.resolve)
    return deferred.promise

  # Read user file
  read: (id) ->
    deferred = Q.defer()
    [path, folder] = User.filename(id)
    fs.readFile path, (err, buffer) =>
      if err then return deferred.reject("err_no_file")
      data = shrink.expand msgpack.unpack(buffer)
      deferred.resolve(data)
    return deferred.promise

  # Delete user file
  del: (id) ->
    deferred = Q.defer()
    path = User.filename(id)[0]
    fs.unlink path, deferred.resolve
    return deferred.promise


