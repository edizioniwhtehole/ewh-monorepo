/**
 * Box Designer CAD Engine
 * Professional parametric geometry generation for packaging
 * Inspired by ArtiosCAD and Pacdora
 */

class BoxTemplate {
  constructor(config) {
    this.config = config;
    this.lines = [];
  }

  generate() {
    throw new Error('Must implement generate() method');
  }
}

/**
 * Standard Rectangular Box (FEFCO 0201)
 * Classic folding carton with 4 panels + flaps
 */
class RectangularBox extends BoxTemplate {
  generate() {
    const { length, width, height, flapRatio = 0.7, bleed = 3 } = this.config;

    const flapHeight = height * flapRatio;
    const lines = [];

    // Base layout: Left panel + Front + Right + Back
    const totalWidth = width * 2 + length * 2;
    const totalHeight = height + flapHeight * 2;

    // Bottom flaps
    lines.push(...this.createFlaps(0, 0, width, length, flapHeight, 'bottom'));

    // Main body panels
    const y1 = flapHeight;

    // Front panel
    lines.push(this.createRect(0, y1, width, height, 'cut'));

    // Left panel
    lines.push(this.createRect(width, y1, length, height, 'cut'));
    lines.push(this.createCrease(width, y1, width, y1 + height));

    // Back panel
    lines.push(this.createRect(width + length, y1, width, height, 'cut'));
    lines.push(this.createCrease(width + length, y1, width + length, y1 + height));

    // Right panel (glue flap)
    const glueFlapWidth = 20;
    lines.push(this.createRect(width * 2 + length, y1, glueFlapWidth, height, 'cut'));
    lines.push(this.createCrease(width * 2 + length, y1, width * 2 + length, y1 + height));

    // Top flaps
    lines.push(...this.createFlaps(0, y1 + height, width, length, flapHeight, 'top'));

    // Add bleed
    if (bleed > 0) {
      lines.push(this.createBleed(lines, bleed));
    }

    return lines;
  }

  createFlaps(x, y, panelWidth, panelLength, flapHeight, position) {
    const flaps = [];
    const positions = [0, panelWidth, panelWidth + panelLength, panelWidth * 2 + panelLength];
    const widths = [panelWidth, panelLength, panelWidth, panelLength];

    positions.forEach((px, i) => {
      const fw = widths[i];

      // Main flap rectangle
      flaps.push({
        type: 'cut',
        points: [
          { x: x + px, y: y },
          { x: x + px + fw, y: y },
          { x: x + px + fw, y: y + flapHeight },
          { x: x + px, y: y + flapHeight }
        ],
        closed: true
      });

      // Crease line at base
      flaps.push({
        type: 'crease',
        points: [
          { x: x + px, y: y + flapHeight },
          { x: x + px + fw, y: y + flapHeight }
        ],
        closed: false
      });

      // Diagonal cuts on corners (dust flaps)
      if (i % 2 === 1) { // Only on length panels
        const cutDepth = 10;
        flaps.push({
          type: 'cut',
          points: [
            { x: x + px, y: y },
            { x: x + px + cutDepth, y: y + cutDepth }
          ],
          closed: false
        });
        flaps.push({
          type: 'cut',
          points: [
            { x: x + px + fw, y: y },
            { x: x + px + fw - cutDepth, y: y + cutDepth }
          ],
          closed: false
        });
      }
    });

    return flaps;
  }

  createRect(x, y, w, h, type) {
    return {
      type,
      points: [
        { x, y },
        { x: x + w, y },
        { x: x + w, y: y + h },
        { x, y: y + h }
      ],
      closed: true
    };
  }

  createCrease(x1, y1, x2, y2) {
    return {
      type: 'crease',
      points: [{ x: x1, y: y1 }, { x: x2, y: y2 }],
      closed: false
    };
  }

  createBleed(lines, bleed) {
    // Calculate bounding box
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
    lines.forEach(line => {
      line.points.forEach(p => {
        minX = Math.min(minX, p.x);
        minY = Math.min(minY, p.y);
        maxX = Math.max(maxX, p.x);
        maxY = Math.max(maxY, p.y);
      });
    });

    return {
      type: 'bleed',
      points: [
        { x: minX - bleed, y: minY - bleed },
        { x: maxX + bleed, y: minY - bleed },
        { x: maxX + bleed, y: maxY + bleed },
        { x: minX - bleed, y: maxY + bleed }
      ],
      closed: true
    };
  }
}

/**
 * Pyramidal Food Bucket (Secchiello)
 * Truncated pyramid with trapezoidal sides
 */
