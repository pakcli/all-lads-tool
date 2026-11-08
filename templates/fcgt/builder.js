/**
 * FilmCraft Native Graphics Template (.fcgt) Builder
 * Conforms strictly to Rust Serde serialization expected by FilmCraft
 */

export function paramFloat(val) {
    return { value: { Float: Number(val) } };
}

export function paramBool(val) {
    return { value: { Bool: Boolean(val) } };
}

export function paramText(val) {
    return { value: { Text: String(val) } };
}

export function paramChoice(val) {
    return { value: { Choice: Math.floor(Number(val)) } };
}

export function paramColor(r, g, b, a = 1.0) {
    return { value: { Color: [Number(r), Number(g), Number(b), Number(a)] } };
}

export function paramVec2(x, y) {
    return { value: { Vec2: { x: Number(x), y: Number(y) } } };
}

/**
 * Creates default graphic_text layer params matching native FilmCraft format
 */
export function createTextLayerParams(options = {}) {
    return {
        align: paramChoice(options.align ?? 0),
        anchor: paramVec2(options.anchorX ?? 0.0, options.anchorY ?? 0.0),
        background: paramBool(options.background ?? false),
        background_color: paramColor(...(options.backgroundColor ?? [0.0, 0.0, 0.0, 1.0])),
        background_opacity: paramFloat(options.backgroundOpacity ?? 75.0),
        background_radius: paramFloat(options.backgroundRadius ?? 0.0),
        background_size: paramFloat(options.backgroundSize ?? 12.0),
        baseline_shift: paramFloat(options.baselineShift ?? 0.0),
        box_height: paramFloat(options.boxHeight ?? 0.0),
        box_width: paramFloat(options.boxWidth ?? 0.0),
        caps: paramChoice(options.caps ?? 0),
        faux_bold: paramBool(options.fauxBold ?? false),
        faux_italic: paramBool(options.fauxItalic ?? false),
        fill: paramBool(options.fill ?? true),
        fill_color: paramColor(...(options.fillColor ?? [1.0, 1.0, 1.0, 1.0])),
        fill_kind: paramChoice(options.fillKind ?? 0),
        font: paramText(options.font ?? "Inter"),
        font_style: paramText(options.fontStyle ?? "Regular"),
        gradient_angle: paramFloat(options.gradientAngle ?? 0.0),
        gradient_end: paramColor(...(options.gradientEnd ?? [0.15, 0.15, 0.15, 1.0])),
        gradient_start: paramColor(...(options.gradientStart ?? [1.0, 1.0, 1.0, 1.0])),
        kerning: paramBool(options.kerning ?? true),
        leading: paramFloat(options.leading ?? 0.0),
        ligatures: paramBool(options.ligatures ?? true),
        name: paramText(options.name ?? ""),
        opacity: paramFloat(options.opacity ?? 100.0),
        position: paramVec2(options.positionX ?? 960.0, options.positionY ?? 540.0),
        rotation: paramFloat(options.rotation ?? 0.0),
        scale: paramFloat(options.scale ?? 100.0),
        scale_width: paramFloat(options.scaleWidth ?? 100.0),
        shadow: paramBool(options.shadow ?? false),
        shadow_angle: paramFloat(options.shadowAngle ?? 135.0),
        shadow_blur: paramFloat(options.shadowBlur ?? 40.0),
        shadow_color: paramColor(...(options.shadowColor ?? [0.0, 0.0, 0.0, 1.0])),
        shadow_distance: paramFloat(options.shadowDistance ?? 10.0),
        shadow_opacity: paramFloat(options.shadowOpacity ?? 75.0),
        shadow_size: paramFloat(options.shadowSize ?? 0.0),
        size: paramFloat(options.size ?? 64.0),
        strikethrough: paramBool(options.strikethrough ?? false),
        stroke: paramBool(options.stroke ?? false),
        stroke2: paramBool(options.stroke2 ?? false),
        stroke2_color: paramColor(...(options.stroke2Color ?? [1.0, 0.85, 0.2, 1.0])),
        stroke2_type: paramChoice(options.stroke2Type ?? 0),
        stroke2_width: paramFloat(options.stroke2Width ?? 10.0),
        stroke_color: paramColor(...(options.strokeColor ?? [0.0, 0.0, 0.0, 1.0])),
        stroke_type: paramChoice(options.strokeType ?? 0),
        stroke_width: paramFloat(options.strokeWidth ?? 4.0),
        text: paramText(options.text ?? ""),
        tracking: paramFloat(options.tracking ?? 0.0),
        underline: paramBool(options.underline ?? false),
        uniform_scale: paramBool(options.uniformScale ?? true),
        vertical: paramBool(options.vertical ?? false)
    };
}

/**
 * Builds a valid graphic_text layer
 */
export function createTextLayer(uid, options = {}) {
    return {
        effect: "graphic_text",
        enabled: true,
        params: createTextLayerParams(options),
        layer: {
            uid: Math.floor(Number(uid))
        }
    };
}

/**
 * Constructs an entire .fcgt graphics template
 */
export function buildTemplate({
    id,
    name,
    category = "Retro Elements",
    description = "",
    author = "Antigravity",
    license = "MIT",
    tags = ["retro"],
    canvas = [1920, 1080],
    duration = 1271350080000,
    layers = [],
    controls = []
}) {
    return {
        format: "filmcraft.graphicsTemplate",
        version: 1,
        id,
        name,
        category,
        description,
        author,
        license,
        tags,
        canvas,
        duration,
        layers,
        graphic: {
            intro: 0,
            outro: 0,
            designIn: 0,
            designDuration: 0
        },
        controls
    };
}
