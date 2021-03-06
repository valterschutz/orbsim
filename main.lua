
function love.load()
  local _, _, flags = love.window.getMode()
  WIDTH, HEIGHT = love.window.getDesktopDimensions(flags.display)
  love.window.setMode(WIDTH, HEIGHT)
  love.window.setTitle("Orbital simulation")

  -- Settings
  NUM_MODE = "RK"  -- Choose either EF (Euler Forward) or RK (Runge-Kutta)
  LINE_WIDTH = 2
  dt = 0.1
  disturbance_y = 0  -- Added to velocity to change trajectory
  disturbance_x = 0
  trajectory_radius = 2
  sun_radius = 20
  planet_radius = 10
  orbital_radius = 200
  orbital_period = 2
  G = 1  -- Gravitational constant, has no impact
  m_p = 1 -- Also has no impact

  -- Calculate variables for circular orbit (if no disturbances are present)
  sun_x = {WIDTH/2, HEIGHT/2}
  m_s = 4*math.pi^2*orbital_radius^3/(orbital_period^2*G)
  x = {sun_x[1]+orbital_radius, sun_x[2]}
  v = {disturbance_x, -2*math.pi*orbital_radius/orbital_period + disturbance_y}

  -- Keep track of time and all previous planetary positions
  time = 0
  prev_positions = {{x[1], x[2]}}

  -- Graphics
  love.graphics.setLineWidth(LINE_WIDTH)
  love.graphics.setBackgroundColor(1,1,1)

end

function love.draw()
  -- Draw sun
  love.graphics.setColor(1,0,0)
  love.graphics.circle("fill",sun_x[1],sun_x[2],sun_radius)

  -- Draw theoretical orbit
  love.graphics.setColor(0,1,0)
  love.graphics.circle("line",sun_x[1],sun_x[2],orbital_radius)

  -- Draw planet
  love.graphics.setColor(0,0,0)
  love.graphics.circle("fill",x[1],x[2],planet_radius)

  -- Draw previous locations
  love.graphics.setColor(0,0,1)
  for k=1,#prev_positions do
    love.graphics.circle("fill", prev_positions[k][1], prev_positions[k][2], trajectory_radius)
  end

end

function love.update()
  time = time + dt

  if NUM_MODE == "EF" then
    EF_update()
  elseif NUM_MODE == "RK" then
    RK_update()
  end
  table.insert(prev_positions, x)

  -- Uncomment for debugging
  -- print(string.format("x=%d, y=%d, time=%d", x[1], x[2], time))
end


function EF_update()
  -- Calculate distance between sun and planet
  dist = ((x[1]-sun_x[1])^2 + (x[2]-sun_x[2])^2)^(1/2)

  -- Force vector
  F = {-G*m_p*m_s*(x[1]-sun_x[1])/dist^3, -G*m_p*m_s*(x[2]-sun_x[2])/dist^3}

  -- Acceleration vector from F=ma
  a = {F[1]/m_p, F[2]/m_p}

  v = {v[1]+a[1]*dt, v[2]+a[2]*dt}
  x = {x[1]+v[1]*dt, x[2]+v[2]*dt}
end

-- Numerical functions

function RK_update()
  -- S is the state, S = [x,y,v_x,v_y]. D is dS/dt
  S = {x[1], x[2], v[1], v[2]}
  setmetatable(S, metavector)
  k1 = D(S)
  k2 = D(S+(k1*(dt/2)))
  k3 = D(S+(k2*(dt/2)))
  k4 = D(S+(k3*dt))
  S = S + (k1 + k2*2 + k3*2 + k4) * (dt/6)
  x = {S[1], S[2]}
  v = {S[3], S[4]}
end

function D(S)
  -- Calculate distance between sun and planet
  dist = ((S[1]-sun_x[1])^2 + (S[2]-sun_x[2])^2)^(1/2)

  -- Force vector
  F = {-G*m_p*m_s*(S[1]-sun_x[1])/dist^3, -G*m_p*m_s*(S[2]-sun_x[2])/dist^3}

  -- Acceleration vector from F=ma
  a = {F[1]/m_p, F[2]/m_p}

  res = {S[3], S[4], a[1], a[2]}
  setmetatable(res, metavector)
  return res
end

-- Helper functions for vectors
metavector = {}

-- Multiply every element in vector v with scalar c
function metavector.__mul(v,c)
  local res = {}
  for k=1,#v do
    res[k] = c * v[k]
  end
  setmetatable(res, metavector)
  return res
end

-- Add vectors elementwise
function metavector.__add(v1,v2)
  local res = {}
  for k=1,#v1 do
    res[k] = v1[k] + v2[k]
  end
  setmetatable(res,metavector)
  return res
end
