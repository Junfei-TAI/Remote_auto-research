function [m] = removeAbsBound(m)

nMats = length(m.matTypes(:));

doDelete = zeros(nMats,1);
%update material refereces to the parent
%newNums = zeros(nMats,1);
newMatCnt = 0;
for mCnt = 1:nMats

    if isfield(m.matTypes{mCnt},'parent') && m.matTypes{mCnt}.parent > 0
        p = m.matTypes{mCnt}.parent;
        m.matTypeRefs(m.matTypeRefs == mCnt) = p;
        doDelete(mCnt) = 1;
    else
        newMatCnt = newMatCnt + 1;
        %newNums(mCnt) = newMatCnt;
        m.matTypeRefs(m.matTypeRefs == mCnt) = newMatCnt;
    end
end

m.matTypes(logical(doDelete)) = [];

if sum(doDelete) == 0
    error('No parent materials found. Either no absorbing boundary was added, or it was not defined with parents. Either way, nothing can be removed.')
end

end
