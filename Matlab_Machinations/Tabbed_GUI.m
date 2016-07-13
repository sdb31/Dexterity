f = figure('Toolbar', 'none', 'Menubar', 'none', 'Name', 'Tabbed GUI',...
    'Numbertitle', 'off');
tgroup = uitabgroup('Parent', f);
tabs = {'Loan Data', 'Amortization Table', 'Principal/Interest Plot'};
for i = 1:length(tabs);
    uitab('Parent', tgroup, 'Title', tabs{i});
end
% tab1 = uitab('Parent', tgroup, 'Title', 'Loan Data');
% tab2 = uitab('Parent', tgroup, 'Title', 'Amortization Table');
% tab3 = uitab('Parent', tgroup, 'Title', 'Principal/Interest Plot');