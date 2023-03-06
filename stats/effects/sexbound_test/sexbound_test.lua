function init()
    effect.setParentDirectives("?scalenearest=0.6")
end

function update(dt)
    local standingPoly = {
        {-0.75 * 0.55, -2.0 * 0.55},
        {-0.35 * 0.55, -2.5 * 0.55},
        {0.35 * 0.55, -2.5 * 0.55},
        {0.75 * 0.55, -2.0 * 0.55},
        {0.75 * 0.55, 0.65 * 0.55},
        {0.35 * 0.55, 1.22 * 0.55},
        {-0.35 * 0.55, 1.22 * 0.55},
        {-0.75 * 0.55, 0.65 * 0.55}
    }
    local crouchingPoly = {
        {-0.75 * 0.55, -2.0 * 0.55},
        {-0.35 * 0.55, -2.5 * 0.55},
        {0.35 * 0.55, -2.5 * 0.55},
        {0.75 * 0.55, -2.0 * 0.55},
        {0.75 * 0.55, -1.0 * 0.55},
        {0.35 * 0.55, -0.5 * 0.55},
        {-0.35 * 0.55, -0.5 * 0.55},
        {-0.75 * 0.55, -1.0 * 0.55}
    }
    mcontroller.controlParameters({standingPoly=standingPoly,crouchingPoly=crouchingPoly})
end

function uninit()
    mcontroller.translate({0,2}) -- Try to prevent expanding into the ground
end