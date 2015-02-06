chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'asset', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()

    require('../src/asset')(@robot)

  # Not exactly an interesting test...
  it 'registers a respond listener', ->
    expect(@robot.respond).to.have.been.calledWith(/asset\s+(\w+)\s*([^\s]*)/i)
