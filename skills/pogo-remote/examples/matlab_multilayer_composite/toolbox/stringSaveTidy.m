function [outString] = stringSaveTidy(string, len)
%stringSaveTidy - tidy up the string to a particular length such that it
%can be saved
strLen = length(string);
if strLen+1 > len
    error('Length of string + 1, %d, is greater than that given for the output, %d',strLen+1, len)
end
outString = blanks(len);
outString(1:strLen) = string;
outString(strLen+1) = 0;

end

