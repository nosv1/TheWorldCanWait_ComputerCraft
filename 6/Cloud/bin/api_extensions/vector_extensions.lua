local vector_index = getmetatable(vector.new()).__index

function vector_index:rotate(angle)
    angle = angle * math.pi / 180
    return vector.new(
        math.cos(angle) * self.x - math.sin(angle) * self.z,
        self.y,
        math.sin(angle) * self.x + math.cos(angle) * self.z
    )
end

function vector_index:direction()
    local vector = self:normalize()
    if vector == vector.new(0, 1, 0) then
        return "up"
    elseif vector == vector.new(0, -1, 0) then
        return "down"
    elseif vector == vector.new(1, 0, 0) then
        return "right"
    elseif vector == vector.new(-1, 0, 0) then
        return "left"
    elseif vector == vector.new(0, 0, 1) then
        return "forward"
    elseif vector == vector.new(0, 0, -1) then
        return "back"
    end
end

function vector_index:length2D()
    return math.sqrt(math.pow(self.x, 2) + math.pow(self.z, 2))
end