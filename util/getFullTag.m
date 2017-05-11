function fullTag = getFullTag(abbrevTag)
  % get full structure tag
  % structureTags = {'Bipolar;Glutamate;Ribbon', 'Bipolar;Conventional;Glutamate'};
  %
  % 7May2017 - SSP - created

  abbrev = lower(abbrev);


  switch abbrev
  case {'bcribbon', 'ribbon'}
    fullTag = 'Bipolar;Glutamate;Ribbon';
  case {'bcconv', 'conv'}
    fullTag = 'Bipolar;Conventional;Glutamate';
  otherwise
    error('tag not found! add it to util\getFullTag.m');
  end
