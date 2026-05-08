function [u] = combineFieldDofs(field, dofWeights)
%combineFieldDofs - combine the degrees of freedom in the field struct into
%a single value which can be visualised
%   [u] = combineFieldDofs(field, dofWeightings)
%
%field - struct, as loaded from loadPogoField
%dofWeightings - vector of weights, one for each DOF in global values.
%Length should be at least the maximum dof number saved.
%u - resultant combined values
%
% Written by P. Huthwaite, Aug 2024

u = zeros(max(field.nodeNums(:)),length(field.times));
nSets = length(field.nodeNums);
for pCnt = 1:nSets %there may be a more optimal way of doing this
    dof = field.dofNums(pCnt);
    node = field.nodeNums(pCnt);
    u(node, :) = u(node, :) + field.u(pCnt,:)*dofWeights(dof);
end

end
