function [err, circm] = minimizeRot(angles, circmo, angleOffset, a, b)

    [circm] = normalCircle(angles, angleOffset, a, b);
    dist = (circm - circmo).^2;
    err = sum(dist(:));