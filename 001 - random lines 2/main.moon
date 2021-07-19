smallRandom = ->
  lovr.math.random(1,100)/100

lovr.draw = ->
  lovr.graphics.setBackgroundColor .1, .1, .1

  points = {}

  for i = 1,100 
    table.insert points, 0.5 - smallRandom()
    table.insert points, 0.5 + smallRandom()
    table.insert points, -2 - smallRandom()

  lovr.graphics.setColor 1, 1, 1
  lovr.graphics.line points
