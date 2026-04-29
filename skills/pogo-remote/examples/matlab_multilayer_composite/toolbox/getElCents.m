function [ ex, ey, ez ] = getElCents( m )
%Get approximate centres of elements for a Pogo model

px = m.nodePos(1,:);
py = m.nodePos(2,:);
if m.nDims == 3
    pz = m.nodePos(3,:);
end


ord = m.elNodes;
ord2 = ord;
ord2(ord2 == 0) = 1;

ex = px(ord2);
ex(ord == 0) = nan;
xm = mean(ex,1,'omitnan');

ey = py(ord2);
ey(ord == 0) = nan;
ym = mean(ey,1,'omitnan');

if m.nDims == 3
    ez = pz(ord2);
    ez(ord == 0) = nan;
    zm = mean(ez,1,'omitnan');
end

ex = xm;
ey = ym;
ez = [];
if m.nDims == 3
    ez = zm;
end

end

