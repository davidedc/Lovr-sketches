-- modified from the example:
-- https://lovr.org/docs/Locomotion/Basic_Thumbsticks

-- Left thumbstick: move and strafe
-- Right thumbstick: rotate the view horizontally

-- Right grip: switch to snap locomotion mode
-- Left grip: enable flying mode
-- Left trigger: switch orientation to left hand controller (can look around while moving)

motion = {
  pose: lovr.math.newMat4(), -- Transformation in VR initialized to origin (0,0,0) looking down -Z
  thumbstickDeadzone: 0.4,   -- Smaller thumbstick displacements are ignored (too much noise)
  directionFrom: 'left',     -- Movement can be relative to orientation of head or left controller
  flying: false,
  -- Snap motion parameters
  snapTurnAngle: 1 * math.pi / 12,
  dashDistance: 1.5,
  thumbstickCooldownTime: 0.3,
  thumbstickCooldown: 0,
  -- Smooth motion parameters
  turningSpeed: 2 * math.pi * 1 / 6,
  walkingSpeed: 4,
}

handsBackForthDistance = 0
previousRightPos = lovr.math.newVec3 0,0,0
previousLeftPos = lovr.math.newVec3 0,0,0

motion.smooth = (dt) ->
  if lovr.headset.isTracked 'right'
    x, y = lovr.headset.getAxis 'right', 'thumbstick'
    -- Smooth horizontal turning
    if math.abs(x) > motion.thumbstickDeadzone
      motion.pose\rotate -x * motion.turningSpeed * dt, 0, 1, 0

  if lovr.headset.isTracked('left')
    x, y = lovr.headset.getAxis 'left', 'thumbstick'
    direction = quat(lovr.headset.getOrientation(motion.directionFrom))\direction()
    if not motion.flying
      direction.y = 0
    -- Smooth strafe movement
    if math.abs(x) > motion.thumbstickDeadzone
      strafeVector = quat(-math.pi / 2, 0,1,0)\mul vec3 direction
      motion.pose\translate strafeVector * x * motion.walkingSpeed * dt

    -- Smooth Forward/backward movement
    if math.abs(y) > motion.thumbstickDeadzone
      motion.pose\translate direction * y * motion.walkingSpeed * dt

motion.snap = (dt) ->
  -- Snap horizontal turning
  if lovr.headset.isTracked 'right'
    x, y = lovr.headset.getAxis 'right', 'thumbstick'
    if math.abs(x) > motion.thumbstickDeadzone and motion.thumbstickCooldown < 0
      angle = -x / math.abs(x) * motion.snapTurnAngle
      motion.pose\rotate angle, 0, 1, 0
      motion.thumbstickCooldown = motion.thumbstickCooldownTime


  -- Dashing forward/backward
  if lovr.headset.isTracked('left')
    x, y = lovr.headset.getAxis 'left', 'thumbstick'
    if math.abs(y) > motion.thumbstickDeadzone and motion.thumbstickCooldown < 0
      moveVector = quat(lovr.headset.getOrientation('head'))\direction()
      if not motion.flying
        moveVector.y = 0
      moveVector\mul y / math.abs(y) * motion.dashDistance
      motion.pose\translate moveVector
      motion.thumbstickCooldown = motion.thumbstickCooldownTime
  motion.thumbstickCooldown = motion.thumbstickCooldown - dt


sign = (number) ->
    number > 0 and 1 or (number == 0 and 0 or -1)

lovr.update = (dt) ->
  if lovr.headset.isDown 'left', 'grip'
    motion.flying = true
  elseif lovr.headset.wasReleased 'left', 'grip'
    motion.flying = false
    height = vec3(motion.pose).y
    motion.pose\translate 0, -height, 0
  if lovr.headset.isDown 'right', 'grip'
    motion.snap dt
  else
    motion.smooth dt

  -----------

  rightHandPosition = vec3 lovr.headset.getPosition 'right'
  leftHandPosition = vec3 lovr.headset.getPosition 'left'

  if (lovr.headset.wasReleased 'left', 'grip') or (lovr.headset.wasReleased 'right', 'grip')
    handsBackForthDistance = 0

  if (lovr.headset.isDown 'left', 'grip') and (lovr.headset.isDown 'right', 'grip')
    handsBackForthDistance += rightHandPosition.z - previousRightPos.z
    handsBackForthDistance -= leftHandPosition.z - previousLeftPos.z

  if math.abs(handsBackForthDistance) > 0.025
    motion.pose\rotate sign(handsBackForthDistance)*motion.snapTurnAngle, 0, 1, 0
    lovr.headset.vibrate 'left', 0.1, 0.025, 0
    lovr.headset.vibrate 'right', 0.1, 0.025, 0
    handsBackForthDistance = 0

  previousRightPos = lovr.math.newVec3 lovr.headset.getPosition 'right'
  previousLeftPos = lovr.math.newVec3 lovr.headset.getPosition 'left'



-- sunflower, Vogel's model
-- https://en.wikipedia.org/wiki/Fermat%27s_spiral
drawSunflowerFloor = ->
  lovr.math.setRandomSeed(0)
  goldenRatio = (math.sqrt(5) + 1) / 2
  goldenAngle = (2 - goldenRatio) * (2 * math.pi)
  c = 1.8
  for n = 1, 500
    -- polar
    r = math.sqrt(n) * c
    theta = goldenAngle * n
    
    -- from polar to carthesian
    x = r * math.cos theta
    y = r * math.sin theta

    if lovr.math.random() < 0.05
      lovr.graphics.setColor 0.5, 0, 0
    else
      shade = 0.1 + 0.3 * lovr.math.random()
      lovr.graphics.setColor shade, shade, shade
    lovr.graphics.cylinder x, 0, y,  0.05, math.pi / 2, 1,0,0, 1, 1

drawHands = ->
  lovr.graphics.setColor 1,1,1
  radius = 0.05
  for _, hand in ipairs lovr.headset.getHands()
    -- Whenever pose of hand or head is used, need to account for VR movement
    poseRW = mat4 lovr.headset.getPose hand
    poseVR = mat4(motion.pose)\mul poseRW
    poseVR\scale radius
    lovr.graphics.sphere poseVR

lovr.draw = ->
  lovr.graphics.setBackgroundColor 0.1, 0.1, 0.1
  lovr.graphics.transform mat4(motion.pose)\invert()

  drawHands()
  drawSunflowerFloor()

  rightHandPosition = vec3(lovr.headset.getPosition('right'))
  lovr.graphics.print (handsBackForthDistance*10), rightHandPosition.x, rightHandPosition.y + 0.5, rightHandPosition.z
