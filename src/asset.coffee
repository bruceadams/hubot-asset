# Description:
#   Keep a lending library of assets.
#
# Commands:
#   hubot asset create <name> - Create a new asset in the library
#   hubot asset borrow <name> - Borrow an asset
#   hubot asset return <name> - Return a borrowed asset
#   hubot asset destroy <name> - Remove an asset from the library
#   hubot asset status - List the holder or availability of each asset
#
# Author:
#   Bruce Adams <bruce.adams@acm.org>
#
# License:
#   MIT

new_holder = (name) ->
  name: name

new_retval = () ->
  holder: null
  remove: false
  tell: []

create = (requester, asset, holder) ->
  retval = new_retval()
  if ! asset
    retval.tell.push "Please try again with the name of the asset you want to create."
  else if holder
    retval.tell.push "No can do: #{asset} already exists."
  else
    retval.holder = new_holder(null)
    retval.tell.push "#{asset} is now available for use."

  retval

borrow = (requester, asset, holder) ->
  retval = new_retval()
  if ! asset
    retval.tell.push "Please try again with the name of the asset you want."
  else if ! holder
    retval.tell.push "No can do: I do not know of \"#{asset}\"."
  else if holder.name and holder.name != requester
    retval.tell.push "No can do: #{asset} is already held by #{holder.name}."
  else if holder.name == requester
    retval.tell.push "#{requester} continues to hold #{asset}."
  else
    retval.holder = new_holder(requester)
    retval.tell.push "#{requester} is now the proud holder of #{asset}."

  retval

release = (requester, asset, holder) ->
  retval = new_retval()
  if ! asset
    retval.tell.push "Please try again with the name of the asset to return."
  else if ! holder
    retval.tell.push "No can do: I do not know of \"#{asset}\"."
  else if ! holder.name
    retval.tell.push "No can do: #{asset} is not held by anyone."
  else if holder.name != requester
    retval.tell.push "No can do: #{requester} is not holding #{asset}."
    retval.tell.push "#{asset} is being held by #{holder.name}."
  else
    retval.holder = new_holder(null)
    retval.tell.push "#{requester} has returned #{asset} for others to use."

  retval

destroy = (requester, asset, holder) ->
  retval = new_retval()
  if ! asset
    retval.tell.push "Please try again with the name of the asset to destroy."
  else if ! holder
    retval.tell.push "No can do: I do not know of \"#{asset}\"."
  else if holder.name
    retval.tell.push "No can do: #{asset} is in use by #{holder.name}."
  else
    retval.remove = true
    retval.tell.push "Now you've gone and done it: #{asset} is no more."

  retval

# This is uglier than I'd prefer.
status = (assets) ->
  retval = new_retval()
  free = []
  pivot = {}
  for asset, holder of assets
    if ! holder.name
      free.push asset
    else if pivot[holder.name]
      pivot[holder.name].push(asset)
    else
      pivot[holder.name] = [asset]

  if free.length == 0
    retval.tell.push "no assets are available."
  else
    ff = free.join(", ")
    retval.tell.push "available assets are: #{ff}"

  for holder, list of pivot
    ll = list.join(", ")
    retval.tell.push "#{holder} holds: #{ll}"

  retval

funcs =
  create:   create

  borrow:   borrow
  checkout: borrow
  co:       borrow
  grab:     borrow

  checkin:  release
  ci:       release
  release:  release
  return:   release

  destroy:  destroy

module.exports = (robot) ->
  robot.respond /asset\s+(\w+)\s*([^\s]*)/i, (msg) ->
    verb = msg.match[1]
    item = msg.match[2]

    assets = robot.brain.get("assets") || {}

    if funcs[verb]
      result = funcs[verb](msg.message.user.name, item, assets[item])
    else if verb == "list" or verb == "status"
      result = status(assets)
    else
      result = tell: ["Sorry, I don't know what #{verb} means."]

    # Do we have a change we need to save?
    if result.remove or result.holder
      # Make the change to "assets"
      if result.remove
        delete assets[item]
      else if result.holder
        assets[item] = result.holder
      # Save "assets" back into the brain
      robot.brain.set("assets", assets)
      robot.brain.save

    # Tell our user what we did or did not do.
    msg.send(line) for line in result.tell

    return
