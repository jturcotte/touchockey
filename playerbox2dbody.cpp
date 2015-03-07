#include "playerbox2dbody.h"

#include <box2dworld.h>

void PlayerBox2DBody::handleTouchMove(float x, float y, int time)
{
    auto velocityDifferenceVector = [](QVector2D toProj, QVector2D onto) {
        // Find what part of the push to removed in account for the current velocity
        // of the body (like when you can't get any faster on a bicycle unless you
        // start pedaling faster than what the current speed is rotating the traction
        // wheel).
        // There is surely a better formula than this, but here take the projection
        // of the input movement onto the current velocity vector, and remove that part,
        // clamping what we remove between 0 and the length of the velocity vector.
        auto unitOnto = onto.normalized();
        auto projLength = QVector2D::dotProduct(toProj, unitOnto);
        auto effectiveProjLength = fmax(0, fmin(projLength, onto.length()));
        return unitOnto * effectiveProjLength;
    };

    if (!world()->isRunning())
        return;

    // Moving the finger 75px per second will be linearly reduced by a speed of 1m per second.
    const int inputPixelPerMeter = 75;
    // How much fraction of a second it takes to reach the mps described by the finger.
    // 1/8th of a second will be needed for the ball to reach the finger mps speed
    // (given that we only accelerate using the velocity difference between the controller
    // and the player body).
    float accelFactor = getMass() * 8;

    int moveTime = time ? time : 16;
    QVector2D inputDelta{x, y};
    QVector2D bodyVelMPS{linearVelocity()};
    QVector2D moveVecMPS = inputDelta * (1000.0 / moveTime / inputPixelPerMeter);
    QVector2D inputAdjustmentVec = velocityDifferenceVector(moveVecMPS, bodyVelMPS);
    QVector2D adjustedMove = moveVecMPS - inputAdjustmentVec;

    QVector2D appliedForce = adjustedMove * accelFactor;
    applyForceToCenter(appliedForce.toPointF());

    emit thrust(inputDelta.normalized(), inputDelta.length());
}
