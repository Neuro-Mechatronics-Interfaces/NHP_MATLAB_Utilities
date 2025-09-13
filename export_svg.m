function doc = export_svg(fig, filename, opts)
%EXPORT_SVG  Export a MATLAB figure to layered, Inkscape-friendly SVG.
%
% Syntax
%   export_svg(fig)                                  % writes "default.svg" in pwd
%   export_svg(fig, "out/figure.svg")
%   export_svg(fig, "out/figure.svg", struct('DPI',300,'FontOverride',"Arial"))
%
% Description
%   Creates an SVG DOM (with inkscape/sodipodi metadata) that mirrors the MATLAB
%   figure hierarchy:
%     <svg>
%       <g inkscape:label="Axes 1" ...>              % one per axes
%         <g inkscape:label="Rulers"> ... </g>       % tick marks & labels (basic)
%         <g inkscape:label="Legend"> ... </g>       % legend (placeholder)
%         <g inkscape:label="child-<Tag|DisplayName>">
%            (path/text elements for lines, patches, texts)
%         </g>
%       </g>
%     </svg>
%
% Name-Value (via opts.<Name> = value)
%   DPI                 : output DPI for size scaling (default 300)
%   DefaultConfig       : 'none' | 'letter-quadrant' | 'letter-half'
%   MinFontSizePoints   : enforce minimum font size (default 8)
%   FontOverride        : font family name or 'none' (default 'none')
%
% Notes
%   - This is a starter: it handles line/patch/text well; images/surfaces are
%     currently stubbed. Ruler/legend drawers are basic; extend as needed.
%   - Uses matlab.io.xml.dom API + xmlwrite.
%
% See also: xmlwrite, matlab.io.xml.dom.*

arguments
    fig (1,1) matlab.ui.Figure
    filename {mustBeTextScalar} = "default.svg"
    opts.ApplyLineAlpha (1,1) logical = false
    opts.LineStrokeAlpha (1,1) double = 1        % 0..1
    opts.LineFillAlpha   (1,1) double = 1        % 0..1 (markers)
    opts.DPI (1,1) double {mustBePositive, mustBeInteger} = 96
    opts.DefaultConfig {mustBeMember(opts.DefaultConfig,{'none','letter-quadrant','letter-half', 'subpanel'})} = 'subpanel';
    opts.DrawAxesFrame (1,1) logical = true
    opts.DrawGridX (1,1) logical = true
    opts.DrawGridY (1,1) logical = true
    opts.GridColor {mustBeTextScalar} = 'auto'   % 'auto' or CSS color
    opts.GridOpacity (1,1) double = 0.15         % 0..1
    opts.GridDash {mustBeTextScalar} = '2,2'     % SVG dasharray
    opts.LegendBoxMode {mustBeMember(opts.LegendBoxMode,{'matlab','tight'})} = 'tight'
    opts.LegendRowSpacingEm (1,1) double = 1.30   % row height ≈ this * font px (min tokenH)
    opts.LegendPadXEm      (1,1) double = 0.70    % left/right padding in “em”
    opts.LegendPadYTopEm   (1,1) double = 0.95    % extra room for ascenders
    opts.LegendPadYBotEm   (1,1) double = 0.65
    opts.LegendTextFudgeEm (1,1) double = 0.35    % safety added to measured text width
    opts.MinFontSizePoints (1,1) double {mustBePositive} = 8
    opts.FontOverride {mustBeTextScalar} = 'none'
end

% ---------- Ensure folder exists ----------
filename = string(filename);
outDir = fileparts(filename);
if strlength(outDir) > 0 && ~isfolder(outDir)
    mkdir(outDir);
end

% ---------- Figure sizing and viewBox ----------
% Base size from figure Position (pixels)
oldUnits = fig.Units;
fig.Units = 'pixels';
figPosPx = fig.Position;           % [x y w h], pixels
fig.Units = oldUnits;

ppi = get(0,'ScreenPixelsPerInch');  % screen PPI
% Convert figure size to inches
figSizeIn = [figPosPx(3) figPosPx(4)] / ppi;

% Apply DefaultConfig sizing if requested
switch opts.DefaultConfig
    case 'subpanel'
        figSizeIn = [4 4];
    case 'letter-quadrant'
        pageIn = [8.5 11];
        figSizeIn = pageIn .* 0.5;
    case 'letter-half'
        pageIn = [8.5 11];
        figSizeIn = [pageIn(1) pageIn(2)/2];  % landscape half-page feel
    case 'none'
        % keep as-is
end

% Output size in user units (px @ opts.DPI)
outPx = figSizeIn * opts.DPI;
svgW = outPx(1);
svgH = outPx(2);

% ---------- Build DOM ----------
import matlab.io.xml.dom.*
doc = Document('svg');
svg = getDocumentElement(doc);

% Namespaces
setAttribute(svg,'xmlns','http://www.w3.org/2000/svg');
setAttribute(svg,'xmlns:inkscape','http://www.inkscape.org/namespaces/inkscape');
setAttribute(svg,'xmlns:sodipodi','http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd');
setAttribute(svg,'version','1.1');

% Size + viewBox
setAttribute(svg,'width', sprintf('%.0fpx', svgW));
setAttribute(svg,'height', sprintf('%.0fpx', svgH));
setAttribute(svg,'viewBox', sprintf('0 0 %.6g %.6g', svgW, svgH));

% sodipodi (basic namedview)
namedView = createElement(doc,'sodipodi:namedview');
setAttribute(namedView,'pagecolor','#ffffff');
setAttribute(namedView,'bordercolor','#666666');
setAttribute(namedView,'borderopacity','1');
appendChild(svg, namedView);

% ---------- Root layer for this figure ----------
rootLayer = createElement(doc,'g');
setAttribute(rootLayer,'inkscape:groupmode','layer');
setAttribute(rootLayer,'inkscape:label', getFigLabel(fig));
appendChild(svg, rootLayer);

% ---------- Collect axes (exclude legends/uitabs) ----------
axs = findall(fig, 'Type','axes');
legends = findall(fig, 'Type','legend');

% Map figure pixel-space -> SVG pixel-space (top-left origin for SVG).
% We'll define an axes <g> with its own transform to account for inner position.
for iax = numel(axs):-1:1
    ax = axs(iax);
    if strcmpi(ax.Tag,'legend') || any(ax == legends) %#ok<*EFIND>
        continue
    end
end

% Sort axes by depth (approximate) to keep MATLAB stacking (back->front)
axs = flipud(axs(:));