class PyramidalBucket extends BoxTemplate {
  generate() {
    const { baseWidth, baseDepth, topWidth, topDepth, height, bottomType = 'closed' } = this.config;

    const lines = [];

    // Calculate wall angles
    const frontAngle = Math.atan2(height, (baseWidth - topWidth) / 2);
    const sideAngle = Math.atan2(height, (baseDepth - topDepth) / 2);

    // Generate 4 trapezoidal walls
    const walls = [
      { w1: baseWidth, w2: topWidth, h: height, label: 'front' },
      { w1: baseDepth, w2: topDepth, h: height, label: 'left' },
      { w1: baseWidth, w2: topWidth, h: height, label: 'back' },
      { w1: baseDepth, w2: topDepth, h: height, label: 'right' }
    ];

    let xOffset = 0;
    walls.forEach((wall, i) => {
      const trapezoid = this.createTrapezoid(xOffset, 0, wall.w1, wall.w2, wall.h);
      lines.push(...trapezoid);

      // Crease between walls
      if (i < walls.length - 1) {
        lines.push({
          type: 'crease',
          points: [
            { x: xOffset + wall.w1, y: 0 },
            { x: xOffset + wall.w1, y: wall.h }
          ],
          closed: false
        });
      }

      xOffset += wall.w1;
    });

    // Bottom (if closed)
    if (bottomType === 'closed') {
      lines.push({
        type: 'cut',
        points: [
          { x: 0, y: height },
          { x: baseWidth, y: height },
          { x: baseWidth, y: height + baseDepth },
          { x: 0, y: height + baseDepth }
        ],
        closed: true
      });

      lines.push({
        type: 'crease',
        points: [{ x: 0, y: height }, { x: baseWidth, y: height }],
        closed: false
      });
    }

    return lines;
  }

  createTrapezoid(x, y, bottomWidth, topWidth, height) {
    const offset = (bottomWidth - topWidth) / 2;

    return [
      {
        type: 'cut',
        points: [
          { x: x, y: y },
          { x: x + bottomWidth, y: y },
          { x: x + bottomWidth - offset, y: y + height },
          { x: x + offset, y: y + height }
        ],
        closed: true
      }
    ];
  }
}

/**
 * Sleeve Box (FEFCO 0427)
 * Sliding sleeve that fits over a tray
 */
class SleeveBox extends BoxTemplate {
  generate() {
    const { length, width, height, wallThickness = 2 } = this.config;

    const lines = [];

    // Front panel
    lines.push({
      type: 'cut',
      points: [
        { x: 0, y: 0 },
        { x: width, y: 0 },
        { x: width, y: height },
        { x: 0, y: height }
      ],
      closed: true
    });

    // Side panel 1
    lines.push({
      type: 'cut',
      points: [
        { x: width, y: 0 },
        { x: width + length, y: 0 },
        { x: width + length, y: height },
        { x: width, y: height }
      ],
      closed: true
    });

    lines.push({
      type: 'crease',
      points: [{ x: width, y: 0 }, { x: width, y: height }],
      closed: false
    });

    // Back panel
    lines.push({
      type: 'cut',
      points: [
        { x: width + length, y: 0 },
        { x: width * 2 + length, y: 0 },
        { x: width * 2 + length, y: height },
        { x: width + length, y: height }
      ],
      closed: true
    });

    lines.push({
      type: 'crease',
      points: [{ x: width + length, y: 0 }, { x: width + length, y: height }],
      closed: false
    });

    // Side panel 2
    lines.push({
      type: 'cut',
      points: [
        { x: width * 2 + length, y: 0 },
        { x: width * 2 + length * 2, y: 0 },
        { x: width * 2 + length * 2, y: height },
        { x: width * 2 + length, y: height }
      ],
      closed: true
    });

    lines.push({
      type: 'crease',
      points: [{ x: width * 2 + length, y: 0 }, { x: width * 2 + length, y: height }],
      closed: false
    });

    // Glue flap
    const glueFlapWidth = 15;
    lines.push({
      type: 'cut',
      points: [
        { x: width * 2 + length * 2, y: 0 },
        { x: width * 2 + length * 2 + glueFlapWidth, y: 0 },
        { x: width * 2 + length * 2 + glueFlapWidth, y: height },
        { x: width * 2 + length * 2, y: height }
      ],
      closed: true
    });

    lines.push({
      type: 'crease',
      points: [
        { x: width * 2 + length * 2, y: 0 },
        { x: width * 2 + length * 2, y: height }
      ],
      closed: false
    });

    return lines;
  }
}

/**
 * Tuck End Box (FEFCO 0401)
 * Auto-lock bottom with tuck-in top flaps
 */
