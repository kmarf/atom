fs = require 'fs'
{Document} = require 'ace/document'

module.exports =
class Buffer
  lines: null

  constructor: (@path) ->
    @url = @path # we want this to be path on master, but let's not break it on a branch
    if @path and fs.exists(@path)
      @setText(fs.read(@path))
    else
      @setText('')

  getText: ->
    @lines.join('\n')

  setText: (text) ->
    @lines = text.split('\n')

  getLines: ->
    @lines

  getLine: (n) ->
    @lines[n]

  change: (preRange, string) ->
    @remove(preRange)
    postRange = @insert(preRange.start, string)
    @trigger 'change', { preRange, postRange, string }

  remove: (range) ->
    prefix = @lines[range.start.row][0...range.start.column]
    suffix = @lines[range.end.row][range.end.column..]

    @lines[range.start.row..range.end.row] = prefix + suffix

  insert: ({row, column}, string) ->
    postRange =
      start: { row, column }
      end: { row, column }

    prefix = @lines[row][0...column]
    suffix = @lines[row][column..]

    lines = string.split('\n')

    if lines.length == 1
      @lines[row] = prefix + string + suffix
      postRange.end.column += string.length
    else
      for line, i in lines
        curRow = row + i
        if i == 0 # replace first line
          @lines[curRow] = prefix + line
        else if i < lines.length - 1 # insert middle lines
          @lines[curRow...curRow] = line
        else # insert last line
          @lines[curRow...curRow] = line + suffix
          postRange.end.row = curRow
          postRange.end.column = line.length

    postRange

  numLines: ->
    @getLines().length

  save: ->
    if not @path then throw new Error("Tried to save buffer with no url")
    fs.write @path, @getText()

  on: (eventName, handler) ->
    @handlers ?= {}
    @handlers[eventName] ?= []
    @handlers[eventName].push(handler)

  trigger: (eventName, data) ->
    @handlers?[eventName]?.forEach (handler) -> handler(data)

