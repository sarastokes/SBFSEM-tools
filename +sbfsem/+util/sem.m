function sem = sem(data)
  % find standard error of the mean
  sem = std(data)/sqrt(length(data));
end
