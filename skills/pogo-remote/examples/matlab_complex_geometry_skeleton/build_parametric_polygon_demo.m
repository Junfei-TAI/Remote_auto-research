function vertices = build_parametric_polygon_demo(params)
% Build a simple asymmetric polygon from parameters.
% Replace this with user-specific geometry reconstruction logic.

w = params.width;
h = params.height;
notch_w = params.notch_width;
notch_d = params.notch_depth;

vertices = [0, 0;
            w, 0;
            w, h;
            0.65*w, h;
            0.65*w, h - notch_d;
            0.65*w - notch_w, h - notch_d;
            0.65*w - notch_w, h;
            0, h];
end