% ---------- Process each axes ----------
for iax = 1:numel(axs)
    ax = axs(iax);
    axGroup = createElement(doc,'g');
    setAttribute(axGroup,'inkscape:groupmode','layer');
    setAttribute(axGroup,'inkscape:label', getAxesLabel(ax, iax));
    addClass(axGroup, 'axes');
    setDataAxes(axGroup, iax);

    % Axes pixel position (inside figure)
    oldAxUnits = ax.Units;
    ax.Units = 'pixels';
    axPos = ax.Position;    % [x y w h] in figure pixel coords, y from bottom
    ax.Units = oldAxUnits;

    % Convert MATLAB bottom-left to SVG top-left using translate + flip-y in the axes group
    % SVG origin at (0,0) top-left. We want axes origin at its top-left corner.
    axX = axPos(1) * (svgW/figPosPx(3));
    axY_topLeft = (figPosPx(4) - axPos(2) - axPos(4)) * (svgH/figPosPx(4));
    axW = axPos(3) * (svgW/figPosPx(3));
    axH = axPos(4) * (svgH/figPosPx(4));

    % Axes group transform: translate to top-left, then scale y by -1 around top edge to ease plotting
    tfm = sprintf('translate(%.6g,%.6g) scale(1,-1) translate(0,%.6g)', axX, axY_topLeft, -axH);
    setAttribute(axGroup,'transform', tfm);

    % --- Rulers (basic ticks + labels) ---
    rulersG = createElement(doc,'g');
    setAttribute(rulersG,'inkscape:label','Rulers');
    addClass(rulersG,'ruler');
    setDataAxes(rulersG, iax);
    appendChild(axGroup, rulersG);
    addRulers(doc, rulersG, ax, axW, axH, opts, iax);

    % --- Legend ---
    legG = createElement(doc,'g');
    setAttribute(legG,'inkscape:label','Legend');
    addClass(legG,'legend');
    setDataAxes(legG, iax);
    appendChild(axGroup, legG);
    addLegend(doc, legG, ax, axW, axH, opts, iax);

    % --- Children (lines, patches, texts, etc.) ---
    kids = ax.Children;
    % MATLAB draws last on top; our axes group is flipped; keep same order
    for ik = 1:numel(kids)
        gk = createElement(doc,'g');
        [lbl, hiHex] = getLabelAndHiColor(kids(ik));
        setAttribute(gk,'inkscape:label', lbl);
        if ~isempty(hiHex)
            setAttribute(gk,'inkscape:highlight-color', hiHex);
        end
        setDataAxes(gk, iax);
        addClass(gk, lower(string(class(kids(ik)))));

        switch lower(class(kids(ik)))
            case 'matlab.graphics.chart.primitive.line'
                addLinePath(doc, gk, kids(ik), ax, axW, axH, opts);
            case 'matlab.graphics.primitive.patch'
                addPatchPath(doc, gk, kids(ik), ax, axW, axH, opts);
            case 'matlab.graphics.primitive.text'
                addTextNode(doc, gk, kids(ik), ax, axW, axH, opts);
            case 'matlab.graphics.primitive.group'
                addHGGroup(doc, gk, kids(ik), ax, axW, axH, opts, iax);
            otherwise
                % scatter() returns Line; area/fill often Patch.
                % images/surfaces/contours can be implemented later:
                warnOnce('export_svg:unsupported', ...
                    'Unsupported object of class %s (skipping).', class(kids(ik)));
        end
        appendChild(axGroup, gk);
    end

    appendChild(rootLayer, axGroup);
end

    function addHGGroup(doc, parentG, grp, ax, axW, axH, opts, iax)
        % Create a wrapper <g> for the group
        gg = createElement(doc,'g');
        [lbl, hiHex] = getLabelAndHiColor(grp);
        setAttribute(gg,'inkscape:label', lbl);
        if ~isempty(hiHex), setAttribute(gg,'inkscape:highlight-color', hiHex); end
        addClass(gg,'hggroup');
        setDataAxes(gg, iax);
        appendChild(parentG, gg);

        % Render children in the same order policy you use elsewhere
        ch = grp.Children(:);
        for j = 1:numel(ch)
            cj = ch(j);
            gchild = createElement(doc,'g');
            [clbl, chi] = getLabelAndHiColor(cj);
            setAttribute(gchild,'inkscape:label', clbl);
            if ~isempty(chi), setAttribute(gchild,'inkscape:highlight-color', chi); end
            setDataAxes(gchild, iax);
            addClass(gchild, lower(string(class(cj))));

            switch lower(class(cj))
                case 'matlab.graphics.chart.primitive.line'
                    addLinePath(doc, gchild, cj, ax, axW, axH, opts);
                case 'matlab.graphics.primitive.patch'
                    addPatchPath(doc, gchild, cj, ax, axW, axH, opts);
                case 'matlab.graphics.primitive.text'
                    addTextNode(doc, gchild, cj, ax, axW, axH, opts);
                case 'matlab.graphics.primitive.group'
                    addHGGroup(doc, gchild, cj, ax, axW, axH, opts, iax);  % recursion
                otherwise
                    warnOnce('export_svg:unsupportedChild', ...
                        'Unsupported child class %s in hggroup (skipping).', class(cj));
            end
            appendChild(gg, gchild);
        end
    end


% ---------- Serialize (MATLAB DOM) ----------
try
    w = matlab.io.xml.dom.DOMWriter;
    % pretty printing (optional)
    try
        w.Configuration.FormatPrettyPrint = true;
    catch
        % older releases may not have this property; ignore
    end
    writeToFile(w, doc, char(filename));
    fprintf('Wrote SVG to: %s\n', filename);
catch ME
    % Fallback to Java xmlwrite by converting to a Java document
    warning('export_svg:serializeFallback', ...
        'DOMWriter failed (%s). Falling back to Java xmlwrite.', ME.message);
    jdoc = toJavaDocument(doc);
    xmlwrite(char(filename), jdoc);
    fprintf('Wrote SVG (via fallback) to: %s\n', filename);
end


