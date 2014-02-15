  describe '#list', ->

    before ->
      list.userId = user.id

    it 'should create a new list', (done) ->

      db.list.create(list).then (id) ->
        list.id = id
        done()

    it 'should read an existing list', (done) ->

      db.list.read(list.id).then (info) ->
        info.should.eql list
        done()

    it 'should update an existing list', (done) ->

      list.name = 'List 1 - Updated'
      model = name: list.name
      db.list.update(list.id, model).then -> done()

    it 'should read an updated list', (done) ->

      db.list.read(list.id, 'name').then (info) ->
        info.should.eql
          name: list.name
        done()

    it 'should destroy an existing list', (done) ->

      db.list.destroy(list.id).then -> done()

    it 'should create another list', (done) ->

      delete list.id
      db.list.create(list).then (id) ->
        list.id = id
        done()


