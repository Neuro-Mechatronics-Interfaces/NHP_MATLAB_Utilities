function add_page_numbers_to_svg(inSvg, outSvg, opt)
% ADD_PAGE_NUMBERS_TO_SVG  Add bottom-center page numbers to an Inkscape multipage SVG.
%
% Usage
%   add_page_numbers_to_svg('in.svg','out.svg');               % defaults shown below
%   add_page_numbers_to_svg('in.svg','out.svg','Font','Arial','FontSize','10pt','Fmt','– %d –','MarginPx',28);
%
% Defaults
%   Font:       'Arial'
%   FontSize:   '10pt'        % SVG accepts 'pt'
%   Fmt:        '– %d –'      % en-dash surrounded by spaces; use '%d' for page number
%   MarginPx:   28            % distance from bottom (SVG px @ 96 dpi ~ 0.29 in)

arguments
    inSvg {mustBeFile}
    outSvg {mustBeTextScalar} = 'out.svg'; 
    opt.Font {mustBeTextScalar} = 'Arial';
    opt.FontSize {mustBeTextScalar} = '10pt';
    opt.Fmt {mustBeTextScalar} = '- %d -';
    opt.MarginPx (1,1) double {mustBePositive} = 28; 
    opt.StartPage (1,1) double {mustBePositive, mustBeInteger} = 2;
    opt.EveryOtherPage (1,1) logical = false;
    opt.EndPage (1,1) double = inf;
end

opt.Font = char(opt.Font); 
opt.FontSize = char(opt.FontSize);
opt.Fmt = char(opt.Fmt); 

% Namespaces
svgNS       = 'http://www.w3.org/2000/svg';
% Read SVG
doc = xmlread(inSvg);

% Root <svg>
root = doc.getDocumentElement();

% Find the namedview (contains <inkscape:page> definitions)
namedViews = root.getElementsByTagName('sodipodi:namedview');
if namedViews.getLength()==0
    error('No <sodipodi:namedview> found. Is this an Inkscape multipage SVG?');
end
namedview = namedViews.item(0);

% Collect page nodes
pageNodes = namedview.getElementsByTagName('inkscape:page');
nPages = pageNodes.getLength();
if nPages==0
    error('No <inkscape:page> elements found. Define pages in Inkscape (1.2+).');
end

% Helper to convert length strings like "210mm", "148.5mm", "800", "800px" -> px (double)
toPx = @(s) lengthToPx(char(s));

if isinf(opt.EndPage)
    endPage = nPages;
else
    endPage = opt.EndPage;
end
if opt.EveryOtherPage
    vec = opt.StartPage:2:endPage;
else
    vec = opt.StartPage:endPage;
end

% Iterate pages 2..N (skip first)
for i=vec
    pg = pageNodes.item(i-1);
    % Read page geometry
    px = toPx(pg.getAttribute('x'));
    py = toPx(pg.getAttribute('y'));
    pw = toPx(pg.getAttribute('width'));
    ph = toPx(pg.getAttribute('height'));

    % Bottom-center position
    x = px + pw/2;
    y = py + ph - opt.MarginPx;

    % Create <text> element in SVG namespace
    textEl = doc.createElementNS(svgNS,'text');
    textEl.setAttribute('x', num2str(x,'%.6f'));
    textEl.setAttribute('y', num2str(y,'%.6f'));
    % Center horizontally; baseline set to 'alphabetic' so it sits above the bottom margin predictably
    textEl.setAttribute('text-anchor','middle');
    textEl.setAttribute('dominant-baseline','alphabetic');
    textEl.setAttribute('xml:space','preserve');

    % Style: Arial 10pt, black fill, no stroke
    style = sprintf('font-family:%s;font-size:%s;fill:#000000;stroke:none;', opt.Font, opt.FontSize);
    textEl.setAttribute('style', style);

    % Text content "– n –"
    txt = sprintf(opt.Fmt, i);
    textNode = doc.createTextNode(txt);
    textEl.appendChild(textNode);

    % Append to root so it sits at document level (visible on all pages by absolute coords)
    root.appendChild(textEl);
end

% Write output
xmlwrite(outSvg, doc);
fprintf('Wrote numbered SVG to %s (pages 2..%d)\n', outSvg, nPages);

end

function px = lengthToPx(s)
% Convert SVG length string to px (user units, Inkscape uses 96 dpi).
% Accepts numbers with optional units: px, mm, cm, in, pt, pc.
% Defaults to px if unit omitted.

if isempty(s)
    px = 0; return;
end
s = strtrim(s);
% Extract number and unit
m = regexp(s,'^\s*([-+]?[\d\.]+(?:[eE][-+]?\d+)?)\s*([a-zA-Z%]*)\s*$','tokens','once');
if isempty(m)
    error('Unrecognized length: "%s"', s);
end
val = str2double(m{1});
unit = lower(m{2});

% 96 px per inch (SVG 2)
switch unit
    case {'','px'}
        px = val;
    case 'mm'
        px = val * 96 / 25.4;
    case 'cm'
        px = val * 96 / 2.54;
    case 'in'
        px = val * 96;
    case 'pt' % 1 pt = 1/72 in
        px = val * 96 / 72;
    case 'pc' % 1 pc = 12 pt
        px = val * 96 / (72/12);
    otherwise
        error('Unsupported unit: "%s"', unit);
end
end