% ==================== Helpers ====================
    function jdoc = toJavaDocument(doc)
        %TOJAVADOCUMENT  Convert matlab.io.xml.dom.Document to org.w3c.dom.Document
        str = string(writeToString(doc));     % MATLAB DOM → string
        db = javaMethod('newInstance','javax.xml.parsers.DocumentBuilderFactory');
        dbf = db.newDocumentBuilder();
        isr = java.io.StringReader(char(str));
        jdoc = dbf.parse(org.xml.sax.InputSource(isr));
    end

    function s = writeToString(doc)
        %WRITETOSTRING  Serialize MATLAB DOM to a string (pretty if available)
        try
            w = matlab.io.xml.dom.DOMWriter;
            try %#ok<TRYNC>
                w.Configuration.FormatPrettyPrint = true;
            end
            s = string(writeToString(w, doc));
        catch
            % very old releases: minimal manual writer
            tmp = [tempname '.svg'];
            w = matlab.io.xml.dom.DOMWriter;
            writeToFile(w, doc, tmp);
            s = string(fileread(tmp));
            delete(tmp);
        end
    end
    function hex = getPropColor(obj, propName, defaultHex)
        %GETPROPCOLOR  Safely get a color property from a graphics object.
        %
        %   hex = getPropColor(obj, 'EdgeColor', '#000')
        %
        % Returns:
        %   hex : CSS hex string (e.g. '#RRGGBB') or 'none'

        hex = defaultHex;
        if ~isprop(obj, propName), return; end
        val = obj.(propName);

        if isempty(val)
            return
        elseif ischar(val) || isstring(val)
            strval = string(val);
            if strcmpi(strval,'none')
                hex = 'none';
            else
                % assume already a valid CSS color string
                hex = char(strval);
            end
        elseif isnumeric(val) && numel(val)==3
            hex = rgb2hex(val);
        end
    end

    function label = getFigLabel(fig)
        label = "Figure";
        if strlength(string(fig.Name))>0, label = string(fig.Name); end
    end

    function label = getAxesLabel(ax, idx)
        if strlength(string(ax.Tag))>0
            label = string(ax.Tag);
        else
            label = sprintf("Axes %d", idx);
        end
    end

    function [lbl, hiHex] = getLabelAndHiColor(obj)
        hiHex = "";
        % Prefer Tag, else DisplayName
        if isprop(obj,'Tag') && strlength(string(obj.Tag))>0
            lbl = string(obj.Tag);
        elseif isprop(obj,'DisplayName') && strlength(string(obj.DisplayName))>0
            lbl = string(obj.DisplayName);
        else
            lbl = string(class(obj));
        end

        % Determine highlight color by type
        if isprop(obj,'Color') && ~isempty(obj.Color)
            hiHex = rgb2hex(obj.Color);
        elseif isprop(obj,'MarkerFaceColor') && ~isempty(obj.MarkerFaceColor) && ~ischar(obj.MarkerFaceColor)
            hiHex = rgb2hex(obj.MarkerFaceColor);
        elseif isprop(obj,'FaceColor') && ~isempty(obj.FaceColor) && ~ischar(obj.FaceColor)
            hiHex = rgb2hex(obj.FaceColor);
        end
    end

    function addRulers(doc, parentG, ax, axW, axH, opts, iax)

        % ---- Grid (behind ticks/labels) ----
        if opts.DrawGridX || opts.DrawGridY
            addGridLines(doc, parentG, ax, axW, axH, opts, iax);
        end

        % ---- Frame (box) ----
        if opts.DrawAxesFrame
            frame = createElement(doc,'rect');
            setAttribute(frame,'x','0'); setAttribute(frame,'y','0');
            setAttribute(frame,'width', num2str(axW)); setAttribute(frame,'height', num2str(axH));
            setAttribute(frame,'fill','none');
            setAttribute(frame,'stroke', rgb2hex(ax.XColor));
            setAttribute(frame,'stroke-width','1');
            setAttribute(frame,'vector-effect','non-scaling-stroke');
            setAttribute(frame,'shape-rendering','crispEdges');
            addClass(frame,'axis-frame');
            setDataAxes(frame, iax);
            appendChild(parentG, frame);
        end

        % ---- Ticks ----
        addTicks(doc, parentG, ax, axW, axH, ax.XLim, 'x', opts, iax);
        addTicks(doc, parentG, ax, axW, axH, ax.YLim, 'y', opts, iax);

        % ---- Labels + Title ----
        addAxisLabel(doc, parentG, ax, axW, axH, 'x', opts, iax);
        addAxisLabel(doc, parentG, ax, axW, axH, 'y', opts, iax);
        addAxisTitle(doc, parentG, ax, axW, axH, opts, iax);
        addAxisSubTitle(doc, parentG, ax, axW, axH, opts, iax);
    end

    function addGridLines(doc, parentG, ax, axW, axH, opts, iax)
        g = createElement(doc,'g');
        setAttribute(g,'inkscape:label','Grid');
        addClass(g,'grid');
        setDataAxes(g, iax);

        % resolve color
        if ischar(opts.GridColor) || isstring(opts.GridColor)
            if strcmpi(string(opts.GridColor),'auto')
                gridHex = rgb2hex(ax.XColor);
            else
                gridHex = char(string(opts.GridColor));
            end
        else
            gridHex = '#cccccc';
        end

        if opts.DrawGridX
            for t = ax.XTick(:)'
                xpx = mapAxis(ax, t, 'x', axW);
                ln = createElement(doc,'line');
                setAttribute(ln,'x1', num2str(xpx)); setAttribute(ln,'y1', '0');
                setAttribute(ln,'x2', num2str(xpx)); setAttribute(ln,'y2', num2str(axH));
                setAttribute(ln,'stroke', gridHex);
                setAttribute(ln,'stroke-width','1');
                setAttribute(ln,'vector-effect','non-scaling-stroke');
                setAttribute(ln,'shape-rendering','crispEdges');
                setAttribute(ln,'stroke-opacity', num2str(clamp01(opts.GridOpacity)));
                if ~isempty(opts.GridDash), setAttribute(ln,'stroke-dasharray', char(string(opts.GridDash))); end
                addClass(ln,'grid-x');
                appendChild(g, ln);
            end
        end

        if opts.DrawGridY
            for t = ax.YTick(:)'
                ypx = mapAxis(ax, t, 'y', axH);
                ln = createElement(doc,'line');
                setAttribute(ln,'x1', '0'); setAttribute(ln,'y1', num2str(ypx));
                setAttribute(ln,'x2', num2str(axW)); setAttribute(ln,'y2', num2str(ypx));
                setAttribute(ln,'stroke', gridHex);
                setAttribute(ln,'stroke-width','1');
                setAttribute(ln,'vector-effect','non-scaling-stroke');
                setAttribute(ln,'shape-rendering','crispEdges');
                setAttribute(ln,'stroke-opacity', num2str(clamp01(opts.GridOpacity)));
                if ~isempty(opts.GridDash), setAttribute(ln,'stroke-dasharray', char(string(opts.GridDash))); end
                addClass(ln,'grid-y');
                appendChild(g, ln);
            end
        end

        appendChild(parentG, g);
    end



    function addTicks(doc, parentG, ax, axW, axH, lim, which, opts, iax)
        switch which
            case 'x'
                ticks = ax.XTick;
                color = ax.XColor;
                for t = ticks(:)'
                    u = (t - lim(1)) / diff(lim);
                    xpx = u * axW;
                    % tick line (at bottom edge)
                    l = createElement(doc,'line');
                    setAttribute(l,'x1', num2str(xpx)); setAttribute(l,'y1', '0');
                    setAttribute(l,'x2', num2str(xpx)); setAttribute(l,'y2', '3'); % outward (remember group flipped)
                    setAttribute(l,'stroke', rgb2hex(color)); setAttribute(l,'stroke-width','1');
                    addClass(l, ['tick tick-' which]);
                    setDataAxes(l, iax);
                    appendChild(parentG, l);

                    % tick label (unflip using additional transform on text)
                    txt = createElement(doc,'text');
                    setAttribute(txt,'transform', sprintf('scale(1,-1) translate(0, %.6g)', 14));
                    setAttribute(txt,'x', num2str(xpx));
                    setAttribute(txt,'y', '0');
                    setAttribute(txt,'text-anchor','middle');
                    addClass(txt, ['tick-label tick-label-' which]);
                    setDataAxes(txt, iax);
                    appendText(doc, txt, num2str(t));
                    style = composeTextStyle(ax, opts);
                    setAttribute(txt,'style', style);
                    appendChild(parentG, txt);
                end
            case 'y'
                ticks = ax.YTick;
                color = ax.YColor;
                for t = ticks(:)'
                    v = (t - lim(1)) / diff(lim);
                    ypx = v * axH;
                    l = createElement(doc,'line');
                    setAttribute(l,'x1','0'); setAttribute(l,'y1', num2str(ypx));
                    setAttribute(l,'x2','3'); setAttribute(l,'y2', num2str(ypx)); % inward to the left
                    setAttribute(l,'stroke', rgb2hex(color)); setAttribute(l,'stroke-width','1');
                    addClass(l, ['tick tick-' which]);
                    setDataAxes(l, iax);
                    appendChild(parentG, l);

                    txt = createElement(doc,'text');
                    setAttribute(txt,'transform', sprintf('scale(1,-1) translate(0, 0)'));
                    setAttribute(txt,'x', num2str(-5));
                    setAttribute(txt,'y', num2str(4-ypx));
                    setAttribute(txt,'text-anchor','end');
                    addClass(txt, ['tick-label tick-label-' which]);
                    setDataAxes(txt, iax);
                    appendText(doc, txt, num2str(t));
                    style = composeTextStyle(ax, opts);
                    setAttribute(txt,'style', style);
                    appendChild(parentG, txt);
                end
        end
    end

    function addAxisLabel(doc, parentG, ax, axW, axH, which, opts, iax)
        switch which
            case 'x'
                if strlength(string(ax.XLabel.String))==0, return; end
                addTextNode(doc, parentG, ax.XLabel, ax, axW, axH, opts, [], iax, 'xlabel');
            case 'y'
                if strlength(string(ax.YLabel.String))==0, return; end
                addTextNode(doc, parentG, ax.YLabel, ax, axW, axH, opts, [], iax, 'ylabel');
        end
    end

    function addAxisTitle(doc, parentG, ax, axW, axH, opts, iax)
        if isempty(ax.Title) || strlength(string(ax.Title.String))==0, return; end
        addTextNode(doc, parentG, ax.Title, ax, axW, axH, opts, [], iax, 'title');
    end

    function addAxisSubTitle(doc, parentG, ax, axW, axH, opts, iax)
        if isempty(ax.Subtitle) || strlength(string(ax.Subtitle.String))==0, return; end
        addTextNode(doc, parentG, ax.Subtitle, ax, axW, axH, opts, [], iax, 'title');
    end

    function addLegend(doc, parentG, ax, axW, axH, opts, iax)
        leg = ax.Legend;
        if isempty(leg) || strcmpi(leg.Visible,'off'), return; end

        % Legend box position in axes pixels (as reported by MATLAB)
        oldUnits = leg.Units;
        leg.Units = 'normalized';
        posN = leg.Position;                     % [x y w h] (axes-normalized)
        leg.Units = oldUnits;

        Lx = (posN(1)-posN(3))*axW;  Ly = (posN(2)-posN(4))*axH;
        Lw = posN(3)*axW;  Lh = posN(4)*axH;

        % Root group for the legend (we'll append bg later after we know size)
        g = createElement(doc,'g');
        setAttribute(g,'inkscape:label','Legend');
        addClass(g,'legend');
        setAttribute(g,'transform', sprintf('translate(%.6g,%.6g)', Lx, Ly));
        setDataAxes(g, iax);
        appendChild(parentG, g);

        % -------- Collect entries --------
        labels = string(leg.String);
        h = []; if isprop(leg,'PlotChildren'), h = leg.PlotChildren; end
        if ~isempty(h)
            mask = true(size(h));
            for k = 1:numel(h)
                if isprop(h(k),'IconDisplayStyle') && strcmpi(h(k).IconDisplayStyle,'off')
                    mask(k) = false;
                end
            end
            h = h(mask);
        end
        if ~isempty(h) && ~isempty(labels) && numel(h)==numel(labels)
            h = flipud(h(:));                     % match label order
        end
        if isempty(h)
            hc = flipud(findobj(ax,'-depth',1,'-not','Type','legend'));
            keep = arrayfun(@(o) any(strcmpi(class(o),{ ...
                'matlab.graphics.chart.primitive.Line', ...
                'matlab.graphics.primitive.Patch'})) || ...
                (isprop(o,'DisplayName') && ~isempty(string(o.DisplayName))), hc);
            h = hc(keep);
        end
        if isempty(labels)
            try labels = string(get(h,'DisplayName')); labels = labels(:);
            catch, labels = repmat("", numel(h),1);
            end
        end
        n = min(numel(h), numel(labels));
        if n==0, return; end

        % -------- Layout (points -> px) --------
        pxPerPt = opts.DPI/72;
        basePt  = getBaseFontSize(leg, opts);
        fontPx  = basePt * pxPerPt;

        % Token size: MATLAB’s ItemTokenSize is in *points*
        tokPt   = [18 9];
        if isprop(leg,'ItemTokenSize') && ~isempty(leg.ItemTokenSize)
            tokPt = double(leg.ItemTokenSize(:)).';
        end
        tokenW  = tokPt(1) * pxPerPt;
        tokenH  = tokPt(2) * pxPerPt;

        % Spacing
        marginX = round(0.8*fontPx);   % roomier padding
        marginY = round(0.8*fontPx);
        gapTok  = round(0.55*fontPx);
        rowH    = max(tokenH, 1.30*fontPx);  % loosen rows a bit

        % Columns
        numCols = 1;
        if isprop(leg,'NumColumns') && ~isempty(leg.NumColumns) && leg.NumColumns>1
            numCols = leg.NumColumns;
        end
        rowsPerCol = ceil(n/numCols);

        % --- Estimate text advance and compute required width/height ---
        txtW = zeros(n,1);
        for i = 1:n
            txtW(i) = approxTextAdvance(labels(i), fontPx);
        end
        maxItemW   = tokenW + gapTok + max(txtW);
        needW      = 2*marginX + numCols*maxItemW;
        needH      = 2*marginY + rowsPerCol*rowH;

        % Grow the MATLAB box if it's too small
        LwEff = max(Lw, needW);
        LhEff = max(Lh, needH);

        % Now that we know the final size, add the background
        bg = createElement(doc,'rect');
        setAttribute(bg,'x','0'); setAttribute(bg,'y','0');
        setAttribute(bg,'width',  num2str(LwEff));
        setAttribute(bg,'height', num2str(LhEff));
        setAttribute(bg,'vector-effect','non-scaling-stroke');
        setDataAxes(bg, iax);

        bgCol = getPropColor(leg,'Color','none');
        if isequal(bgCol,'none'), setAttribute(bg,'fill','none');
        else, setAttribute(bg,'fill', bgCol);
        end
        if strcmpi(leg.Box,'on')
            setAttribute(bg,'stroke', getPropColor(leg,'EdgeColor','#000'));
            setAttribute(bg,'stroke-width','1');
            setAttribute(bg,'shape-rendering','crispEdges');
        else
            setAttribute(bg,'stroke','none');
        end
        appendChild(g, bg);

        % --- Collect entries (labels + handles) robustly ---
        labels = string(leg.String);
        h = [];
        if isprop(leg,'PlotChildren')
            h = leg.PlotChildren;
        end

        % Filter out items hidden from the legend
        if ~isempty(h)
            mask = true(size(h));
            for k = 1:numel(h)
                if isprop(h(k),'IconDisplayStyle') && strcmpi(h(k).IconDisplayStyle,'off')
                    mask(k) = false;
                end
            end
            h = h(mask);
        end

        % Some releases return h in reverse order relative to labels
        if ~isempty(h) && ~isempty(labels) && numel(h) == numel(labels)
            h = flipud(h(:));
        end

        % Fallbacks if needed
        if isempty(h)
            % try visible children in drawing order (top-most last)
            hc = flipud(findobj(ax, '-depth',1, '-not','Type','legend'));
            % only keep ones that usually participate in legends
            keep = arrayfun(@(o) any(strcmpi(class(o),{ ...
                'matlab.graphics.chart.primitive.Line', ...
                'matlab.graphics.primitive.Patch'})) || ...
                (isprop(o,'DisplayName') && ~isempty(string(o.DisplayName))), hc);
            h = hc(keep);
        end
        if isempty(labels)
            % derive from DisplayName if legend.String is empty
            try
                labels = string(get(h,'DisplayName'));
                labels = labels(:);
            catch
                labels = repmat("", numel(h),1);
            end
        end

        n = min(numel(h), numel(labels));
        if n==0, return; end

        % ---- Layout metrics (points → px) ----
        pxPerPt = opts.DPI/72;
        basePt  = getBaseFontSize(leg, opts);
        fontPx  = basePt * pxPerPt;

        % token size (pt -> px)
        tokPt = [18 9];  % fallback
        if isprop(leg,'ItemTokenSize') && ~isempty(leg.ItemTokenSize)
            tokPt = double(leg.ItemTokenSize(:)).';
        end
        tokenH  = tokPt(2) * pxPerPt;
        tokenW  = tokPt(1)/2 * pxPerPt;

        % row height & padding
        padX      = round(opts.LegendPadXEm    * fontPx);
        padYBot   = round(opts.LegendPadYBotEm * fontPx);
        % vertical spacing: at least tokenH or 1.1× font height
        rowH    = max(tokenH, 1.1*fontPx);

        % paddings
        gapTok  = round(0.25*fontPx);     % space between token and text

        % columns
        numCols = 1;
        if isprop(leg,'NumColumns') && ~isempty(leg.NumColumns) && leg.NumColumns>1
            numCols = leg.NumColumns;
        end
        rowsPerCol = ceil(n/numCols);
        colW   = (Lw - 2*padX)/max(1,numCols);
        colTextMax = zeros(1,numCols);

        % Build items
        for i = 1:n
            col = floor((i-1)/rowsPerCol);      % 0-based
            row = mod(i-1, rowsPerCol);         % 0-based
            % update max text width per column
            wtxt = fontPx + opts.LegendTextFudgeEm*fontPx;
            colTextMax(col+1) = max(colTextMax(col+1), wtxt);

            itemX = padX + col*colW;
            itemY =  padYBot + row*rowH;

            itemG = createElement(doc,'g');
            setAttribute(itemG,'class','legend-item');
            setAttribute(itemG,'transform', sprintf('translate(%.6g,%.6g)', itemX, itemY));
            appendChild(g, itemG);

            % Token group (kept at local y-up)
            tokG = createElement(doc,'g');
            setAttribute(tokG,'class','legend-token');
            appendChild(itemG, tokG);

            % Draw token based on object class
            obj = h(i);
            % Midline for token
            yMid = 0.5*tokenH;

            switch lower(class(obj))
                case 'matlab.graphics.chart.primitive.line'
                    % Short horizontal polyline
                    pad = 0.2*tokenH;                             % keep some room for marker
                    lx1 = pad;  lx2 = tokenW - pad;

                    ln = createElement(doc,'line');
                    setAttribute(ln,'x1', num2str(lx1));
                    setAttribute(ln,'y1', num2str(yMid));
                    setAttribute(ln,'x2', num2str(lx2));
                    setAttribute(ln,'y2', num2str(yMid));
                    setAttribute(ln,'vector-effect','non-scaling-stroke');
                    setAttribute(ln,'stroke', rgb2hex(obj.Color));
                    setAttribute(ln,'stroke-width', num2str(max(0.5, obj.LineWidth)));
                    switch obj.LineStyle
                        case ':',  setAttribute(ln,'stroke-dasharray','1,3');
                        case '--', setAttribute(ln,'stroke-dasharray','6,4');
                        case '-.', setAttribute(ln,'stroke-dasharray','6,4,1,4');
                        case 'none', setAttribute(ln,'stroke','none');
                    end
                    % global alpha (optional)
                    if isfield(opts,'ApplyLineAlpha') && opts.ApplyLineAlpha
                        setAttribute(ln,'stroke-opacity', num2str(max(0,min(1,opts.LineStrokeAlpha))));
                    end
                    appendChild(tokG, ln);

                    % Marker (if any) – single centered marker
                    if ~strcmpi(obj.Marker,'none') && ~isempty(obj.Marker)
                        ms_pt   = obj.MarkerSize;                         % diameter in pt
                        rPx     = 0.5 * ms_pt * pxPerPt;                  % radius in px
                        rPx     = min(rPx, 0.45*tokenH);                  % clamp to token box

                        edgeHex = resolveMarkerEdgeColor(obj, rgb2hex(obj.Color));
                        faceHex = resolveMarkerFaceColor(obj, rgb2hex(obj.Color));

                        % center of token
                        mx = 0.5*tokenW;  my = yMid;
                        drawMarker(doc, tokG, obj.Marker, mx, my, rPx, edgeHex, faceHex, max(0.5,obj.LineWidth));

                        % optional alpha
                        if isfield(opts,'ApplyLineAlpha') && opts.ApplyLineAlpha
                            last = tokG.getLastChild();
                            try %#ok<TRYNC>
                                last.setAttribute('stroke-opacity', num2str(max(0,min(1,opts.LineStrokeAlpha))));
                                if ~strcmpi(faceHex,'none')
                                    last.setAttribute('fill-opacity', num2str(max(0,min(1,opts.LineFillAlpha))));
                                end
                            end
                        end
                    end


                case 'matlab.graphics.primitive.patch'
                    % Small filled rectangle token
                    pg = createElement(doc,'rect');
                    setAttribute(pg,'x','0'); setAttribute(pg,'y','0');
                    setAttribute(pg,'width',  num2str(tokenW));
                    setAttribute(pg,'height', num2str(tokenH));
                    setAttribute(pg,'vector-effect','non-scaling-stroke');
                    setAttribute(pg,'fill', parseColorProp(obj.FaceColor, '#808080'));
                    ec = parseColorProp(obj.EdgeColor, 'none');
                    if ~strcmpi(ec,'none')
                        setAttribute(pg,'stroke', ec);
                        setAttribute(pg,'stroke-width', num2str(max(0.5, obj.LineWidth)));
                    else
                        setAttribute(pg,'stroke','none');
                    end
                    setAttribute(pg,'fill-opacity', num2str(getAlpha(obj.FaceAlpha,1.0)));
                    switch obj.LineStyle
                        case ':',  setAttribute(pg,'stroke-dasharray','1,3');
                        case '--', setAttribute(pg,'stroke-dasharray','2,3');
                        case '-.', setAttribute(pg,'stroke-dasharray','2,3,1,3');
                        case 'none', setAttribute(pg,'stroke','none');
                    end
                    appendChild(tokG, pg);

                otherwise
                    % Generic marker-only token if possible (Scatter, etc.)
                    if isprop(obj,'Marker') && ~strcmpi(obj.Marker,'none')
                        ms_pt  = obj.MarkerSize;
                        pxPerPt = (isfield(opts,'DPI') * opts.DPI/72); if pxPerPt==0, pxPerPt = 96/72; end
                        r = max(0.5, 0.5 * ms_pt * pxPerPt);
                        edgeHex = '#000000';
                        if isprop(obj,'Color') && ~ischar(obj.Color), edgeHex = rgb2hex(obj.Color); end
                        if isprop(obj,'MarkerEdgeColor')
                            edgeHex = resolveMarkerEdgeColor(obj, edgeHex);
                        end
                        if isprop(obj,'MarkerFaceColor')
                            faceHex = resolveMarkerFaceColor(obj, edgeHex);
                        else
                            faceHex = 'none';
                        end
                        drawMarker(doc, tokG, obj.Marker, 0.5*tokenW, yMid, r, edgeHex, faceHex, 0.75);
                    else
                        % Fallback empty token
                        % (leave blank)
                    end
            end

            % Text label: place to the right, make glyphs upright
            tx = createElement(doc,'text');
            setAttribute(tx,'class','legend-text');
            setAttribute(tx,'x','0'); setAttribute(tx,'y','0');
            setAttribute(tx,'transform', sprintf('translate(%.6g,%.6g) scale(1,-1)', tokenW + gapTok, yMid));
            setAttribute(tx,'text-anchor','start');
            styleText = composeTextStyle(leg, opts, leg) + " dominant-baseline:middle; alignment-baseline:middle;";
            setAttribute(tx,'style', styleText);
            appendRichText(doc, tx, labels(i), basePt);
            appendChild(itemG, tx);
        end
        % % % ---- Tighten background to content (optional) ----
        % needH = rowsPerCol*rowH + padYTop + padYBot;
        % % % width per column = tokenW + gap + maxText; total = pads + sum(cols)
        % needW = 2*padX + sum(tokenW + gapTok + colTextMax);
        % setAttribute(bg,'width',  num2str(max(Lw, needW)));
        % setAttribute(bg,'height', num2str(max(Lh, needH)));

    end

    function addLinePath(doc, parentG, ln, ax, axW, axH, opts)
        % Polyline (unless LineStyle='none') + per-point markers (by shape)

        % ----- 1) Polyline (respects 'none') -----
        X = ln.XData; Y = ln.YData;
        if ~strcmpi(ln.LineStyle,'none')
            [px, py] = mapXY(ax, X, Y, axW, axH);
            segs = nanSegments(px, py);
            for iseg = 1:numel(segs)
                idx = segs{iseg};
                if numel(idx) < 2, continue; end
                path = createElement(doc,'polyline');
                ptsStr = join(string(px(idx)) + "," + string(py(idx)), " ");
                setAttribute(path,'points', ptsStr);
                setAttribute(path,'fill','none');
                setAttribute(path,'vector-effect','non-scaling-stroke');

                % stroke color
                strokeHex = '#000000';
                if ~isempty(ln.Color) && ~ischar(ln.Color)
                    strokeHex = rgb2hex(ln.Color);
                end
                setAttribute(path,'stroke', strokeHex);
                addClass(path, 'line');
                setDataAxes(path, iax);

                if opts.ApplyLineAlpha
                    setAttribute(path, 'stroke-opacity', num2str(clamp01(opts.LineStrokeAlpha)));
                end

                % width + dash
                setAttribute(path,'stroke-width', num2str(max(0.5, ln.LineWidth)));
                switch ln.LineStyle
                    case ':',  setAttribute(path,'stroke-dasharray','1,3');
                    case '--', setAttribute(path,'stroke-dasharray','6,4');
                    case '-.', setAttribute(path,'stroke-dasharray','6,4,1,4');
                end

                % optional joins/caps if present
                if isprop(ln,'LineJoin'), setAttribute(path,'stroke-linejoin', lower(string(ln.LineJoin))); end
                if isprop(ln,'LineCap'),  setAttribute(path,'stroke-linecap',  lower(string(ln.LineCap)));  end

                appendChild(parentG, path);
            end
        end

        % ----- 2) Markers -----
        if ~strcmpi(ln.Marker,'none') && ~isempty(ln.Marker)
            % Marker size: points -> pixels @ opts.DPI
            ms_pt = ln.MarkerSize;           % MATLAB points
            pxPerPt = double(isfield(opts,'DPI') || isprop(opts,'DPI')) * opts.DPI/72;
            if pxPerPt==0
                pxPerPt = 96/72;
            end  % fallback (screen ~96 dpi)
            r = max(0.5, 0.5 * ms_pt * pxPerPt);  % radius-like size in px

            % Colors
            lineHex = '#000000';
            if ~isempty(ln.Color) && ~ischar(ln.Color), lineHex = rgb2hex(ln.Color); end
            edgeHex = resolveMarkerEdgeColor(ln, lineHex);
            faceHex = resolveMarkerFaceColor(ln, lineHex);

            % Which indices get markers?
            if isprop(ln,'MarkerIndices') && ~isempty(ln.MarkerIndices)
                idxs = ln.MarkerIndices(:)';
                idxs = idxs(idxs>=1 & idxs<=numel(X));
            else
                idxs = 1:numel(X);
            end

            mkG = createElement(doc,'g');
            setAttribute(mkG,'inkscape:label','Markers');
            addClass(mkG,'markers');
            setDataAxes(mkG, iax);
            for k = idxs
                if isnan(X(k)) || isnan(Y(k)), continue; end
                [cx, cy] = mapXY(ax, X(k), Y(k), axW, axH);
                drawMarker(doc, mkG, ln.Marker, cx, cy, r, edgeHex, faceHex, max(0.5, ln.LineWidth));
            end

            appendChild(parentG, mkG);
        end
    end

    function setStrokeFill(el, doFill, classSuffix, edgeHex, faceHex, lw)
        setAttribute(el,'vector-effect','non-scaling-stroke');
        if strcmpi(edgeHex,'none')
            setAttribute(el,'stroke','none');
        else
            setAttribute(el,'stroke', edgeHex);
        end
        setAttribute(el,'stroke-width', num2str(lw));
        if doFill
            if strcmpi(faceHex,'none')
                setAttribute(el,'fill','none');
            else
                setAttribute(el,'fill', faceHex);
            end
        else
            setAttribute(el,'fill','none');
        end
        % classes
        addClass(el, ['marker marker-' classSuffix]);
        if opts.ApplyLineAlpha
            setAttribute(el, 'stroke-opacity', num2str(clamp01(opts.LineStrokeAlpha)));
            if doFill
                setAttribute(el, 'fill-opacity',   num2str(clamp01(opts.LineFillAlpha)));
            end
        end
    end

