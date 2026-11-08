import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import {
    createTextLayer,
    buildTemplate
} from './builder.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function createRetroMilestonePin() {
    // Layer 1: Year Label (Accent Gold / Green)
    const yearLayer = createTextLayer(1, {
        name: "Year",
        text: "1995",
        font: "Consolas",
        fontStyle: "Bold",
        size: 32.0,
        positionX: 960.0,
        positionY: 420.0,
        fillColor: [0.95, 0.77, 0.25, 1.0], // Golden amber
        background: true,
        backgroundColor: [0.12, 0.12, 0.14, 0.85],
        backgroundSize: 10.0,
        backgroundRadius: 4.0,
        tracking: 2.0
    });

    // Layer 2: Main Milestone Headline
    const headlineLayer = createTextLayer(2, {
        name: "Headline",
        text: "Sony PlayStation Released",
        font: "Consolas",
        fontStyle: "Regular",
        size: 44.0,
        positionX: 960.0,
        positionY: 490.0,
        fillColor: [0.93, 0.90, 0.82, 1.0], // Vintage CRT parchment
        shadow: true,
        shadowColor: [0.0, 0.0, 0.0, 0.8],
        shadowDistance: 6.0,
        shadowBlur: 12.0
    });

    // Layer 3: Subtitle / Description
    const subtitleLayer = createTextLayer(3, {
        name: "Subtitle",
        text: "32-bit CD-ROM console revolutionizing 3D gaming graphics worldwide",
        font: "Consolas",
        fontStyle: "Regular",
        size: 22.0,
        positionX: 960.0,
        positionY: 545.0,
        fillColor: [0.65, 0.65, 0.68, 1.0],
        boxWidth: 700.0,
        boxHeight: 80.0
    });

    // Controls exposed in FilmCraft Essential Graphics Panel
    const controls = [
        {
            id: "milestone_year",
            name: "Milestone Year",
            kind: "text",
            layer: 1,
            param: "text"
        },
        {
            id: "milestone_headline",
            name: "Headline",
            kind: "text",
            layer: 2,
            param: "text"
        },
        {
            id: "milestone_subtitle",
            name: "Description",
            kind: "text",
            layer: 3,
            param: "text"
        }
    ];

    return buildTemplate({
        id: "retro:milestone-pin",
        name: "Retro Milestone Pin",
        category: "Retro Elements",
        description: "Vintage computer style milestone pin with Year badge, Title, and Description",
        layers: [yearLayer, headlineLayer, subtitleLayer],
        controls
    });
}

// Generate and export
const template = createRetroMilestonePin();
const jsonContent = JSON.stringify(template, null, 2);

// 1. Save local Git-tracked copy
const localPath = path.join(__dirname, 'retro_milestone_pin.fcgt');
fs.writeFileSync(localPath, jsonContent, 'utf-8');
console.log(`[OK] Saved Git-tracked template: ${localPath}`);

// 2. Install to FilmCraft Graphics Templates folder (if accessible)
try {
    const appData = process.env.APPDATA;
    if (appData) {
        const filmcraftTemplatesDir = path.join(appData, 'FilmCraft', 'Graphics Templates');
        if (fs.existsSync(filmcraftTemplatesDir)) {
            const destPath = path.join(filmcraftTemplatesDir, 'retro_milestone_pin.fcgt');
            fs.writeFileSync(destPath, jsonContent, 'utf-8');
            console.log(`[OK] Installed to FilmCraft: ${destPath}`);
        } else {
            console.log(`[INFO] FilmCraft templates dir not found at ${filmcraftTemplatesDir}`);
        }
    }
} catch (err) {
    console.log(`[NOTE] AppData folder is protected by environment sandbox. Template saved in workspace.`);
}