class TuckEndBox extends BoxTemplate {
  generate() {
    const { length, width, height } = this.config;

    const lines = [];

    // Complex auto-lock bottom structure
    const lockFlapDepth = width * 0.4;

    // Front panel with auto-lock
    lines.push(...this.createAutoLockPanel(0, 0, width, height, lockFlapDepth, 'front'));

    // Side panels
    lines.push(...this.createSidePanel(width, 0, length, height, lockFlapDepth));
    lines.push(...this.createSidePanel(width + length + width, 0, length, height, lockFlapDepth));

    // Back panel
    lines.push(...this.createAutoLockPanel(width + length, 0, width, height, lockFlapDepth, 'back'));

    return lines;
  }

  createAutoLockPanel(x, y, w, h, lockDepth, position) {
    const lines = [];

    // Main panel
    lines.push({
      type: 'cut',
      points: [
        { x, y: y + lockDepth },
        { x: x + w, y: y + lockDepth },
        { x: x + w, y: y + lockDepth + h },
        { x, y: y + lockDepth + h }
      ],
      closed: true
    });

    // Bottom lock flap
    if (position === 'front') {
      lines.push({
        type: 'cut',
        points: [
          { x: x + w * 0.2, y: y },
          { x: x + w * 0.8, y: y },
          { x: x + w * 0.8, y: y + lockDepth },
          { x: x + w * 0.2, y: y + lockDepth }
        ],
        closed: true
      });

      lines.push({
        type: 'crease',
        points: [
          { x: x + w * 0.2, y: y + lockDepth },
          { x: x + w * 0.8, y: y + lockDepth }
        ],
        closed: false
      });
    }

    // Top tuck flap
    const tuckFlapHeight = h * 0.6;
    lines.push({
      type: 'cut',
      points: [
        { x, y: y + lockDepth + h },
        { x: x + w, y: y + lockDepth + h },
        { x: x + w * 0.9, y: y + lockDepth + h + tuckFlapHeight },
        { x: x + w * 0.1, y: y + lockDepth + h + tuckFlapHeight }
      ],
      closed: true
    });

    lines.push({
      type: 'crease',
      points: [
        { x, y: y + lockDepth + h },
        { x: x + w, y: y + lockDepth + h }
      ],
      closed: false
    });

    return lines;
  }

  createSidePanel(x, y, l, h, lockDepth) {
    const lines = [];

    lines.push({
      type: 'cut',
      points: [
        { x, y: y + lockDepth },
        { x: x + l, y: y + lockDepth },
        { x: x + l, y: y + lockDepth + h },
        { x, y: y + lockDepth + h }
      ],
      closed: true
    });

    lines.push({
      type: 'crease',
      points: [
        { x, y: y + lockDepth },
        { x, y: y + lockDepth + h }
      ],
      closed: false
    });

    return lines;
  }
}

/**
 * Gable Top Box (Milk Carton Style)
 * Iconic peaked roof design
 */
class GableTopBox extends BoxTemplate {
  generate() {
    const { length, width, height, gableHeight = 30 } = this.config;

    const lines = [];

    // Base similar to rectangular box
    const totalWidth = width * 2 + length * 2;

    // Bottom
    let y = 0;
    const bottomFlapHeight = 20;

    // Main body (4 panels)
    y += bottomFlapHeight;

    [width, length, width, length].forEach((panelWidth, i) => {
      const xStart = i === 0 ? 0 :
                     i === 1 ? width :
                     i === 2 ? width + length :
                     width * 2 + length;

      lines.push({
        type: 'cut',
        points: [
          { x: xStart, y },
          { x: xStart + panelWidth, y },
          { x: xStart + panelWidth, y: y + height },
          { x: xStart, y: y + height }
        ],
        closed: true
      });

      if (i > 0) {
        lines.push({
          type: 'crease',
          points: [{ x: xStart, y }, { x: xStart, y: y + height }],
          closed: false
        });
      }
    });

    // Gable top (triangular)
    const gableY = y + height;

    // Front gable
    lines.push({
      type: 'cut',
      points: [
        { x: 0, y: gableY },
        { x: width, y: gableY },
        { x: width / 2, y: gableY + gableHeight }
      ],
      closed: true
    });

    lines.push({
      type: 'crease',
      points: [{ x: 0, y: gableY }, { x: width, y: gableY }],
      closed: false
    });

    // Side panels with angled top
    lines.push({
      type: 'cut',
      points: [
        { x: width, y: gableY },
        { x: width + length, y: gableY },
        { x: width + length, y: gableY + gableHeight },
        { x: width, y: gableY + gableHeight }
      ],
      closed: true
    });

    // Back gable
    lines.push({
      type: 'cut',
      points: [
        { x: width + length, y: gableY },
        { x: width * 2 + length, y: gableY },
        { x: width + length + width / 2, y: gableY + gableHeight }
      ],
      closed: true
    });

    return lines;
  }
}

/**
 * CAD Drawing Tools
 */
