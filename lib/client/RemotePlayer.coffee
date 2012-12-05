Player = require('./Player')

class RemotePlayer extends Player
  constructor: (@world, slot, team, callsign, tag, args) ->
    super @world, slot, team, callsign, tag, args

    @world.socket.on 'update player', @handleUpdatePlayer
    @world.socket.on 'remove player', @handleRemovePlayer

  handleUpdatePlayer: (updatePlayerData) =>
    return unless updatePlayerData.slot is @model.slot

    for key, val of updatePlayerData
      @model[key] = val if @model[key]?

  handleRemovePlayer: (removePlayerData) =>
    return unless removePlayerData.slot is @model.slot

    @world.socket.removeListener 'update player', @handleUpdatePlayer
    @world.socket.removeListener 'remove player', @handleRemovePlayer

module.exports = RemotePlayer