% ---------- marker helpers ----------
    function drawMarker(doc, parent, mk, cx, cy, r, edgeHex, faceHex, lw)
        mk = char(lower(string(mk)));

        switch mk
            case 'o'  % circle
                c = createElement(doc,'circle');
                setAttribute(c,'cx', num2str(cx));
                setAttribute(c,'cy', num2str(cy));
                setAttribute(c,'r',  num2str(r));
                setStrokeFill(c, true, 'circle', edgeHex, faceHex, lw);
                appendChild(parent, c);

            case '.'  % point: tiny filled circle
                c = createElement(doc,'circle');
                setAttribute(c,'cx', num2str(cx)); setAttribute(c,'cy', num2str(cy));
                setAttribute(c,'r',  num2str(max(0.5, 0.4*r)));
                % For '.' prefer fill = edge color if face is none/auto
                fillHex = faceHex;
                if strcmpi(fillHex,'none')
                    fillHex = edgeHex;
                end
                setStrokeFill(c, true, 'point', 'none', fillHex, lw);
                appendChild(parent, c);

            case 's'  % square
                rect = createElement(doc,'rect');
                setAttribute(rect,'x', num2str(cx - r));
                setAttribute(rect,'y', num2str(cy - r));
                setAttribute(rect,'width',  num2str(2*r));
                setAttribute(rect,'height', num2str(2*r));
                setStrokeFill(rect, true, 'square', edgeHex, faceHex, lw);
                appendChild(parent, rect);

            case 'd'  % diamond
                pts = [cx, cy+r;  cx+r, cy;  cx, cy-r;  cx-r, cy];
                poly = createElement(doc,'polygon');
                setAttribute(poly,'points', joinPts(pts));
                setStrokeFill(poly, true, 'diamond', edgeHex, faceHex, lw);
                appendChild(parent, poly);

            case '^'  % up triangle (y is up in our axes group)
                pts = [cx, cy+r;  cx-r, cy-r;  cx+r, cy-r];
                poly = createElement(doc,'polygon');
                setAttribute(poly,'points', joinPts(pts));
                setStrokeFill(poly, true, 'up', edgeHex, faceHex, lw);
                appendChild(parent, poly);

            case 'v'  % down triangle
                pts = [cx, cy-r;  cx-r, cy+r;  cx+r, cy+r];
                poly = createElement(doc,'polygon');
                setAttribute(poly,'points', joinPts(pts));
                setStrokeFill(poly, true, 'down', edgeHex, faceHex, lw);
                appendChild(parent, poly);

            case '>'  % right triangle
                pts = [cx+r, cy;  cx-r, cy+r;  cx-r, cy-r];
                poly = createElement(doc,'polygon');
                setAttribute(poly,'points', joinPts(pts));
                setStrokeFill(poly, true, 'right', edgeHex, faceHex, lw);
                appendChild(parent, poly);

            case '<'  % left triangle
                pts = [cx-r, cy;  cx+r, cy+r;  cx+r, cy-r];
                poly = createElement(doc,'polygon');
                setAttribute(poly,'points', joinPts(pts));
                setStrokeFill(poly, true, 'left', edgeHex, faceHex, lw);
                appendChild(parent, poly);

            case 'x'  % x-mark
                mrkg = createElement(doc, 'g');
                addClass(mrkg,'marker marker-x');
                l1 = createElement(doc,'line');
                setAttribute(l1,'x1', num2str(cx-r)); setAttribute(l1,'y1', num2str(cy-r));
                setAttribute(l1,'x2', num2str(cx+r)); setAttribute(l1,'y2', num2str(cy+r));
                setStrokeFill(l1, false, mk, edgeHex, faceHex, lw);
                appendChild(mrkg, l1);
                l2 = createElement(doc,'line');
                setAttribute(l2,'x1', num2str(cx-r)); setAttribute(l2,'y1', num2str(cy+r));
                setAttribute(l2,'x2', num2str(cx+r)); setAttribute(l2,'y2', num2str(cy-r));
                setStrokeFill(l2, false, mk, edgeHex, faceHex, lw);
                appendChild(mrkg, l2);
                appendChild(parent, mrkg);

            case '+'  % plus
                mrkg = createElement(doc, 'g');
                lh = createElement(doc,'line');
                setAttribute(lh,'x1', num2str(cx-r)); setAttribute(lh,'y1', num2str(cy));
                setAttribute(lh,'x2', num2str(cx+r)); setAttribute(lh,'y2', num2str(cy));
                setStrokeFill(lh, false, mk, edgeHex, faceHex, lw);
                appendChild(mrkg, lh);
                lv = createElement(doc,'line');
                setAttribute(lv,'x1', num2str(cx)); setAttribute(lv,'y1', num2str(cy-r));
                setAttribute(lv,'x2', num2str(cx)); setAttribute(lv,'y2', num2str(cy+r));
                setStrokeFill(lv, false, mk, edgeHex, faceHex, lw);
                appendChild(mrkg, lv);
                addClass(mrkg,'marker marker-plus');
                appendChild(parent, mrkg);

            case '*'  % asterisk: plus + x
                mrkg = createElement(doc, 'g');
                drawMarker(doc, mrkg, '+', cx, cy, r, edgeHex, faceHex, lw);
                drawMarker(doc, mrkg, 'x', cx, cy, r, edgeHex, faceHex, lw);
                addClass(mrkg,'marker marker-asterisk');
                appendChild(parent, mrkg);

            case 'p'  % pentagram star (filled)
                poly = createElement(doc,'polygon');
                pts = starPolygon(cx, cy, 5, r, 0.45*r, -90); % rotate so one point up
                setAttribute(poly,'points', joinPts(pts));
                setStrokeFill(poly, true, mk, edgeHex, faceHex, lw);
                appendChild(parent, poly);

            case 'h'  % hexagram (two triangles)
                mrkg = createElement(doc, 'g');
                drawMarker(doc, mrkg, '^', cx, cy, r, edgeHex, faceHex, lw);
                drawMarker(doc, mrkg, 'v', cx, cy, r, edgeHex, faceHex, lw);
                addClass(mrkg,'marker marker-hex');
                appendChild(parent, mrkg);

            otherwise % fallback -> circle
                c = createElement(doc,'circle');
                setAttribute(c,'cx', num2str(cx)); setAttribute(c,'cy', num2str(cy));
                setAttribute(c,'r',  num2str(r));
                setStrokeFill(c, true, mk, edgeHex, faceHex, lw);
                appendChild(parent, c);
        end
    end

    function hex = resolveMarkerEdgeColor(ln, defaultHex)
        % 'auto' -> line color; 'none' -> 'none'; RGB -> hex
        if isprop(ln,'MarkerEdgeColor') && ~isempty(ln.MarkerEdgeColor)
            val = ln.MarkerEdgeColor;
            if ischar(val) || isstring(val)
                if strcmpi(string(val),'auto'), hex = defaultHex; return; end
                if strcmpi(string(val),'none'), hex = 'none';     return; end
            elseif isnumeric(val) && numel(val)==3
                hex = rgb2hex(val); return;
            end
        end
        hex = defaultHex;
    end

    function hex = resolveMarkerFaceColor(ln, defaultHex)
        % 'auto' -> line color; 'none' -> 'none'; RGB -> hex
        if isprop(ln,'MarkerFaceColor') && ~isempty(ln.MarkerFaceColor)
            val = ln.MarkerFaceColor;
            if ischar(val) || isstring(val)
                if strcmpi(string(val),'auto'), hex = defaultHex; return; end
                if strcmpi(string(val),'none'), hex = 'none';     return; end
            elseif isnumeric(val) && numel(val)==3
                hex = rgb2hex(val); return;
            end
        end
        % default: filled if face set elsewhere, else none
        hex = 'none';
    end

    function segs = nanSegments(px, py)
        % Return index runs between NaNs
        nanmask = isnan(px) | isnan(py);
        idxAll = 1:numel(px);
        edges = find(nanmask);
        cuts = [0, edges, numel(px)+1];
        segs = {};
        for k = 1:numel(cuts)-1
            a = cuts(k)+1; b = cuts(k+1)-1;
            if b >= a, segs{end+1} = idxAll(a:b); end %#ok<AGROW>
        end
    end

    function s = joinPts(pts)
        % pts: N×2
        s = join(string(pts(:,1)) + "," + string(pts(:,2)), " ");
    end

    function pts = starPolygon(cx, cy, n, rOuter, rInner, rotDeg)
        % Regular n-point star as 2n vertices alternating outer/inner
        theta0 = deg2rad(rotDeg);
        theta = theta0 + (0:(2*n-1))' * pi/n;
        rad   = repmat([rOuter; rInner], n, 1);
        pts   = [cx + rad .* cos(theta), cy + rad .* sin(theta)];
    end


    function addPatchPath(doc, parentG, p, ax, axW, axH, opts) %#ok<INUSD>
        xlim = ax.XLim; ylim = ax.YLim;
        X = p.XData; Y = p.YData;

        % Handle NaN-separated faces
        [px, py, faces] = mapToPixels(X, Y, xlim, ylim, axW, axH);
        for i = 1:numel(faces)
            idx = faces{i};
            if numel(idx) < 3, continue; end
            pg = createElement(doc,'polygon');
            ptsStr = join(string(px(idx)) + "," + string(py(idx))," ");
            setAttribute(pg,'points', ptsStr);

            faceColor = parseColorProp(p.FaceColor, '#808080');
            edgeColor = parseColorProp(p.EdgeColor, 'none');

            setAttribute(pg,'fill', faceColor);
            if ~strcmpi(edgeColor,'none')
                setAttribute(pg,'stroke', edgeColor);
                setAttribute(pg,'stroke-width', num2str(max(0.5, p.LineWidth)));
            else
                setAttribute(pg,'stroke','none');
            end
            setAttribute(pg,'fill-opacity', num2str(getAlpha(p.FaceAlpha, 1.0)));
            switch p.LineStyle
                case ':',  setAttribute(pg,'stroke-dasharray','1,3');
                case '--', setAttribute(pg,'stroke-dasharray','2,3');
                case '-.', setAttribute(pg,'stroke-dasharray','2,3,1,3');
                case 'none', setAttribute(pg,'stroke','none');
            end
            appendChild(parentG, pg);
        end
    end

    function addTextNode(doc, parentG, t, ax, axW, axH, opts, rotation, iax, cssClass)
        if nargin < 8 || isempty(rotation), rotation = t.Rotation; end
        if nargin < 9 || isempty(iax), iax = 0; end
        if nargin < 10, cssClass = ''; end
        switch cssClass
            case {'xlabel'}
                scale = ax.LabelFontSizeMultiplier;
                [cx, cy] = mapXY(ax, t.Position(1), t.Position(2)-0.15, axW, axH);
            case {'ylabel'}
                scale = ax.LabelFontSizeMultiplier;
                [cx, cy] = mapXY(ax, t.Position(1)-0.075, t.Position(2), axW, axH);
            case {'title'}
                scale = ax.TitleFontSizeMultiplier;
                [cx, cy] = mapXY(ax, t.Position(1), t.Position(2), axW, axH);
            otherwise
                scale = 1;
                [cx, cy] = mapXY(ax, t.Position(1), t.Position(2), axW, axH);
        end
        txt = createElement(doc,'text');
        setAttribute(txt,'transform', ...
            sprintf('translate(%.6f,%.6f) rotate(%g) scale(%.2f,-%.2f)', cx, cy, rotation, scale, scale));
        setAttribute(txt,'x','0'); setAttribute(txt,'y','0');

        switch lower(t.HorizontalAlignment)
            case 'center', setAttribute(txt,'text-anchor','middle');
            case 'right',  setAttribute(txt,'text-anchor','end');
            otherwise,     setAttribute(txt,'text-anchor','start');
        end

        setAttribute(txt,'style', composeTextStyle(t, opts, t));
        if ~isempty(cssClass), addClass(txt, cssClass); end
        addClass(txt, 'text');                      % generic text tag
        setDataAxes(txt, iax);

        basePt = getBaseFontSize(t, opts);
        appendRichText(doc, txt, string(t.String), basePt);
        appendChild(parentG, txt);
    end

    function appendRichText(doc, parentTextEl, s, basePt)
        % Append <tspan> runs to parentTextEl, parsing _{...}/^{...} (and _x/^x).
        % Supports escaping with \_ \^ \{ \}.
        % Newlines (\n) create a new tspan on the next line (dy).

        s = char(s);
        i = 1;
        plainBuf = "";

        while i <= numel(s)
            ch = s(i);

            % Handle escapes
            if ch == '\' && i < numel(s)
                next = s(i+1);
                if any(next == ['_','^','{','}','\'])
                    plainBuf = plainBuf + string(next);
                    i = i + 2;
                    continue
                end
            end

            if (ch=='_' || ch=='^')
                % flush any pending plain text
                if strlength(plainBuf) > 0
                    tspan = createElement(doc,'tspan');
                    appendText(doc, tspan, plainBuf);
                    appendChild(parentTextEl, tspan);
                    plainBuf = "";
                end

                mode = ch;  % '_' or '^'
                i = i + 1;
                if i <= numel(s) && s(i) == '{'
                    % grouped {...}
                    [content, iNext] = extractBraceGroup(s, i);
                    i = iNext;
                else
                    % single char
                    if i <= numel(s)
                        content = s(i);
                        i = i + 1;
                    else
                        content = ''; % nothing to apply
                    end
                end

                if ~isempty(content)
                    tspan = createElement(doc,'tspan');
                    % size scale for sub/sup
                    subScale = 0.7;  % tweak if you like
                    setAttribute(tspan,'style', sprintf('font-size:%.3fpt; baseline-shift:%s;', ...
                        basePt*subScale, iff(mode=='_', 'sub', 'super')));
                    % Recursively allow nested ^/_ inside the group
                    appendRichText(doc, tspan, string(content), basePt*subScale);
                    appendChild(parentTextEl, tspan);
                end
                continue
            end

            % Newline handling -> new visual line (optional)
            if ch == newline
                if strlength(plainBuf) > 0
                    tspan = createElement(doc,'tspan');
                    appendText(doc, tspan, plainBuf);
                    appendChild(parentTextEl, tspan);
                    plainBuf = "";
                end
                br = createElement(doc,'tspan');
                % move down roughly 1.2em of the current base size
                setAttribute(br,'x','0');
                setAttribute(br,'dy', sprintf('%.3f', 1.2*basePt));
                appendChild(parentTextEl, br);
                i = i + 1;
                continue
            end

            plainBuf = plainBuf + string(ch);
            i = i + 1;
        end

        % flush remaining plain text
        if strlength(plainBuf) > 0
            tspan = createElement(doc,'tspan');
            appendText(doc, tspan, plainBuf);
            appendChild(parentTextEl, tspan);
        end
    end

    function [content, idxAfter] = extractBraceGroup(s, iOpen)
        % s(iOpen) must be '{'. Returns content inside matching braces (supports nesting).
        assert(s(iOpen)=='{', 'extractBraceGroup: expected ''{'' at iOpen');
        depth = 0;
        i = iOpen;
        start = i + 1;
        while i < numel(s)
            i = i + 1;
            c = s(i);
            if c == '\' && i < numel(s) % skip escaped next char
                i = i + 1;
                continue
            elseif c == '{'
                depth = depth + 1;
            elseif c == '}'
                if depth == 0
                    content = s(start:i-1);
                    idxAfter = i + 1;
                    return
                else
                    depth = depth - 1;
                end
            end
        end
        % If we get here, braces were unbalanced; treat as empty
        content = '';
        idxAfter = numel(s) + 1;
    end

    function out = iff(cond, a, b)
        if cond, out = a; else, out = b; end
    end

    function fsz = getBaseFontSize(src, opts)
        % Mirror composeTextStyle's font-size choice (numeric)
        if isprop(src,'FontSize'), fsz = src.FontSize; else, fsz = 10; end
        fsz = max(fsz, opts.MinFontSizePoints);
    end

    function appendText(doc, el, txt)
        %APPENDTEXT  Create and append a text node to an element.
        %   appendText(doc, element, "hello")
        if ~ischar(txt) && ~isstring(txt)
            txt = string(txt);
        end
        tn = createTextNode(doc, char(txt));
        appendChild(el, tn);
    end


    function style = composeTextStyle(src, opts, labelObj)
        % Determine font family, size, and fill color
        if nargin < 3 || isempty(labelObj)
            fsz = getIfProp(src,'FontSize',10);
            % default axis tick color
            if isprop(src,'XColor'), fcol = src.XColor;
            elseif isprop(src,'Color'), fcol = src.Color;
            else, fcol = [0 0 0];
            end
        else
            fsz = getIfProp(labelObj,'FontSize', getIfProp(src,'FontSize',10));
            % *** Prefer TextColor when present (Legend, etc.) ***
            if isprop(labelObj,'TextColor')
                fcol = labelObj.TextColor;
            elseif isprop(labelObj,'Color')
                fcol = labelObj.Color;
            else
                fcol = [0 0 0];
            end
        end

        fsz = max(fsz, opts.MinFontSizePoints);
        if opts.FontOverride ~= "none"
            ffam = string(opts.FontOverride);
        else
            ffam = string(getIfProp(src,'FontName','Arial'));
        end
        style = sprintf('font-family:%s; font-size:%.3gpt; fill:%s;', ...
            ffam, fsz, rgb2hex(fcol));
    end

    function v = getIfProp(obj, prop, fallback)
        if isprop(obj,prop) && ~isempty(obj.(prop))
            v = obj.(prop);
        else
            v = fallback;
        end
    end


    function [px, py, segs] = mapToPixels(X, Y, xlim, ylim, axW, axH)
        px = (X - xlim(1)) ./ (xlim(2)-xlim(1)) * axW;
        py = (Y - ylim(1)) ./ (ylim(2)-ylim(1)) * axH;
        % Break at NaNs
        nanmask = isnan(px) | isnan(py);
        idxAll = 1:numel(X);
        edges = find(nanmask);
        cuts = [0, edges, numel(X)+1];
        segs = {};
        for k = 1:numel(cuts)-1
            a = cuts(k)+1; b = cuts(k+1)-1;
            if b >= a
                segs{end+1} = idxAll(a:b); %#ok<AGROW>
            end
        end
    end

    function hex = rgb2hex(c)
        if isstring(c) || ischar(c)
            hex = char(c);
            return
        end
        if numel(c)==3
            c = max(0,min(1,double(c)));
            hex = sprintf('#%02X%02X%02X', round(c(1)*255), round(c(2)*255), round(c(3)*255));
        else
            hex = '#000000';
        end
    end

    function col = parseColorProp(val, defaultHex)
        if ischar(val) || (isstring(val) && val == "none")
            if strcmpi(string(val),'none')
                col = 'none';
                return
            end
        end
        if isempty(val) || (ischar(val) && strcmpi(val,'flat'))
            col = defaultHex;
        elseif isnumeric(val) && numel(val)==3
            col = rgb2hex(val);
        else
            try
                col = rgb2hex(val);
            catch
                col = defaultHex;
            end
        end
    end

    function a = getAlpha(val, defaultA)
        if isempty(val)
            a = defaultA;
        elseif ischar(val) && strcmpi(val,'flat')
            a = defaultA;
        else
            a = max(0,min(1,double(val)));
        end
    end

    function warnOnce(id, msg, varargin)
        % Simple once-only warning by ID
        persistent SEEN
        if isempty(SEEN), SEEN = containers.Map('KeyType','char','ValueType','logical'); end
        if ~isKey(SEEN, id)
            SEEN(id) = true;
            warning(id, msg, varargin{:});
        end
    end

    function [px, py] = mapXY(ax, X, Y, axW, axH)
        % Map data (X,Y) -> pixel coords, honoring XDir/YDir and log scales.
        px = mapAxis(ax, X, 'x', axW);
        py = mapAxis(ax, Y, 'y', axH);
    end

    function p = mapAxis(ax, v, which, spanPx)
        switch which
            case 'x'
                lim = ax.XLim;
                dir = ax.XDir;    % 'normal' | 'reverse'
                scale = ax.XScale;% 'linear' | 'log'
            case 'y'
                lim = ax.YLim;
                dir = ax.YDir;
                scale = ax.YScale;
        end

        % numeric -> normalized [0,1]
        if strcmpi(scale,'log')
            v = log10(v);
            lim = log10(lim);
        end
        u = (v - lim(1)) ./ (lim(2) - lim(1));

        if strcmpi(dir,'reverse')
            u = 1 - u;
        end

        p = u .* spanPx;
    end

    function setDataAxes(el, iax)
        % Attach axes index as data attribute
        setAttribute(el, 'data-axes', num2str(iax));
    end

    function wpx = approxTextWidthPx(str, basePt)
        % Conservative width estimate (works well for Arial/Helvetica-like UI fonts)
        s = char(str);
        if isempty(s), wpx = 0; return; end
        n  = numel(s);
        ns = sum(s==' ');
        % ~0.62em per non-space, 0.40em per space
        emUnits = 0.62*(n - ns) + 0.40*ns;
        wpx = (basePt * (opts.DPI/72)) * emUnits;
    end


    function addClass(el, cls)
        % Append to 'class' attribute safely
        try
            cur = char(getAttribute(el,'class'));
        catch
            cur = '';
        end
        if isempty(cur)
            setAttribute(el,'class', char(cls));
        else
            setAttribute(el,'class', [cur ' ' char(cls)]);
        end
    end

    function a = clamp01(x)
        if isempty(x) || ~isfinite(x), a = 1; return; end
        a = max(0, min(1, double(x)));
    end

    function w = approxTextAdvance(s, fontPx)
        % Very light heuristic: ~0.56em per char, spaces ~0.35em, wide chars bonus.
        s = char(string(s));
        if isempty(s), w = 0; return; end
        n   = numel(s);
        nsp = sum(s==' ');
        nwide = sum(isstrprop(s,'upper') | ismember(s,'MW@#%&'));
        base = 0.3*(n-nsp) + 0.35*nsp + 0.08*nwide;   % in "em"
        w = base * fontPx;                              % px
    end


end