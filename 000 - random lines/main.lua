
-- random lines

function lovr.draw()
  lovr.graphics.setBackgroundColor(.1, .1, .1)


  local points = {}

  for i = 1,100 
  do
    table.insert(points, 0.5 -lovr.math.random( 1, 100 )/100)
    table.insert(points, 0.5 + lovr.math.random( 1, 100 )/100)
    table.insert(points, -2 -lovr.math.random( 1, 100 )/100)
  end

  lovr.graphics.setColor(1, 1, 1)
  lovr.graphics.line(points)

end