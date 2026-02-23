function export_with_formats(fig, basePath, opts)

arguments
    fig matlab.ui.Figure
    basePath {mustBeTextScalar}
    opts.ExportFormats string = ".png"
    opts.ExportDPI double = 300
end

for fmt = opts.ExportFormats

    outFile = basePath + fmt;

    switch lower(fmt)
        case ".png"
            try
                exportgraphics(fig, outFile, ...
                    'Resolution', opts.ExportDPI);
            catch
                saveas(fig, outFile);
            end

        case ".svg"
            try
                exportgraphics(fig, outFile);
            catch
                try
                    saveas(fig, outFile);
                catch
                    try
                        print(fig, outFile, '-dsvg', '-painters');
                    catch
                        warning("Could not export SVG for '%s'. Skipping SVG export.", basePath);
                    end
                end
            end

        case ".pdf"
            try
                exportgraphics(fig, outFile);
            catch
                print(fig, outFile, '-dpdf', '-painters');
            end

        otherwise
            error("Unsupported format: %s", fmt)
    end
end
end