class CADTools {
  static createRectangle(x, y, width, height, lineType = 'cut') {
    return {
      type: lineType,
      points: [
        { x, y },
        { x: x + width, y },
        { x: x + width, y: y + height },
        { x, y: y + height }
      ],
      closed: true,
      dimensions: { width, height }
    };
  }

  static createCircle(centerX, centerY, radius, lineType = 'cut', segments = 64) {
    const points = [];
    for (let i = 0; i < segments; i++) {
      const angle = (i / segments) * Math.PI * 2;
      points.push({
        x: centerX + Math.cos(angle) * radius,
        y: centerY + Math.sin(angle) * radius
      });
    }

    return {
      type: lineType,
      points,
      closed: true,
      dimensions: { radius, diameter: radius * 2 }
    };
  }

  static createArc(centerX, centerY, radius, startAngle, endAngle, lineType = 'cut', segments = 32) {
    const points = [];
    const angleRange = endAngle - startAngle;

    for (let i = 0; i <= segments; i++) {
      const angle = startAngle + (i / segments) * angleRange;
      points.push({
        x: centerX + Math.cos(angle) * radius,
        y: centerY + Math.sin(angle) * radius
      });
    }

    return {
      type: lineType,
      points,
      closed: false
    };
  }

  static createRoundedRectangle(x, y, width, height, cornerRadius, lineType = 'cut') {
    const r = Math.min(cornerRadius, width / 2, height / 2);

    const lines = [];

    // Top line
    lines.push({
      type: lineType,
      points: [
        { x: x + r, y },
        { x: x + width - r, y }
      ],
      closed: false
    });

    // Top-right corner
    lines.push(this.createArc(x + width - r, y + r, r, -Math.PI / 2, 0, lineType, 8));

    // Right line
    lines.push({
      type: lineType,
      points: [
        { x: x + width, y: y + r },
        { x: x + width, y: y + height - r }
      ],
      closed: false
    });

    // Bottom-right corner
    lines.push(this.createArc(x + width - r, y + height - r, r, 0, Math.PI / 2, lineType, 8));

    // Bottom line
    lines.push({
      type: lineType,
      points: [
        { x: x + width - r, y: y + height },
        { x: x + r, y: y + height }
      ],
      closed: false
    });

    // Bottom-left corner
    lines.push(this.createArc(x + r, y + height - r, r, Math.PI / 2, Math.PI, lineType, 8));

    // Left line
    lines.push({
      type: lineType,
      points: [
        { x, y: y + height - r },
        { x, y: y + r }
      ],
      closed: false
    });

    // Top-left corner
    lines.push(this.createArc(x + r, y + r, r, Math.PI, Math.PI * 1.5, lineType, 8));

    return lines;
  }

  static addDimension(line, label, offset = 20) {
    // Add dimension annotation
    const p1 = line.points[0];
    const p2 = line.points[line.points.length - 1];

    const dx = p2.x - p1.x;
    const dy = p2.y - p1.y;
    const length = Math.sqrt(dx * dx + dy * dy);

    return {
      type: 'dimension',
      startPoint: p1,
      endPoint: p2,
      label: label || `${length.toFixed(1)}mm`,
      offset,
      length
    };
  }
}

/**
 * Template Library
 */
const TemplateLibrary = {
  'rectangular-box': {
    name: 'Standard Rectangular Box',
    category: 'Basic',
    fefco: '0201',
    defaultParams: { length: 100, width: 80, height: 60, flapRatio: 0.7 },
    generator: RectangularBox
  },
  'pyramidal-bucket': {
    name: 'Pyramidal Food Bucket',
    category: 'Food Service',
    fefco: 'Custom',
    defaultParams: { baseWidth: 85, baseDepth: 85, topWidth: 70, topDepth: 70, height: 200 },
    generator: PyramidalBucket
  },
  'sleeve-box': {
    name: 'Sleeve Box',
    category: 'Packaging',
    fefco: '0427',
    defaultParams: { length: 100, width: 80, height: 60 },
    generator: SleeveBox
  },
  'tuck-end-box': {
    name: 'Auto-Lock Tuck End',
    category: 'Retail',
    fefco: '0401',
    defaultParams: { length: 100, width: 80, height: 120 },
    generator: TuckEndBox
  },
  'gable-top': {
    name: 'Gable Top (Milk Carton)',
    category: 'Food Service',
    fefco: '0950',
    defaultParams: { length: 60, width: 60, height: 100, gableHeight: 30 },
    generator: GableTopBox
  }
};

// Export for use in HTML
if (typeof window !== 'undefined') {
  window.CADEngine = {
    BoxTemplate,
    RectangularBox,
    PyramidalBucket,
    SleeveBox,
    TuckEndBox,
    GableTopBox,
    CADTools,
    TemplateLibrary
  };
}
