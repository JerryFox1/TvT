glmatrix = require('../../vendor/gl-matrix/gl-matrix')
glmatrix.glMatrixArrayType = glmatrix.MatrixArray = glmatrix.setMatrixArrayType(Array)

Projection = require('./Projection')
Rectangle = require('./Rectangle')

class RotatedRectangle extends Rectangle
  constructor: (@position, @size, @rotation) ->
    super @position, @size

    @rotation ?= 0

    # Rectangle's origin property. We assume the center of the Rectangle will
    # be the point that we will be rotating around and we use that for the origin.
    Object.defineProperty @, 'origin',
      writable: false
      value: [@width / 2, @height / 2]

    Object.defineProperty @, 'upperLeft',
      get: ->
        point  = [@left, @top]
        origin = [point[0] + @origin[0], point[1] + @origin[1]]
        @rotatePoint(point, origin, @rotation)

    Object.defineProperty @, 'upperRight',
      get: ->
        point  = [@right, @top]
        origin = [point[0] - @origin[0], point[1] + @origin[1]]
        @rotatePoint(point, origin, @rotation)

    Object.defineProperty @, 'lowerLeft',
      get: ->
        point  = [@left, @bottom]
        origin = [point[0] + @origin[0], point[1] - @origin[1]]
        @rotatePoint(point, origin, @rotation)

    Object.defineProperty @, 'lowerRight',
      get: ->
        point  = [@right, @bottom]
        origin = [point[0] - @origin[0], point[1] - @origin[1]]
        @rotatePoint(point, origin, @rotation)

    Object.defineProperty @, 'vertices',
      get: ->
        [@upperLeft, @upperRight, @lowerLeft, @lowerRight]

  intersects: (rectangle) ->
    # Calculate the axes we will use to determine if a collision has occurred
    # Since the objects are rectangles, we only have to generate 4 axes (2 for
    # each rectangle) since we know the other 2 on a rectangle are parallel.
    axes = [
      glmatrix.vec2.subtract(@upperRight, @upperLeft)
      glmatrix.vec2.subtract(@upperRight, @lowerRight)
      glmatrix.vec2.subtract(rectangle.upperLeft, rectangle.lowerLeft)
      glmatrix.vec2.subtract(rectangle.upperLeft, rectangle.upperRight)
    ]

    # Cycle through all of the axes we need to check. If a collision does not occur
    # on ALL of the axes, then a collision is NOT occurring. We can then exit out 
    # immediately and notify the calling function that no collision was detected. If
    # a collision DOES occur on ALL of the axes, then there is a collision occurring
    # between the rotated rectangles. We know this to be true by the Seperating Axis Theorem.
    
    # In addition, overlap is tracked so that the smallest overlap can be returned to the caller.
    bestOverlap = Number.MAX_VALUE
    bestCollisionProjection = glmatrix.vec2.create()

    for axis in axes
      # required for accurate projections
      glmatrix.vec2.normalize(axis)

      out = @isAxisCollision(rectangle, axis)

      if !out
        # if there is no axis collision, we can guarantee they do not overlap
        return false

      # do we have the smallest overlap yet?
      if out < bestOverlap
        bestOverlap = out
        bestCollisionProjection = axis

    # it is now guaranteed that the rectangles intersect for us to have gotten this far
    overlap = bestOverlap
    collisionProjection = bestCollisionProjection

    # now we want to make sure the collision projection vector points from the other rectangle to us
    centerToCenter = glmatrix.vec2.create()
    centerToCenter[0] = (rectangle.x + rectangle.origin[0]) - (@x + @origin[0])
    centerToCenter[1] = (rectangle.y + rectangle.origin[1]) - (@y + @origin[1])

    if glmatrix.vec2.dot(collisionProjection, centerToCenter) > 0
      glmatrix.vec2.negate(collisionProjection)

    return [overlap, collisionProjection]

  isAxisCollision: (rectangle, axis) ->
    # project both rectangles onto the axis
    curProj   = @project(axis)
    otherProj = rectangle.project(axis)

    # do the projections overlap?
    if curProj.getOverlap(otherProj) < 0
      return false

    # get the overlap
    overlap = curProj.getOverlap(otherProj)

    # check for containment
    if curProj.contains(otherProj) or otherProj.contains(curProj)
      # get the overlap plus the distance from the minimum end points
      mins = Math.abs(curProj.min - otherProj.min)
      maxs = Math.abs(curProj.max - otherProj.max)

      # NOTE: depending on which is smaller you may need to negate the separating axis
      if mins < maxs
        overlap += mins
      else
        overlap += maxs

    # and return the overlap for an axis collision
    return overlap

  project: (axis) ->
    vertices = @vertices

    min = glmatrix.vec2.dot(axis, vertices[0])
    max = min

    for vertex in vertices
      p = glmatrix.vec2.dot(axis, vertex)

      if p < min
        min = p
      else if p > max
        max = p

    return new Projection(min, max)

  rotatePoint: (point, origin, rotation) ->
    ret = [0, 0]

    c = Math.cos(rotation)
    s = Math.sin(rotation)

    ret[0] = (point[0] - origin[0]) * c - (point[1] - origin[1]) * s + origin[0]
    ret[1] = (point[1] - origin[1]) * c + (point[0] - origin[0]) * s + origin[1]

    return ret

module.exports = RotatedRectangle
